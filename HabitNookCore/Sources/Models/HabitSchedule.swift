import Foundation
import SwiftData

/// Stores the scheduling rule and reminder configuration for a habit.
@Model
public class HabitSchedule {
    /// JSON-encoded `ScheduleFrequency`. Stored as `Data` so SwiftData's schema
    /// analyser never traverses the enum's associated-value payload (Set<Int>
    /// uses Builtin.BridgeObject internally, which crashes SchemaProperty).
    private var frequencyData: Data = Data()

    /// JSON-encoded `[HabitReminder]`. Stored as `Data` for the same reason:
    /// Array<HabitReminder> also uses Builtin.BridgeObject for its CoW storage buffer.
    private var remindersData: Data = Data()

    /// The habit this schedule belongs to. `nil` only during object-graph
    /// construction (e.g. previews and tests); always non-`nil` in production.
    @Relationship(inverse: \Habit.scheduleStorage)
    public var habit: Habit?

    /// The scheduling rule for this habit. Computed over `frequencyData`.
    public var frequency: ScheduleFrequency {
        get {
            (try? JSONDecoder().decode(ScheduleFrequency.self, from: frequencyData)) ?? .daily
        }
        set {
            frequencyData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    /// Times during the day when the user should receive a reminder, each
    /// backed by its own AlarmKit alarm. Computed over `remindersData`.
    public var reminders: [HabitReminder] {
        get {
            (try? JSONDecoder().decode([HabitReminder].self, from: remindersData)) ?? []
        }
        set {
            remindersData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    /// Convenience view of `reminders` as bare times, for callers that don't
    /// need per-reminder ids. Setting this replaces `reminders` with fresh ids.
    public var reminderTimes: [Date] {
        get { reminders.map(\.time) }
        set { reminders = newValue.map { HabitReminder(time: $0) } }
    }

    public init(
        frequency: ScheduleFrequency,
        reminderTimes: [Date] = [],
        habit: Habit? = nil
    ) {
        self.frequencyData = (try? JSONEncoder().encode(frequency)) ?? Data()
        let reminders = reminderTimes.map { HabitReminder(time: $0) }
        self.remindersData = (try? JSONEncoder().encode(reminders)) ?? Data()
        self.habit = habit
    }

    /// Returns true when this schedule requires the habit to be performed on `date`.
    public func isDue(on date: Date) -> Bool {
        let calendar = Calendar.current

        switch frequency {
        case .daily:
            return true

        case .weekly(let days):
            let weekday = calendar.component(.weekday, from: date) - 1
            return days.contains(weekday)

        case .interval(let every):
            guard every > 0 else { return false }
            guard let createdAt = habit?.createdAt else { return false }
            let startOfCreation = calendar.startOfDay(for: createdAt)
            let startOfTarget = calendar.startOfDay(for: date)
            let components = calendar.dateComponents([.day], from: startOfCreation, to: startOfTarget)
            let daysDiff = components.day ?? 0
            guard daysDiff >= 0 else { return false }
            return daysDiff % every == 0

        case .xTimesPerWeek:
            return true
        }
    }
}
