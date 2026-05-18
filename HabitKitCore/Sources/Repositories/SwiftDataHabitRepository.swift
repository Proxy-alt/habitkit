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

    nonisolated func fetchAll() async throws -> [Habit] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate { !$0.isArchived },
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            return try context.fetch(descriptor)
        }
    }

    nonisolated func fetchDue(on date: Date) async throws -> [Habit] {
        let all = try await fetchAll()
        return all.filter { $0.schedule.isDue(on: date) }
    }

    nonisolated func save(_ habit: Habit) async throws {
        try await MainActor.run {
            context.insert(habit)
            try context.save()
        }
    }

    nonisolated func delete(_ habit: Habit) async throws {
        try await MainActor.run {
            context.delete(habit)
            try context.save()
        }
    }

    nonisolated func archive(_ habit: Habit) async throws {
        try await MainActor.run {
            habit.isArchived = true
            try context.save()
        }
    }

    nonisolated func reorder(_ habits: [Habit]) async throws {
        try await MainActor.run {
            for (index, habit) in habits.enumerated() {
                habit.sortOrder = index
            }
            try context.save()
        }
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

    nonisolated func fetchCompletions(for habit: Habit) async throws -> [HabitCompletion] {
        try await MainActor.run {
            let habitID = habit.id
            let descriptor = FetchDescriptor<HabitCompletion>(
                predicate: #Predicate { $0.habit.id == habitID },
                sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
            )
            return try context.fetch(descriptor)
        }
    }

    nonisolated func recordCompletion(_ completion: HabitCompletion) async throws {
        try await MainActor.run {
            context.insert(completion)
            try context.save()
        }
    }

    nonisolated func deleteCompletion(_ completion: HabitCompletion) async throws {
        try await MainActor.run {
            context.delete(completion)
            try context.save()
        }
    }
}
