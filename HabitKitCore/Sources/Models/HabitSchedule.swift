import Foundation
import SwiftData

/// Stores the scheduling rule and reminder configuration for a habit.
@Model
public class HabitSchedule {
    /// How often the habit should be performed.
    public var frequency: ScheduleFrequency

    /// List of times during the day when the user should receive a reminder.
    /// Only the hour and minute components of each Date are meaningful.
    public var reminderTimes: [Date]

    /// The habit this schedule belongs to. `nil` only during object-graph
    /// construction (e.g. previews and tests); always non-`nil` in production.
    public var habit: Habit?

    public init(
        frequency: ScheduleFrequency,
        reminderTimes: [Date] = [],
        habit: Habit? = nil
    ) {
        self.frequency = frequency
        self.reminderTimes = reminderTimes
        self.habit = habit
    }

    /// Returns true when this schedule requires the habit to be performed on `date`.
    ///
    /// - Parameter date: The calendar day to evaluate.
    /// - Returns: `true` if the habit is due on that day.
    public func isDue(on date: Date) -> Bool {
        let calendar = Calendar.current

        switch frequency {
        case .daily:
            return true

        case .weekly(let days):
            // weekday: 1=Sunday, 2=Monday … 7=Saturday  → convert to 0-based Sunday=0
            let weekday = calendar.component(.weekday, from: date) - 1
            return days.contains(weekday)

        case .interval(let every):
            guard every > 0 else { return false }
            guard let createdAt = habit?.createdAt else { return false }
            let startOfCreation = calendar.startOfDay(for: createdAt)
            let startOfTarget = calendar.startOfDay(for: date)
            let components = calendar.dateComponents([.day], from: startOfCreation, to: startOfTarget)
            let daysDiff = components.day ?? 0
            // Avoid counting days before the habit was created.
            guard daysDiff >= 0 else { return false }
            return daysDiff % every == 0

        case .xTimesPerWeek:
            // xTimesPerWeek schedules do not mark specific calendar days as "due";
            // instead, the habit is eligible any day of the week. The caller is
            // responsible for checking how many completions have occurred this week.
            return true
        }
    }
}
