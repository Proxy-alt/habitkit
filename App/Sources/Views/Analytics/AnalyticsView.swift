import SwiftUI
import SwiftData
import HabitNookCore
import HabitNookUI

struct AnalyticsView: View {
    @Environment(NookThemeManager.self) private var themes
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
                        VStack(spacing: NookSpacing.lg) {
                            coachingSection
                            periodPicker
                            overviewSection
                            habitPicker
                            if let habit = selectedHabit ?? activeHabits.first {
                                habitAnalytics(for: habit)
                            }
                            correlationSection
                        }
                        .padding(NookSpacing.md)
                    }
                }
            }
            .navigationTitle("Analytics")
            .task { await viewModel.refreshCoachingSummary(habits: activeHabits) }
        }
    }

    private var coachingSection: some View {
        NookCard {
            VStack(alignment: .leading, spacing: NookSpacing.sm) {
                HStack {
                    Image(systemName: NookSymbol.sparkles)
                        .foregroundStyle(themes.current.primaryColor)
                    Text("Your Week")
                        .font(.nookHeadline)
                        .foregroundStyle(themes.current.textColor)
                }

                if viewModel.isLoadingCoachingSummary {
                    ProgressView()
                        .tint(themes.current.primaryColor)
                } else if !viewModel.coachingSummary.isEmpty {
                    Text(viewModel.coachingSummary)
                        .font(.nookBody)
                        .foregroundStyle(themes.current.textColor)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: NookSpacing.lg) {
            Image(systemName: NookSymbol.chartBarX)
                .font(NookIconSize.xl)
                .foregroundStyle(themes.current.subtextColor)
            Text("No data yet")
                .font(.nookTitle)
                .foregroundStyle(themes.current.textColor)
            Text("Complete some habits to see your analytics.")
                .font(.nookBody)
                .foregroundStyle(themes.current.subtextColor)
                .multilineTextAlignment(.center)
        }
        .padding(NookSpacing.xl)
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
        NookCard {
            VStack(alignment: .leading, spacing: NookSpacing.md) {
                Text("Overview")
                    .font(.nookHeadline)
                    .foregroundStyle(themes.current.textColor)

                HStack(spacing: NookSpacing.md) {
                    ForEach(activeHabits.prefix(4)) { habit in
                        VStack(spacing: NookSpacing.xs) {
                            NookProgressRing(
                                progress: viewModel.completionRate(for: habit, period: viewModel.selectedPeriod),
                                lineWidth: 6,
                                size: 52
                            )
                            Text(habit.name)
                                .font(.nookCaption)
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
            HStack(spacing: NookSpacing.sm) {
                ForEach(activeHabits) { habit in
                    Button {
                        viewModel.selectedHabitID = habit.id
                    } label: {
                        HStack(spacing: NookSpacing.xs) {
                            Image(systemName: habit.icon)
                            Text(habit.name)
                                .font(.nookBody)
                        }
                        .foregroundStyle(
                            (viewModel.selectedHabitID ?? activeHabits.first?.id) == habit.id
                            ? themes.current.baseColor
                            : themes.current.textColor
                        )
                        .padding(.horizontal, NookSpacing.md)
                        .padding(.vertical, NookSpacing.sm)
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
        VStack(spacing: NookSpacing.md) {
            NookCard {
                VStack(alignment: .leading, spacing: NookSpacing.sm) {
                    HStack {
                        Image(systemName: habit.icon)
                            .foregroundStyle(themes.current.primaryColor)
                        Text(habit.name)
                            .font(.nookHeadline)
                            .foregroundStyle(themes.current.textColor)
                    }

                    HStack(spacing: NookSpacing.lg) {
                        VStack {
                            Text("\(StreakCalculator.currentStreak(completions: habit.completions, schedule: habit.schedule))")
                                .font(.nookLargeTitle)
                                .foregroundStyle(themes.current.warningColor)
                            Text("Current Streak")
                                .font(.nookCaption)
                                .foregroundStyle(themes.current.subtextColor)
                        }
                        VStack {
                            Text("\(StreakCalculator.longestStreak(completions: habit.completions, schedule: habit.schedule))")
                                .font(.nookLargeTitle)
                                .foregroundStyle(themes.current.primaryColor)
                            Text("Best Streak")
                                .font(.nookCaption)
                                .foregroundStyle(themes.current.subtextColor)
                        }
                        VStack {
                            Text("\(Int(viewModel.completionRate(for: habit, period: viewModel.selectedPeriod) * 100))%")
                                .font(.nookLargeTitle)
                                .foregroundStyle(themes.current.successColor)
                            Text("Rate")
                                .font(.nookCaption)
                                .foregroundStyle(themes.current.subtextColor)
                        }
                    }
                }
            }

            NookCard {
                VStack(alignment: .leading, spacing: NookSpacing.sm) {
                    Text("Activity Heatmap")
                        .font(.nookHeadline)
                        .foregroundStyle(themes.current.textColor)
                    HeatmapView(habit: habit)
                }
            }

            if let insight = viewModel.clusterInsights[habit.id] {
                NookCard {
                    HStack(alignment: .top, spacing: NookSpacing.sm) {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(themes.current.primaryColor)
                        Text(insight.insightText)
                            .font(.nookBody)
                            .foregroundStyle(themes.current.textColor)
                    }
                }
            }
        }
        .task(id: habit.id) { await viewModel.refreshClusterInsight(for: habit) }
    }

    private var correlationSection: some View {
        Group {
            if activeHabits.count >= 2 {
                NookCard {
                    VStack(alignment: .leading, spacing: NookSpacing.sm) {
                        Text("Habit Correlations")
                            .font(.nookHeadline)
                            .foregroundStyle(themes.current.textColor)
                        Text("Pairs that tend to be completed together (last 30 days)")
                            .font(.nookCaption)
                            .foregroundStyle(themes.current.subtextColor)

                        ForEach(viewModel.correlationPairs(from: activeHabits).prefix(5), id: \.nameA) { pair in
                            HStack {
                                Text("\(pair.nameA) & \(pair.nameB)")
                                    .font(.nookBody)
                                    .foregroundStyle(themes.current.textColor)
                                Spacer()
                                Text(String(format: "%.0f%%", pair.correlation * 100))
                                    .font(.nookMono)
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
