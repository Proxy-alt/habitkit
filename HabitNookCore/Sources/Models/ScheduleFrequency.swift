import Foundation

/// Defines how often a habit should be performed.
public enum ScheduleFrequency: Codable, Hashable, Sendable {
    /// The habit is required every day.
    case daily

    /// The habit is required on specific days of the week.
    /// `days` is a set of integers where 0 = Sunday and 6 = Saturday.
    case weekly(days: Set<Int>)

    /// The habit is required every N days.
    case interval(every: Int)

    /// The habit must be completed a certain number of times within any 7-day rolling window.
    case xTimesPerWeek(x: Int)
}
