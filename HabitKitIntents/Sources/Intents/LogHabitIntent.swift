import AppIntents
import Foundation

/// Marks a habit as complete for the current day.
///
/// Exposed to Siri, Shortcuts, Control Center, and Spotlight.
/// Returns an inline confirmation snippet when invoked from Spotlight (iOS 26).
public struct LogHabitIntent: AppIntent {
    public static let title: LocalizedStringResource = "Log Habit"
    public static let description = IntentDescription("Mark a habit as complete for today.")
    public static let openAppWhenRun = false

    @Parameter(title: "Habit")
    public var habit: HabitEntity

    public init() {}

    public init(habit: HabitEntity) {
        self.habit = habit
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        // In a real app, this would write a completion record to SwiftData.
        return .result(dialog: "Marked \(habit.name) as complete.")
    }
}
