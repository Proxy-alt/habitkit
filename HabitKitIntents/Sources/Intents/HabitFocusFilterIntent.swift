import AppIntents
import Foundation

// MARK: - HabitFocusFilterIntent (§8.5)

/// A `SetFocusFilterIntent` that configures which habits are visible during
/// a given Focus Mode (§8.5).
///
/// When the user assigns a Focus Mode to HabitKit in System Settings →
/// Focus → App Customisation, they can select:
/// - Which habit groups appear
/// - Whether to hide sensitive habits
/// - Whether to silence completion notifications
///
/// HabitKit reads `focusModeID` from the active configuration to filter
/// `GetHabitsIntent` and the Today view.
public struct HabitFocusFilterIntent: SetFocusFilterIntent {
    public static let title: LocalizedStringResource = "Configure HabitKit for Focus"
    public static let description = IntentDescription(
        "Choose which habits and notifications appear when this Focus is active."
    )

    // MARK: - Parameters

    /// An optional habit group name to restrict the Today view to.
    @Parameter(
        title: "Habit Group",
        description: "Only show habits in this group when this Focus is active.",
        default: nil
    )
    public var habitGroup: String?

    /// Whether to hide sensitive habits during this Focus.
    @Parameter(
        title: "Hide Sensitive Habits",
        description: "When enabled, habits marked as sensitive are hidden.",
        default: false
    )
    public var hideSensitiveHabits: Bool

    /// Whether to suppress habit completion notifications during this Focus.
    @Parameter(
        title: "Silence Notifications",
        description: "When enabled, habit reminder notifications are silenced.",
        default: false
    )
    public var silenceNotifications: Bool

    /// A stable identifier written to `Habit.focusModeID` for filtering.
    @Parameter(
        title: "Focus Mode ID",
        description: "Unique identifier used to tag habits for this Focus.",
        default: nil
    )
    public var focusModeID: String?

    // MARK: - Init

    public init() {}

    // MARK: - Perform

    public func perform() async throws -> some IntentResult {
        // Persist the configuration to shared UserDefaults so the Today view
        // and widget can read it without invoking the intent again.
        let defaults = UserDefaults(suiteName: "group.com.habitkit.app")
        defaults?.set(habitGroup, forKey: "focus.habitGroup")
        defaults?.set(hideSensitiveHabits, forKey: "focus.hideSensitive")
        defaults?.set(silenceNotifications, forKey: "focus.silenceNotifications")
        defaults?.set(focusModeID, forKey: "focus.focusModeID")

        if silenceNotifications {
            await NotificationScheduler.shared.cancelAllReminders()
        }

        NotificationCenter.default.post(
            name: .focusFilterDidChange,
            object: nil,
            userInfo: [
                "habitGroup": habitGroup as Any,
                "hideSensitive": hideSensitiveHabits,
                "silence": silenceNotifications,
            ]
        )
        return .result()
    }
}

// MARK: - FocusFilterConfiguration

/// A snapshot of the active Focus Filter configuration.
///
/// Read by `TodayViewModel` on each app foreground to apply filtering.
public struct FocusFilterConfiguration: Sendable {
    public var habitGroup: String?
    public var hideSensitiveHabits: Bool
    public var silenceNotifications: Bool
    public var focusModeID: String?

    /// Loads the current configuration from shared UserDefaults.
    public static func current() -> FocusFilterConfiguration {
        let defaults = UserDefaults(suiteName: "group.com.habitkit.app")
        return FocusFilterConfiguration(
            habitGroup: defaults?.string(forKey: "focus.habitGroup"),
            hideSensitiveHabits: defaults?.bool(forKey: "focus.hideSensitive") ?? false,
            silenceNotifications: defaults?.bool(forKey: "focus.silenceNotifications") ?? false,
            focusModeID: defaults?.string(forKey: "focus.focusModeID")
        )
    }

    public init(
        habitGroup: String?,
        hideSensitiveHabits: Bool,
        silenceNotifications: Bool,
        focusModeID: String?
    ) {
        self.habitGroup = habitGroup
        self.hideSensitiveHabits = hideSensitiveHabits
        self.silenceNotifications = silenceNotifications
        self.focusModeID = focusModeID
    }
}

// MARK: - Notification names

public extension Notification.Name {
    /// Posted when the Focus Filter configuration changes.
    static let focusFilterDidChange = Notification.Name("com.habitkit.focusFilterDidChange")
}
