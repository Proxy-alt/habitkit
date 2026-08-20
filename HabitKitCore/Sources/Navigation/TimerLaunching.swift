/// Lets `HabitKitIntents` start a Live Activity timer without depending on
/// the App target's `AppNavigator` directly.
///
/// The App target's `AppNavigator` conforms to this and is registered with
/// `AppDependencyManager` at launch; `StartTimerIntent` resolves it via
/// `@Dependency`.
@MainActor
public protocol TimerLaunching: AnyObject, Sendable {
    func startTimer(for habit: TimedHabit)
}
