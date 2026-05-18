import AppIntents
import Foundation

public struct ListIncompleteHabitsIntent: AppIntent {
    public static let title: LocalizedStringResource = "List Incomplete Habits"
    public static let description = IntentDescription(
        "Returns all habits that have not yet been completed or skipped today."
    )
    public static let openAppWhenRun = false

    public init() {}

    public func perform() async throws -> some IntentResult & ReturnsValue<[HabitEntity]> {
        // In a real app, this would query SwiftData for habits scheduled today
        // that have no completion or skip record for the current calendar day.
        let incompleteHabits: [HabitEntity] = []
        return .result(value: incompleteHabits)
    }
}
