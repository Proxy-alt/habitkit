import AppIntents
import Foundation
import HabitKitCore
import SwiftData

/// Brings HabitKit to the foreground and starts a Live Activity timer for a timed habit.
///
/// Because `openAppWhenRun` is `true`, `perform()` runs in the host app's own
/// process (StartTimerIntent is linked directly into the app target, not a
/// separate extension). This lets it resolve the app's `AppNavigator` — via
/// the `TimerLaunching` dependency registered in `HabitKitApp` — and hand it
/// the resolved `TimedHabit`, which switches to the Live tab and starts the
/// `ActivityKit` Live Activity.
public struct StartTimerIntent: AppIntent {
    public static let title: LocalizedStringResource = "Start Habit Timer"
    public static let description = IntentDescription(
        "Brings HabitKit to the foreground and starts a Live Activity timer for the selected habit."
    )
    /// Opening the app is required so it can start and own the Live Activity.
    public static let openAppWhenRun = true

    @Parameter(title: "Habit")
    public var habit: HabitEntity

    @Dependency private var navigator: any TimerLaunching
    @Dependency private var modelContainer: ModelContainer

    public init() {}

    public init(habit: HabitEntity) {
        self.habit = habit
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let habitID = habit.id
        let descriptor = FetchDescriptor<TimedHabit>(predicate: #Predicate { $0.id == habitID })
        guard let timedHabit = try modelContainer.mainContext.fetch(descriptor).first else {
            return .result(dialog: "Couldn't find a timed habit named \(habit.name).")
        }
        navigator.startTimer(for: timedHabit)
        return .result(dialog: "Starting timer for \(habit.name).")
    }
}
