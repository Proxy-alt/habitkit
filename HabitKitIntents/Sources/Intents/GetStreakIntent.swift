import AppIntents
import Foundation

public struct GetStreakIntent: AppIntent {
    public static let title: LocalizedStringResource = "Get Habit Streak"
    public static let description = IntentDescription("Returns the current consecutive-day streak for a habit.")
    public static let openAppWhenRun = false

    @Parameter(title: "Habit")
    public var habit: HabitEntity

    public init() {}

    public init(habit: HabitEntity) {
        self.habit = habit
    }

    public func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        // In a real app, this would query SwiftData for consecutive completion
        // records ending today and return the count.
        let streak: Int = 0
        return .result(value: streak)
    }
}
