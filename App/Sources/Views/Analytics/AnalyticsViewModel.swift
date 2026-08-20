import Foundation
import HabitKitCore

@Observable
@MainActor
final class AnalyticsViewModel {
    var selectedPeriod: AnalyticsPeriod = .thirtyDays
    var selectedHabitID: UUID?

    /// On-device Apple Intelligence summary of the week, from `HabitCoach`.
    /// Empty until `refreshCoachingSummary` completes.
    var coachingSummary: String = ""
    var isLoadingCoachingSummary = false

    /// CoreML behavior-cluster insight per habit, from `HabitMLManager`.
    /// Populated lazily as `HabitDetailView`/`AnalyticsView` request each habit;
    /// `nil` for a habit means either "not yet predicted" or "model unavailable" —
    /// both render as no insight shown.
    private(set) var clusterInsights: [UUID: HabitCluster] = [:]

    /// Generates a fresh weekly coaching summary from the current habit set.
    /// Safe to call repeatedly (e.g. on every `AnalyticsView` appearance) —
    /// `HabitCoach` reuses its prewarmed session.
    func refreshCoachingSummary(habits: [Habit]) async {
        guard !habits.isEmpty else {
            coachingSummary = ""
            return
        }
        isLoadingCoachingSummary = true
        defer { isLoadingCoachingSummary = false }

        let rates = habits.map { ($0.name, completionRate(for: $0, period: .sevenDays)) }
        let overallRate = Int((rates.map(\.1).reduce(0, +) / Double(rates.count)) * 100)
        let topHabit = rates.max { $0.1 < $1.1 }?.0 ?? habits[0].name
        let missedHabits = rates.filter { $0.1 < 0.5 }.map(\.0)

        coachingSummary = await HabitCoach.shared.weeklyCoachingSummary(
            completionRate: overallRate,
            topHabit: topHabit,
            missedHabits: missedHabits
        )
    }

    /// Predicts and caches the behavior cluster for a single habit.
    func refreshClusterInsight(for habit: Habit) async {
        let rate = completionRate(for: habit, period: .thirtyDays)
        let avgHour = averageCompletionHour(for: habit)
        let streak = StreakCalculator.currentStreak(completions: habit.completions, schedule: habit.schedule)
        clusterInsights[habit.id] = await HabitMLManager.shared.predictCluster(
            completionRate: rate,
            avgCompletionHour: avgHour,
            streakLength: streak
        )
    }

    private func averageCompletionHour(for habit: Habit) -> Double {
        let hours = habit.completions.map { Double(Calendar.current.component(.hour, from: $0.completedAt)) }
        guard !hours.isEmpty else { return 12 }
        return hours.reduce(0, +) / Double(hours.count)
    }

    func completionRate(for habit: Habit, period: AnalyticsPeriod) -> Double {
        let days: Int
        switch period {
        case .sevenDays: days = 7
        case .thirtyDays: days = 30
        case .ninetyDays: days = 90
        }
        let calendar = Calendar.current
        let now = Date()
        let targetDays = (0..<days).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) }
        let completed = targetDays.filter { day in
            habit.completions.contains { calendar.isDate($0.completedAt, inSameDayAs: day) }
        }
        return Double(completed.count) / Double(max(days, 1))
    }

    func correlationPairs(from habits: [Habit]) -> [(correlation: Double, nameA: String, nameB: String)] {
        var pairs: [(Double, String, String)] = []
        for i in 0..<habits.count {
            for j in (i + 1)..<habits.count {
                let r = pearsonCorrelation(habits[i], habits[j])
                if r > 0.2 {
                    pairs.append((r, habits[i].name, habits[j].name))
                }
            }
        }
        return pairs.sorted { $0.0 > $1.0 }
    }

    private func pearsonCorrelation(_ a: Habit, _ b: Habit) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let days = (0..<30).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) }
        let xVals = days.map { day -> Double in
            a.completions.contains { calendar.isDate($0.completedAt, inSameDayAs: day) } ? 1 : 0
        }
        let yVals = days.map { day -> Double in
            b.completions.contains { calendar.isDate($0.completedAt, inSameDayAs: day) } ? 1 : 0
        }
        let n = Double(days.count)
        let xMean = xVals.reduce(0, +) / n
        let yMean = yVals.reduce(0, +) / n
        let num = zip(xVals, yVals).reduce(0.0) { $0 + ($1.0 - xMean) * ($1.1 - yMean) }
        let xVar = xVals.reduce(0.0) { $0 + pow($1 - xMean, 2) }
        let yVar = yVals.reduce(0.0) { $0 + pow($1 - yMean, 2) }
        let denom = sqrt(xVar * yVar)
        guard denom > 0 else { return 0 }
        return num / denom
    }
}
