import Foundation
import SwiftData

/// SwiftData-backed implementation of ``HabitRepository``.
/// Internal to HabitKitCore — consumers use the protocol.
@MainActor
final class SwiftDataHabitRepository: HabitRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() async throws -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try context.fetch(descriptor)
    }

    func fetchDue(on date: Date) async throws -> [Habit] {
        let all = try await fetchAll()
        return all.filter { $0.schedule.isDue(on: date) }
    }

    func save(_ habit: Habit) async throws {
        context.insert(habit)
        try context.save()
    }

    func delete(_ habit: Habit) async throws {
        context.delete(habit)
        try context.save()
    }

    func archive(_ habit: Habit) async throws {
        habit.isArchived = true
        try context.save()
    }

    func reorder(_ habits: [Habit]) async throws {
        for (index, habit) in habits.enumerated() {
            habit.sortOrder = index
        }
        try context.save()
    }
}

/// SwiftData-backed implementation of ``CompletionRepository``.
/// Internal to HabitKitCore — consumers use the protocol.
@MainActor
final class SwiftDataCompletionRepository: CompletionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchCompletions(for habit: Habit) async throws -> [HabitCompletion] {
        let habitID = habit.id
        let descriptor = FetchDescriptor<HabitCompletion>(
            predicate: #Predicate { $0.habit.id == habitID },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func recordCompletion(_ completion: HabitCompletion) async throws {
        context.insert(completion)
        try context.save()
    }

    func deleteCompletion(_ completion: HabitCompletion) async throws {
        context.delete(completion)
        try context.save()
    }
}
