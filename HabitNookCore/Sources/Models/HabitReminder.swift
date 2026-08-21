import Foundation

/// A single time-of-day reminder for a habit, backed by an AlarmKit alarm.
///
/// `id` is stable across edits (unlike an array index) so a habit's reminders
/// can be added, removed, or retimed independently — it doubles as the
/// AlarmKit alarm id, so `HabitAlarmScheduler` knows which alarm to
/// reschedule or cancel when a single reminder changes.
public struct HabitReminder: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID

    /// Only the hour and minute components are meaningful.
    public var time: Date

    public init(id: UUID = UUID(), time: Date) {
        self.id = id
        self.time = time
    }
}
