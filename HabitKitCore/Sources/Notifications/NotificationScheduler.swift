import Foundation
import UserNotifications

// MARK: - NotificationScheduler

/// Schedules and manages UNUserNotification reminders for habits (§8.13).
///
/// Each habit reminder delivers a notification with Complete and Skip
/// actionable buttons. Tapping Complete calls the `LogHabitIntent` via
/// the notification response.
public actor NotificationScheduler {

    // MARK: - Shared instance

    public static let shared = NotificationScheduler()

    // MARK: - Category and action identifiers

    public static let habitCategoryIdentifier = "HABIT_REMINDER"
    public static let completeActionIdentifier = "HABIT_COMPLETE"
    public static let skipActionIdentifier = "HABIT_SKIP"

    // MARK: - Init

    private init() {}

    // MARK: - Authorization

    /// Requests notification authorization with alert, badge, and sound options.
    ///
    /// - Returns: `true` if authorization was granted.
    @discardableResult
    public func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        if granted {
            registerCategories()
        }
        return granted
    }

    // MARK: - Scheduling

    /// Schedules a daily reminder notification for a habit.
    ///
    /// - Parameters:
    ///   - habit: Lightweight representation of the habit to remind.
    ///   - hour: The hour component for the reminder (0–23).
    ///   - minute: The minute component for the reminder (0–59).
    public func scheduleDailyReminder(
        habitID: UUID,
        habitName: String,
        habitIcon: String,
        hour: Int,
        minute: Int
    ) async {
        let center = UNUserNotificationCenter.current()

        // Remove any existing notification for this habit first.
        await cancelReminder(for: habitID)

        let content = UNMutableNotificationContent()
        content.title = habitName
        content.body = "Time to complete your habit!"
        content.sound = .default
        content.categoryIdentifier = Self.habitCategoryIdentifier
        content.userInfo = ["habitID": habitID.uuidString, "habitName": habitName]
        content.badge = 1

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: notificationID(for: habitID),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    /// Cancels the scheduled reminder for a specific habit.
    ///
    /// - Parameter habitID: The habit whose reminder should be cancelled.
    public func cancelReminder(for habitID: UUID) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID(for: habitID)])
    }

    /// Cancels all pending HabitKit notifications.
    public func cancelAllReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let habitKitIDs = pending
            .map(\.identifier)
            .filter { $0.hasPrefix("habitkit.reminder.") }
        center.removePendingNotificationRequests(withIdentifiers: habitKitIDs)
    }

    // MARK: - Private helpers

    private func notificationID(for habitID: UUID) -> String {
        "habitkit.reminder.\(habitID.uuidString)"
    }

    private func registerCategories() {
        let completeAction = UNNotificationAction(
            identifier: Self.completeActionIdentifier,
            title: "Complete",
            options: [.authenticationRequired]
        )
        let skipAction = UNNotificationAction(
            identifier: Self.skipActionIdentifier,
            title: "Skip",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Self.habitCategoryIdentifier,
            actions: [completeAction, skipAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
