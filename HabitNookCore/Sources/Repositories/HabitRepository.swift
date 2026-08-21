import Foundation

/// Abstraction over the SwiftData persistence layer for `Habit` records.
///
/// All UI layer code interacts with habits through this protocol, never via
/// `ModelContext` directly. This enables testing with a fake implementation.
@MainActor
public protocol HabitRepository {
    /// Returns all non-archived habits, sorted by `sortOrder`.
    func fetchAll() async throws -> [Habit]
    /// Returns all habits due on the given date, sorted by `sortOrder`.
    func fetchDue(on date: Date) async throws -> [Habit]
    /// Persists a new or updated habit.
    func save(_ habit: Habit) async throws
    /// Permanently removes a habit and all its completions.
    func delete(_ habit: Habit) async throws
    /// Archives a habit (sets `isArchived = true`).
    func archive(_ habit: Habit) async throws
    /// Updates the `sortOrder` of habits to reflect the given ordered array.
    func reorder(_ habits: [Habit]) async throws
}
