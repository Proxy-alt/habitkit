import SwiftUI
import SwiftData
import HabitKitCore
import HabitKitUI

struct AnalyticsView: View {
    @Environment(HKThemeManager.self) private var themes
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var viewModel = AnalyticsViewModel()

    private var activeHabits: [Habit] { habits.filter { !$0.isArchived } }

    private var selectedHabit: Habit? {
        if let id = viewModel.selectedHabitID {
            return activeHabits.first { $0.id == id }
        }
        return nil
    }

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
            Image(systemName: HKSymbol.chartBarX)
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
        Picker("Period", selection: $viewModel.selectedPeriod) {
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
                                progress: viewModel.completionRate(for: habit, period: viewModel.selectedPeriod),
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
                        viewModel.selectedHabitID = habit.id
                    } label: {
                        HStack(spacing: HKSpacing.xs) {
                            Image(systemName: habit.icon)
                            Text(habit.name)
                                .font(.hkBody)
                        }
                        .foregroundStyle(
                            (viewModel.selectedHabitID ?? activeHabits.first?.id) == habit.id
                            ? themes.current.baseColor
                            : themes.current.textColor
                        )
                        .padding(.horizontal, HKSpacing.md)
                        .padding(.vertical, HKSpacing.sm)
                        .background(
                            (viewModel.selectedHabitID ?? activeHabits.first?.id) == habit.id
                            ? themes.current.primaryColor
                            : themes.current.surface1Color,
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View analytics for \(habit.name)")
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
                            Text("\(Int(viewModel.completionRate(for: habit, period: viewModel.selectedPeriod) * 100))%")
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

                        ForEach(viewModel.correlationPairs(from: activeHabits).prefix(5), id: \.nameA) { pair in
                            HStack {
                                Text("\(pair.nameA) & \(pair.nameB)")
                                    .font(.hkBody)
                                    .foregroundStyle(themes.current.textColor)
                                Spacer()
                                Text(String(format: "%.0f%%", pair.correlation * 100))
                                    .font(.hkMono)
                                    .foregroundStyle(correlationColor(pair.correlation))
                            }
                        }
                    }
                }
            }
        }
    }

    private func correlationColor(_ r: Double) -> Color {
        if r > 0.6 { return themes.current.successColor }
        if r > 0.3 { return themes.current.warningColor }
        return themes.current.subtextColor
    }
}
