import Observation
import HabitKitCore

enum AppTab {
    case today, habits, analytics, live, settings
}

/// Observable app-level navigation state, shared across tabs.
///
/// Inject an instance at the app root:
/// ```swift
/// @State private var navigator = AppNavigator()
///
/// WindowGroup {
///     ContentView()
///         .environment(navigator)
/// }
/// ```
@MainActor
@Observable
final class AppNavigator: TimerLaunching, @unchecked Sendable {
    var selectedTab: AppTab = .today
    var pendingTimerHabit: TimedHabit?

    /// Switches to the Live tab and queues `habit` to start a session as soon as it appears.
    func startTimer(for habit: TimedHabit) {
        pendingTimerHabit = habit
        selectedTab = .live
    }
}
