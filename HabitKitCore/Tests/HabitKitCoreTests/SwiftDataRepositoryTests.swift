import Foundation
import SwiftData
import Testing
@testable import HabitKitCore

@MainActor
@Suite("SwiftData repositories")
struct SwiftDataRepositoryTests {

    private func makeContext() throws -> ModelContext {
        ModelContext(try ModelContainerConfiguration.makeInMemoryContainer())
    }

    private func makeHabit(name: String = "Run", in context: ModelContext) -> Habit {
        let schedule = HabitSchedule(frequency: .daily)
        context.insert(schedule)
        let habit = Habit(name: name, icon: "star", colorHex: "#000", schedule: schedule)
        schedule.habit = habit
        context.insert(habit)
        return habit
    }

    // MARK: - HabitRepository

    @Test("fetchAll returns only non-archived habits")
    func fetchAllFiltersArchived() async throws {
        let ctx = try makeContext()
        let repo = SwiftDataHabitRepository(context: ctx)

        let active = makeHabit(name: "Active", in: ctx)
        let archived = makeHabit(name: "Archived", in: ctx)
        archived.isArchived = true
        try ctx.save()

        let results = try await repo.fetchAll()
        #expect(results.contains { $0.id == active.id })
        #expect(!results.contains { $0.id == archived.id })
    }

    @Test("save inserts a habit and it appears in fetchAll")
    func saveAndFetch() async throws {
        let ctx = try makeContext()
        let repo = SwiftDataHabitRepository(context: ctx)

        let schedule = HabitSchedule(frequency: .daily)
        ctx.insert(schedule)
        let habit = Habit(name: "New", icon: "plus", colorHex: "#FFF", schedule: schedule)
        schedule.habit = habit

        try await repo.save(habit)
        let results = try await repo.fetchAll()
        #expect(results.contains { $0.name == "New" })
    }

    @Test("delete removes habit from store")
    func deleteHabit() async throws {
        let ctx = try makeContext()
        let repo = SwiftDataHabitRepository(context: ctx)

        let habit = makeHabit(in: ctx)
        try ctx.save()
        let idBefore = habit.id

        try await repo.delete(habit)
        let results = try await repo.fetchAll()
        #expect(!results.contains { $0.id == idBefore })
    }

    @Test("archive sets isArchived and hides from fetchAll")
    func archiveHabit() async throws {
        let ctx = try makeContext()
        let repo = SwiftDataHabitRepository(context: ctx)

        let habit = makeHabit(in: ctx)
        try ctx.save()

        try await repo.archive(habit)
        let results = try await repo.fetchAll()
        #expect(!results.contains { $0.id == habit.id })
        #expect(habit.isArchived)
    }

    @Test("reorder updates sortOrder")
    func reorderHabits() async throws {
        let ctx = try makeContext()
        let repo = SwiftDataHabitRepository(context: ctx)

        let a = makeHabit(name: "A", in: ctx)
        let b = makeHabit(name: "B", in: ctx)
        try ctx.save()

        try await repo.reorder([b, a])
        #expect(b.sortOrder == 0)
        #expect(a.sortOrder == 1)
    }

    @Test("fetchDue returns habits scheduled for the given day")
    func fetchDue() async throws {
        let ctx = try makeContext()
        let repo = SwiftDataHabitRepository(context: ctx)

        // daily habit — always due
        let daily = makeHabit(name: "Daily", in: ctx)
        // weekly habit on Sunday (0) only
        let sundaySchedule = HabitSchedule(frequency: .weekly(days: [0]))
        ctx.insert(sundaySchedule)
        let weekly = Habit(name: "Weekly", icon: "calendar", colorHex: "#000", schedule: sundaySchedule)
        sundaySchedule.habit = weekly
        ctx.insert(weekly)
        try ctx.save()

        // Pick a known Monday
        var comps = DateComponents()
        comps.year = 2024; comps.month = 1; comps.day = 1  // Monday
        let monday = Calendar.current.date(from: comps)!

        let due = try await repo.fetchDue(on: monday)
        #expect(due.contains { $0.id == daily.id })
        #expect(!due.contains { $0.id == weekly.id })
    }

    // MARK: - CompletionRepository

    @Test("recordCompletion saves and fetchCompletions retrieves it")
    func recordAndFetch() async throws {
        let ctx = try makeContext()
        let completionRepo = SwiftDataCompletionRepository(context: ctx)

        let habit = makeHabit(in: ctx)
        try ctx.save()

        let c = HabitCompletion(completedAt: Date(), habit: habit)
        try await completionRepo.recordCompletion(c)

        let results = try await completionRepo.fetchCompletions(for: habit)
        #expect(results.count == 1)
    }

    @Test("fetchCompletions returns newest first")
    func fetchCompletionsOrder() async throws {
        let ctx = try makeContext()
        let completionRepo = SwiftDataCompletionRepository(context: ctx)

        let habit = makeHabit(in: ctx)
        try ctx.save()

        let older = HabitCompletion(
            completedAt: Date(timeIntervalSinceNow: -3600),
            habit: habit
        )
        let newer = HabitCompletion(completedAt: Date(), habit: habit)

        try await completionRepo.recordCompletion(older)
        try await completionRepo.recordCompletion(newer)

        let results = try await completionRepo.fetchCompletions(for: habit)
        #expect(results.count == 2)
        #expect(results[0].completedAt >= results[1].completedAt)
    }

    @Test("deleteCompletion removes it from the store")
    func deleteCompletion() async throws {
        let ctx = try makeContext()
        let completionRepo = SwiftDataCompletionRepository(context: ctx)

        let habit = makeHabit(in: ctx)
        try ctx.save()

        let c = HabitCompletion(completedAt: Date(), habit: habit)
        try await completionRepo.recordCompletion(c)

        try await completionRepo.deleteCompletion(c)
        let results = try await completionRepo.fetchCompletions(for: habit)
        #expect(results.isEmpty)
    }

    // MARK: - ModelContainerConfiguration

    @Test("makeInMemoryContainer succeeds")
    func makeInMemoryContainer() throws {
        let container = try ModelContainerConfiguration.makeInMemoryContainer()
        #expect(container.configurations.isEmpty == false)
    }

    @Test("makeContainer without CloudKit succeeds")
    func makeContainerLocalOnly() throws {
        let container = try ModelContainerConfiguration.makeContainer(cloudKitEnabled: false)
        #expect(container.configurations.isEmpty == false)
    }

    // MARK: - DefaultsKeys

    @Test("DefaultsKeys constants are non-empty strings")
    func defaultsKeysNonEmpty() {
        #expect(!DefaultsKeys.iCloudSync.isEmpty)
        #expect(!DefaultsKeys.hapticsEnabled.isEmpty)
        #expect(!DefaultsKeys.selectedTheme.isEmpty)
        #expect(!DefaultsKeys.notificationSound.isEmpty)
    }

    @Test("registerDefaults does not crash")
    func registerDefaultsNoCrash() {
        DefaultsKeys.registerDefaults()
    }
}
