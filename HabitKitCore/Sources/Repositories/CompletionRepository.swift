import Foundation

/// Abstraction over the persistence layer for `HabitCompletion` records.
public protocol CompletionRepository: Sendable {
    /// Returns all completions for a habit, newest first.
    func fetchCompletions(for habit: Habit) async throws -> [HabitCompletion]
    /// Records a new completion.
    func recordCompletion(_ completion: HabitCompletion) async throws
    /// Removes a completion record.
    func deleteCompletion(_ completion: HabitCompletion) async throws
}
