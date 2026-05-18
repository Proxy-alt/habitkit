import AppIntents
import Foundation

public struct StartTimerIntent: AppIntent {
    public static let title: LocalizedStringResource = "Start Habit Timer"
    public static let description = IntentDescription(
        "Brings HabitKit to the foreground and starts a Live Activity timer for the selected habit."
    )
    /// Opening the app is required so it can start and own the Live Activity.
    public static let openAppWhenRun = true

    @Parameter(title: "Habit")
    public var habit: HabitEntity

    public init() {}

    public init(habit: HabitEntity) {
        self.habit = habit
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        // The app is brought to the foreground by the system before perform()
        // is called (because openAppWhenRun == true). The app itself observes
        // the intent result and starts the Live Activity for the given habit.
        return .result(dialog: "Starting timer for \(habit.name).")
    }
}
