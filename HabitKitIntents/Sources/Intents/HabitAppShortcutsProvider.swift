import AppIntents

public struct HabitAppShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
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
