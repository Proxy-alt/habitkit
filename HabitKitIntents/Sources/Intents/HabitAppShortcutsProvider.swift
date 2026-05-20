import AppIntents

/// Registers HabitKit's built-in App Shortcuts with Siri and Shortcuts.app.
///
/// Phrases defined here appear in Siri suggestions and can be triggered
/// without opening the app.
public struct HabitAppShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetHabitsIntent(incompleteOnly: true),
            phrases: [
                "Show my incomplete habits in \(.applicationName)",
                "What habits do I still have today in \(.applicationName)",
            ],
            shortTitle: "Incomplete Habits",
            systemImageName: "list.bullet.circle"
        )

        AppShortcut(
            intent: LogHabitIntent(),
            phrases: [
                "Log \(\.$habit) in \(.applicationName)",
                "Mark \(\.$habit) done in \(.applicationName)",
            ],
            shortTitle: "Log Habit",
            systemImageName: "checkmark.circle.fill"
        )

        AppShortcut(
            intent: StartTimerIntent(),
            phrases: [
                "Start \(\.$habit) timer in \(.applicationName)",
            ],
            shortTitle: "Start Timer",
            systemImageName: "timer"
        )
    }
}
