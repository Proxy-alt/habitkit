import Foundation
import HabitKitCore
import SwiftData

/// Actor-isolated SwiftData query layer for AppIntents.
///
/// Each intent creates an instance backed by the shared `IntentModelContainer`
/// and calls the relevant method. Using `@ModelActor` avoids touching
/// `@MainActor`-isolated APIs from the extension process.
@ModelActor
actor HabitIntentStore {

    // MARK: - Entity resolution

    func fetchEntities(for ids: [UUID]) throws -> [HabitEntity] {
        let idSet = Set(ids)
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived }
        )
        let today = Calendar.current.startOfDay(for: Date())
        return try modelContext.fetch(descriptor)
            .filter { idSet.contains($0.id) }
            .map { habit in
                HabitEntity(
                    id: habit.id,
                    name: habit.name,
                    icon: habit.icon,
                    streak: StreakCalculator.currentStreak(
                        completions: habit.completions,
                        schedule: habit.schedule
                    ),
                    isCompletedToday: hasCompletion(habit, on: today)
                )
            }
    }

    func fetchAllEntities() throws -> [HabitEntity] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let today = Calendar.current.startOfDay(for: Date())
        return try modelContext.fetch(descriptor)
            .map { habit in
                HabitEntity(
                    id: habit.id,
                    name: habit.name,
                    icon: habit.icon,
                    streak: StreakCalculator.currentStreak(
                        completions: habit.completions,
                        schedule: habit.schedule
                    ),
                    isCompletedToday: hasCompletion(habit, on: today)
                )
            }
    }

    // MARK: - Full habit list for summary/check-in intents

    /// Returns all non-archived habits with completion state for today.
    func fetchAllHabits() throws -> [HabitEntity] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let today = Calendar.current.startOfDay(for: Date())
        return try modelContext.fetch(descriptor)
            .map { habit in
                HabitEntity(
                    id: habit.id,
                    name: habit.name,
                    icon: habit.icon,
                    streak: StreakCalculator.currentStreak(
                        completions: habit.completions,
                        schedule: habit.schedule
                    ),
                    isCompletedToday: hasCompletion(habit, on: today)
                )
            }
    }

    // MARK: - Filtered habit list

    /// Returns today's scheduled habits filtered by the supplied options.
    ///
    /// - Parameters:
    ///   - incompleteOnly: When `true`, omit habits already completed or skipped today.
    ///   - minimumCompletionPct: 0–100. Omit habits whose 30-day completion rate is
    ///     below this threshold. Pass `0` to skip the filter.
    ///   - skippedIDs: Set of habit ID strings marked as skipped today (from `SkipStore`).
    func fetchHabits(
        incompleteOnly: Bool,
        minimumCompletionPct: Int,
        skippedIDs: Set<String>
    ) throws -> [HabitEntity] {
        let today = Calendar.current.startOfDay(for: Date())
        var habits = try fetchHabitsScheduledToday()

        if incompleteOnly {
            habits = habits.filter {
                !hasCompletion($0, on: today) && !skippedIDs.contains($0.id.uuidString)
            }
        }

        if minimumCompletionPct > 0 {
            let threshold = Double(min(minimumCompletionPct, 100)) / 100.0
            let analytics = AnalyticsEngine()
            habits = habits.filter {
                analytics.completionRate(for: $0, over: .thirtyDays) >= threshold
            }
        }

        return habits.map { habit in
            HabitEntity(
                id: habit.id,
                name: habit.name,
                icon: habit.icon,
                streak: StreakCalculator.currentStreak(
                    completions: habit.completions,
                    schedule: habit.schedule
                ),
                isCompletedToday: hasCompletion(habit, on: today)
            )
        }
    }

    // MARK: - Streak

    func currentStreak(for habitID: UUID) throws -> Int {
        guard let habit = try fetchHabit(id: habitID) else { return 0 }
        return StreakCalculator.currentStreak(
            completions: habit.completions,
            schedule: habit.schedule
        )
    }

    // MARK: - Today progress

    func todayProgress() throws -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        let habits = try fetchHabitsScheduledToday()
        guard !habits.isEmpty else { return 0.0 }
        let completedCount = habits.filter { hasCompletion($0, on: today) }.count
        return Double(completedCount) / Double(habits.count)
    }

    // MARK: - Log completion

    func logCompletion(for habitID: UUID) throws {
        guard let habit = try fetchHabit(id: habitID) else {
            throw HabitError.notFound(habitID)
        }
        let completion = HabitCompletion(completedAt: Date(), habit: habit)
        modelContext.insert(completion)
        habit.completions.append(completion)
        try modelContext.save()
    }

    // MARK: - Private helpers

    private func fetchHabit(id: UUID) throws -> Habit? {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func fetchHabitsScheduledToday() throws -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived }
        )
        let today = Calendar.current.startOfDay(for: Date())
        return try modelContext.fetch(descriptor).filter { $0.schedule.isDue(on: today) }
    }

    private func hasCompletion(_ habit: Habit, on day: Date) -> Bool {
        let calendar = Calendar.current
        return habit.completions.contains {
            calendar.startOfDay(for: $0.completedAt) == day
        }
    }
}
