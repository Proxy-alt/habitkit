import Foundation

/// Pure-function utilities for computing habit streaks from completion history.
public struct StreakCalculator: Sendable {

    // MARK: - Public API

    /// Returns the number of consecutive scheduled days ending today (or yesterday
    /// if today has not yet had a completion) on which the habit was completed.
    ///
    /// - Parameters:
    ///   - completions: All recorded completions for the habit, in any order.
    ///   - schedule: The habit's scheduling rule.
    /// - Returns: The current streak length in days (0 if no streak exists).
    public static func currentStreak(
        completions: [HabitCompletion],
        schedule: HabitSchedule
    ) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let completedDays = completedDaySet(from: completions, calendar: calendar)

        // Walk backwards from today, counting consecutive due days that were completed.
        var streak = 0
        var cursor = today

        // If today is a due day but not yet completed, start counting from yesterday.
        if schedule.isDue(on: cursor) && !completedDays.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }

        while true {
            if schedule.isDue(on: cursor) {
                if completedDays.contains(cursor) {
                    streak += 1
                } else {
                    break
                }
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            // Stop if we've gone further back than the earliest completion.
            if let earliest = completedDays.min(), previous < earliest { break }
            cursor = previous
        }

        return streak
    }

    /// Returns the longest consecutive streak of scheduled days ever achieved.
    ///
    /// - Parameters:
    ///   - completions: All recorded completions for the habit, in any order.
    ///   - schedule: The habit's scheduling rule.
    /// - Returns: The longest streak length in days (0 if there are no completions).
    public static func longestStreak(
        completions: [HabitCompletion],
        schedule: HabitSchedule
    ) -> Int {
        let calendar = Calendar.current
        let completedDays = completedDaySet(from: completions, calendar: calendar)
        guard let earliest = completedDays.min(), let latest = completedDays.max() else { return 0 }

        var longest = 0
        var current = 0
        var cursor = earliest

        while cursor <= latest {
            if schedule.isDue(on: cursor) {
                if completedDays.contains(cursor) {
                    current += 1
                    longest = max(longest, current)
                } else {
                    current = 0
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return longest
    }

    /// Returns the most recent date on which a streak was broken, or `nil` if
    /// no streak break has occurred.
    ///
    /// A streak break is defined as a scheduled due day that was missed (no
    /// completion recorded) and is in the past.
    ///
    /// - Parameters:
    ///   - completions: All recorded completions for the habit, in any order.
    ///   - schedule: The habit's scheduling rule.
    /// - Returns: The calendar day of the most recent streak break, or `nil`.
    public static func streakBreakDate(
        completions: [HabitCompletion],
        schedule: HabitSchedule
    ) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let completedDays = completedDaySet(from: completions, calendar: calendar)
        guard let earliest = completedDays.min() else { return nil }

        var breakDate: Date? = nil
        var cursor = earliest

        // Walk forward up to (but not including) today, looking for missed due days.
        while cursor < today {
            if schedule.isDue(on: cursor) && !completedDays.contains(cursor) {
                // Keep the latest break date found.
                if breakDate == nil || cursor > breakDate! {
                    breakDate = cursor
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return breakDate
    }

    // MARK: - Internal helpers

    /// Builds a `Set<Date>` of calendar-day start times from a list of completions.
    private static func completedDaySet(
        from completions: [HabitCompletion],
        calendar: Calendar
    ) -> Set<Date> {
        Set(completions.map { calendar.startOfDay(for: $0.completedAt) })
    }
}
