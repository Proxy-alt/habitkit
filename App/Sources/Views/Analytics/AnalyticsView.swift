import SwiftUI
import SwiftData
import HabitKitCore
import HabitKitUI

struct AnalyticsView: View {
    @Environment(HKThemeManager.self) private var themes
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var selectedHabit: Habit?
    @State private var selectedPeriod: AnalyticsPeriod = .thirtyDays

    private var activeHabits: [Habit] { habits.filter { !$0.isArchived } }

    var body: some View {
        NavigationStack {
            ZStack {
                themes.current.baseColor.ignoresSafeArea()

                if activeHabits.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: HKSpacing.lg) {
                            periodPicker
                            overviewSection
                            habitPicker
                            if let habit = selectedHabit ?? activeHabits.first {
                                habitAnalytics(for: habit)
                            }
                            correlationSection
                        }
                        .padding(HKSpacing.md)
                    }
                }
            }
            .navigationTitle("Analytics")
        }
    }

    private var emptyState: some View {
        VStack(spacing: HKSpacing.lg) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundStyle(themes.current.subtextColor)
            Text("No data yet")
                .font(.hkTitle)
                .foregroundStyle(themes.current.textColor)
            Text("Complete some habits to see your analytics.")
                .font(.hkBody)
                .foregroundStyle(themes.current.subtextColor)
                .multilineTextAlignment(.center)
        }
        .padding(HKSpacing.xl)
    }

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            Text("7 Days").tag(AnalyticsPeriod.sevenDays)
            Text("30 Days").tag(AnalyticsPeriod.thirtyDays)
            Text("90 Days").tag(AnalyticsPeriod.ninetyDays)
        }
        .pickerStyle(.segmented)
    }

    private var overviewSection: some View {
        HKCard {
            VStack(alignment: .leading, spacing: HKSpacing.md) {
                Text("Overview")
                    .font(.hkHeadline)
                    .foregroundStyle(themes.current.textColor)

                HStack(spacing: HKSpacing.md) {
                    ForEach(activeHabits.prefix(4)) { habit in
                        VStack(spacing: HKSpacing.xs) {
                            HKProgressRing(
                                progress: completionRate(for: habit),
                                lineWidth: 6,
                                size: 52
                            )
                            Text(habit.name)
                                .font(.hkCaption)
                                .foregroundStyle(themes.current.subtextColor)
                                .lineLimit(1)
                                .frame(width: 60)
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    private var habitPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HKSpacing.sm) {
                ForEach(activeHabits) { habit in
                    Button {
                        selectedHabit = habit
                    } label: {
                        HStack(spacing: HKSpacing.xs) {
                            Image(systemName: habit.icon)
                            Text(habit.name)
                                .font(.hkBody)
                        }
                        .foregroundStyle(
                            (selectedHabit?.id ?? activeHabits.first?.id) == habit.id
                            ? themes.current.baseColor
                            : themes.current.textColor
                        )
                        .padding(.horizontal, HKSpacing.md)
                        .padding(.vertical, HKSpacing.sm)
                        .background(
                            (selectedHabit?.id ?? activeHabits.first?.id) == habit.id
                            ? themes.current.primaryColor
                            : themes.current.surface1Color,
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func habitAnalytics(for habit: Habit) -> some View {
        VStack(spacing: HKSpacing.md) {
            HKCard {
                VStack(alignment: .leading, spacing: HKSpacing.sm) {
                    HStack {
                        Image(systemName: habit.icon)
                            .foregroundStyle(themes.current.primaryColor)
                        Text(habit.name)
                            .font(.hkHeadline)
                            .foregroundStyle(themes.current.textColor)
                    }

                    HStack(spacing: HKSpacing.lg) {
                        VStack {
                            Text("\(StreakCalculator.currentStreak(completions: habit.completions, schedule: habit.schedule))")
                                .font(.hkLargeTitle)
                                .foregroundStyle(themes.current.warningColor)
                            Text("Current Streak")
                                .font(.hkCaption)
                                .foregroundStyle(themes.current.subtextColor)
                        }
                        VStack {
                            Text("\(StreakCalculator.longestStreak(completions: habit.completions, schedule: habit.schedule))")
                                .font(.hkLargeTitle)
                                .foregroundStyle(themes.current.primaryColor)
                            Text("Best Streak")
                                .font(.hkCaption)
                                .foregroundStyle(themes.current.subtextColor)
                        }
                        VStack {
                            Text("\(Int(completionRate(for: habit) * 100))%")
                                .font(.hkLargeTitle)
                                .foregroundStyle(themes.current.successColor)
                            Text("Rate")
                                .font(.hkCaption)
                                .foregroundStyle(themes.current.subtextColor)
                        }
                    }
                }
            }

            HKCard {
                VStack(alignment: .leading, spacing: HKSpacing.sm) {
                    Text("Activity Heatmap")
                        .font(.hkHeadline)
                        .foregroundStyle(themes.current.textColor)
                    HeatmapView(habit: habit)
                }
            }
        }
    }

    private var correlationSection: some View {
        Group {
            if activeHabits.count >= 2 {
                HKCard {
                    VStack(alignment: .leading, spacing: HKSpacing.sm) {
                        Text("Habit Correlations")
                            .font(.hkHeadline)
                            .foregroundStyle(themes.current.textColor)
                        Text("Pairs that tend to be completed together (last 30 days)")
                            .font(.hkCaption)
                            .foregroundStyle(themes.current.subtextColor)

                        ForEach(correlationPairs.prefix(5), id: \.0) { pair in
                            HStack {
                                Text("\(pair.1) & \(pair.2)")
                                    .font(.hkBody)
                                    .foregroundStyle(themes.current.textColor)
                                Spacer()
                                Text(String(format: "%.0f%%", pair.0 * 100))
                                    .font(.hkMono)
                                    .foregroundStyle(correlationColor(pair.0))
                            }
                        }
                    }
                }
            }
        }
    }

    private func completionRate(for habit: Habit) -> Double {
        let days: Int
        switch selectedPeriod {
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

    private var correlationPairs: [(Double, String, String)] {
        var pairs: [(Double, String, String)] = []
        let h = activeHabits
        for i in 0..<h.count {
            for j in (i + 1)..<h.count {
                let r = pearsonCorrelation(h[i], h[j])
                if r > 0.2 {
                    pairs.append((r, h[i].name, h[j].name))
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
            a.completions.contains { calendar.isDate($0.completedAt, inSameDayAs: day) } ? 1.0 : 0.0
        }
        let yVals = days.map { day -> Double in
            b.completions.contains { calendar.isDate($0.completedAt, inSameDayAs: day) } ? 1.0 : 0.0
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

    private func correlationColor(_ r: Double) -> Color {
        if r > 0.6 { return themes.current.successColor }
        if r > 0.3 { return themes.current.warningColor }
        return themes.current.subtextColor
    }
}
