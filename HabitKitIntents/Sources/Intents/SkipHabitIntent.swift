import AppIntents
import Foundation

/// Skips a habit for the current day without counting it as a missed completion.
///
/// Skipped days are excluded from streak calculations.
public struct SkipHabitIntent: AppIntent {
    public static let title: LocalizedStringResource = "Skip Habit"
    public static let description = IntentDescription("Skip a habit for today without marking it as a failure.")
    public static let openAppWhenRun = false

    @Parameter(title: "Habit")
    public var habit: HabitEntity

    public init() {}

    public init(habit: HabitEntity) {
        self.habit = habit
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        // In a real app, this would write a skip record to SwiftData so the
        // habit does not count against the streak for today.
        return .result(dialog: "Skipped \(habit.name) for today.")
    }
}
