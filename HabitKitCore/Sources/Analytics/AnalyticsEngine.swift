import Foundation

// MARK: - AnalyticsPeriod

/// A fixed lookback window used for rate calculations.
public enum AnalyticsPeriod: Sendable {
    case sevenDays
    case thirtyDays
    case ninetyDays

    /// The number of calendar days in this period.
    public var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        }
    }
}

// MARK: - AnalyticsEngine

/// Computes statistics about a user's habit performance.
public actor AnalyticsEngine {

    // MARK: - Completion rate

    /// Returns the fraction of scheduled days within `period` on which the habit
    /// was completed.
    ///
    /// - Parameters:
    ///   - habit: The habit to analyse.
    ///   - period: The lookback window.
    /// - Returns: A value in [0, 1]. Returns 0 when no days were scheduled.
    public func completionRate(for habit: Habit, over period: AnalyticsPeriod) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let periodStart = calendar.date(byAdding: .day, value: -(period.days - 1), to: today) ?? today

        // Completions mapped to calendar-day start times.
        let completedDays: Set<Date> = Set(
            habit.completions
                .map { calendar.startOfDay(for: $0.completedAt) }
                .filter { $0 >= periodStart && $0 <= today }
        )

        // Count scheduled days in the period.
        var scheduledCount = 0
        var completedCount = 0
        var cursor = periodStart

        while cursor <= today {
            if habit.schedule.isDue(on: cursor) {
                scheduledCount += 1
                if completedDays.contains(cursor) {
                    completedCount += 1
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        guard scheduledCount > 0 else { return 0 }
        return Double(completedCount) / Double(scheduledCount)
    }

    // MARK: - Best time of day

    /// Returns the most common hour-and-minute at which the habit is completed.
    ///
    /// - Parameter habit: The habit to analyse.
    /// - Returns: A `DateComponents` with `.hour` and `.minute` set, or `nil` if
    ///   the habit has no completions.
    public func bestTimeOfDay(for habit: Habit) -> DateComponents? {
        guard !habit.completions.isEmpty else { return nil }

        let calendar = Calendar.current

        // Bucket completions by (hour, minute) pair and count occurrences.
        var frequency: [HourMinute: Int] = [:]
        for completion in habit.completions {
            let comps = calendar.dateComponents([.hour, .minute], from: completion.completedAt)
            if let hour = comps.hour, let minute = comps.minute {
                let key = HourMinute(hour: hour, minute: minute)
                frequency[key, default: 0] += 1
            }
        }

        guard let best = frequency.max(by: { $0.value < $1.value })?.key else { return nil }

        var result = DateComponents()
        result.hour = best.hour
        result.minute = best.minute
        return result
    }

    // MARK: - Pearson correlation

    /// Computes the Pearson correlation coefficient between the daily completion
    /// patterns of two habits over the last 30 calendar days.
    ///
    /// Each day is represented as 1.0 (at least one completion) or 0.0 (none).
    ///
    /// - Parameters:
    ///   - habitA: The first habit.
    ///   - habitB: The second habit.
    /// - Returns: A value in [-1, 1], or 0 if the coefficient is undefined
    ///   (e.g. one series has zero variance).
    public func correlationCoefficient(between habitA: Habit, and habitB: Habit) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let windowDays = 30

        // Build a sorted list of the last 30 days.
        var days: [Date] = []
        for offset in stride(from: -(windowDays - 1), through: 0, by: 1) {
            if let day = calendar.date(byAdding: .day, value: offset, to: today) {
                days.append(day)
            }
        }

        let completedA = daySet(from: habitA.completions, calendar: calendar)
        let completedB = daySet(from: habitB.completions, calendar: calendar)

        let x = days.map { completedA.contains($0) ? 1.0 : 0.0 }
        let y = days.map { completedB.contains($0) ? 1.0 : 0.0 }

        return pearson(x: x, y: y)
    }

    // MARK: - Heatmap data

    /// Returns the number of completions per calendar day over the last 365 days.
    ///
    /// - Parameters:
    ///   - habit: The habit to analyse.
    ///   - calendar: The calendar used to normalise dates to day boundaries.
    /// - Returns: A dictionary mapping each day's start `Date` to the completion
    ///   count on that day. Days with zero completions are omitted.
    public func heatmapData(for habit: Habit, in calendar: Calendar) -> [Date: Int] {
        let today = calendar.startOfDay(for: Date())
        guard let yearStart = calendar.date(byAdding: .day, value: -364, to: today) else { return [:] }

        var counts: [Date: Int] = [:]
        for completion in habit.completions {
            let day = calendar.startOfDay(for: completion.completedAt)
            guard day >= yearStart && day <= today else { continue }
            counts[day, default: 0] += 1
        }
        return counts
    }

    // MARK: - Private helpers

    private func daySet(from completions: [HabitCompletion], calendar: Calendar) -> Set<Date> {
        Set(completions.map { calendar.startOfDay(for: $0.completedAt) })
    }

    /// Computes the Pearson correlation coefficient for two equal-length sequences.
    private func pearson(x: [Double], y: [Double]) -> Double {
        let n = Double(x.count)
        guard n > 0, x.count == y.count else { return 0 }

        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n

        var numerator = 0.0
        var denomX = 0.0
        var denomY = 0.0

        for i in 0 ..< x.count {
            let dx = x[i] - meanX
            let dy = y[i] - meanY
            numerator += dx * dy
            denomX += dx * dx
            denomY += dy * dy
        }

        let denominator = (denomX * denomY).squareRoot()
        guard denominator > 0 else { return 0 }
        return numerator / denominator
    }
}

// MARK: - Internal value types

/// Hashable (hour, minute) pair used for frequency bucketing.
private struct HourMinute: Hashable {
    let hour: Int
    let minute: Int
}
