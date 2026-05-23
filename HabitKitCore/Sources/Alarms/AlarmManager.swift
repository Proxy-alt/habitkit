import AlarmKit
import Foundation

// MARK: - AlarmManager

/// Manages AlarmKit alarms for habit reminders (iOS 26+).
///
/// Each habit can have at most one active alarm. Alarms are scheduled using
/// `AlarmKit` and present a full-screen alert with Complete / Snooze actions.
public actor AlarmManager {

    // MARK: - Shared instance

    public static let shared = AlarmManager()

    // MARK: - Private state

    /// Maps habit UUID to the currently-active `Alarm` identifier.
    private var scheduledAlarms: [UUID: String] = [:]

    // MARK: - Init

    private init() {}

    // MARK: - Schedule

    /// Schedules (or replaces) the alarm for a given habit.
    ///
    /// - Parameters:
    ///   - habitID: The habit to alarm for.
    ///   - habitName: User-visible title shown on the alarm screen.
    ///   - date: The exact date/time at which the alarm fires.
    public func scheduleAlarm(for habitID: UUID, habitName: String, at date: Date) async throws {
        // Cancel any existing alarm for this habit first.
        await cancelAlarm(for: habitID)

        let attributes = HabitAlarmAttributes(habitID: habitID, habitName: habitName)
        let content = AlarmContent(
            title: habitName,
            body: "Time to complete your habit.",
            sound: .default
        )
        let alarm = Alarm(
            id: habitID.uuidString,
            schedule: .fixed(date),
            attributes: attributes,
            content: content,
            actions: [
                AlarmAction(identifier: "COMPLETE", title: "Complete"),
                AlarmAction(identifier: "SNOOZE", title: "Snooze 10 min"),
            ]
        )
        try await AlarmCenter.shared.add(alarm)
        scheduledAlarms[habitID] = habitID.uuidString
    }

    /// Cancels the alarm for a given habit if one exists.
    public func cancelAlarm(for habitID: UUID) async {
        guard let identifier = scheduledAlarms[habitID] else { return }
        await AlarmCenter.shared.remove(withIdentifier: identifier)
        scheduledAlarms.removeValue(forKey: habitID)
    }

    /// Cancels all active alarms managed by HabitKit.
    public func cancelAllAlarms() async {
        for identifier in scheduledAlarms.values {
            await AlarmCenter.shared.remove(withIdentifier: identifier)
        }
        scheduledAlarms.removeAll()
    }
}

// MARK: - HabitAlarmAttributes

/// Metadata attached to a HabitKit alarm, passed to the alarm handler.
public struct HabitAlarmAttributes: AlarmAttributes {
    public typealias ContentState = HabitAlarmContentState

    public var habitID: UUID
    public var habitName: String

    public init(habitID: UUID, habitName: String) {
        self.habitID = habitID
        self.habitName = habitName
    }
}

// MARK: - HabitAlarmContentState

/// Dynamic content for a HabitKit alarm (supports live updates).
public struct HabitAlarmContentState: Codable, Hashable, Sendable {
    /// Whether the alarm has already been acknowledged during this session.
    public var isAcknowledged: Bool

    public init(isAcknowledged: Bool = false) {
        self.isAcknowledged = isAcknowledged
    }
}
