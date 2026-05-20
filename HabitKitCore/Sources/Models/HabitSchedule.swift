import Foundation
import SwiftData

/// Stores the scheduling rule and reminder configuration for a habit.
@Model
public class HabitSchedule {
    /// JSON-encoded `ScheduleFrequency`. Stored as `Data` so SwiftData's schema
    /// analyser never traverses the enum's associated-value payload (Set<Int>
    /// uses Builtin.BridgeObject internally, which crashes SchemaProperty).
    private var frequencyData: Data

    /// JSON-encoded `[Date]`. Stored as `Data` for the same reason: Array<Date>
    /// also uses Builtin.BridgeObject for its CoW storage buffer.
    private var reminderTimesData: Data

    /// The habit this schedule belongs to. `nil` only during object-graph
    /// construction (e.g. previews and tests); always non-`nil` in production.
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

    /// List of times during the day when the user should receive a reminder.
    /// Only the hour and minute components of each Date are meaningful.
    public var reminderTimes: [Date] {
        get {
            (try? JSONDecoder().decode([Date].self, from: reminderTimesData)) ?? []
        }
        set {
            reminderTimesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    public init(
        frequency: ScheduleFrequency,
        reminderTimes: [Date] = [],
        habit: Habit? = nil
    ) {
        self.frequencyData = (try? JSONEncoder().encode(frequency)) ?? Data()
        self.reminderTimesData = (try? JSONEncoder().encode(reminderTimes)) ?? Data()
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
