import AppIntents
import Foundation

/// Returns the list of habits that have not yet been completed or skipped today.
///
/// The result is an array of ``HabitEntity`` values, usable as input to other
/// Shortcuts steps such as ``LogHabitIntent``.
public struct ListIncompleteHabitsIntent: AppIntent {
    public static let title: LocalizedStringResource = "List Incomplete Habits"
    public static let description = IntentDescription(
        "Returns all habits that have not yet been completed or skipped today."
    )
    public static let openAppWhenRun = false

    public init() {}

    public func perform() async throws -> some IntentResult & ReturnsValue<[HabitEntity]> {
        let store = HabitIntentStore(modelContainer: IntentModelContainer.shared)
        let skipped = SkipStore.skippedTodayIDs()
        let incomplete = try await store.incompleteHabitsToday(skippedIDs: skipped)
        return .result(value: incomplete)
    }
}
