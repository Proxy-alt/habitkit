import AppIntents
import Foundation

/// Returns the list of habits that have not yet been completed or skipped today.
///
/// Equivalent to ``GetHabitsIntent`` with *Incomplete Only* toggled on.
/// Kept as a named shortcut for discoverability and backward compatibility.
public struct ListIncompleteHabitsIntent: AppIntent {
    public static let title: LocalizedStringResource = "List Incomplete Habits"
    public static let description = IntentDescription(
        "Returns all habits that have not yet been completed or skipped today."
    )
    public static let openAppWhenRun = false

    public init() {}

    public func perform() async throws -> some IntentResult & ReturnsValue<[HabitEntity]> {
        let store = HabitIntentStore(modelContainer: try IntentModelContainer.make())
        let habits = try await store.fetchHabits(
            incompleteOnly: true,
            minimumCompletionPct: 0,
            skippedIDs: SkipStore.skippedTodayIDs()
        )
        return .result(value: habits)
    }
}
