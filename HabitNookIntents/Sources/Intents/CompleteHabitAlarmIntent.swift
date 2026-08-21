import AppIntents
import Foundation

/// Marks a habit as complete when the person taps "Complete" on its reminder alarm.
///
/// Passed as the `stopIntent` when scheduling a habit's `HabitAlarmScheduler`
/// alarm, so it must be a `LiveActivityIntent` — AlarmKit runs it directly
/// from the alarm's system UI rather than through Siri or Shortcuts.
public struct CompleteHabitAlarmIntent: AppIntent, LiveActivityIntent {
    public static let title: LocalizedStringResource = "Complete Habit"
    public static let description = IntentDescription("Mark a habit as complete from its reminder alarm.")
    public static let openAppWhenRun = false

    @Parameter(title: "Habit")
    public var habit: HabitEntity

    public init() {}

    public init(habit: HabitEntity) {
        self.habit = habit
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = HabitIntentStore(modelContainer: try IntentModelContainer.make())
        try await store.logCompletion(for: habit.id)
        return .result(dialog: "Marked \(habit.name) as complete.")
    }
}
