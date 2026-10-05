import SwiftUI
import SwiftData
import HabitNookCore
import HabitNookUI
import NookCore
import NookUI

struct AnalyticsView: View {
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
                Rectangle().fill(.nook(.base)).ignoresSafeArea()

                if activeHabits.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: NookSpacing.lg.value) {
                            coachingSection
                            periodPicker
                            overviewSection
                            habitPicker
                            if let habit = selectedHabit ?? activeHabits.first {
                                habitAnalytics(for: habit)
                            }
                            correlationSection
                        }
                        .padding(.md)
                    }
                }
            }
            .navigationTitle("Analytics")
            .task { await viewModel.refreshCoachingSummary(habits: activeHabits) }
        }
    }

    private var coachingSection: some View {
        NookCard {
            VStack(alignment: .leading, spacing: NookSpacing.sm.value) {
                HStack {
                    Image(nookSymbol: .sparkles)
                        .foregroundStyle(.nook(.primary))
                    Text("Your Week")
                        .font(.nook(.headline))
                        .foregroundStyle(.nook(.text))
                }

                if viewModel.isLoadingCoachingSummary {
                    ProgressView()
                        .tint(NookColourStyle(.primary))
                } else if !viewModel.coachingSummary.isEmpty {
                    Text(viewModel.coachingSummary)
                        .font(.nook(.body))
                        .foregroundStyle(.nook(.text))
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: NookSpacing.lg.value) {
            Image(nookSymbol: .chartBarX)
                .nookIconSize(.xl)
                .foregroundStyle(.nook(.subtext))
            Text("No data yet")
                .font(.nook(.title))
                .foregroundStyle(.nook(.text))
            Text("Complete some habits to see your analytics.")
                .font(.nook(.body))
                .foregroundStyle(.nook(.subtext))
                .multilineTextAlignment(.center)
        }
        .padding(.xl)
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
            VStack(alignment: .leading, spacing: NookSpacing.md.value) {
                Text("Overview")
                    .font(.nook(.headline))
                    .foregroundStyle(.nook(.text))

                HStack(spacing: NookSpacing.md.value) {
                    ForEach(activeHabits.prefix(4)) { habit in
                        VStack(spacing: NookSpacing.xs.value) {
                            NookProgressRing(
                                progress: viewModel.completionRate(for: habit, period: viewModel.selectedPeriod),
                                lineWidth: 6,
                                size: 52
                            )
                            Text(habit.name)
                                .font(.nook(.caption))
                                .foregroundStyle(.nook(.subtext))
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
            HStack(spacing: NookSpacing.sm.value) {
                ForEach(activeHabits) { habit in
                    Button {
                        viewModel.selectedHabitID = habit.id
                    } label: {
                        HStack(spacing: NookSpacing.xs.value) {
                            Image(systemName: habit.icon)
                            Text(habit.name)
                                .font(.nook(.body))
                        }
                        .foregroundStyle(
                            (viewModel.selectedHabitID ?? activeHabits.first?.id) == habit.id
                            ? .nook(.base)
                            : .nook(.text)
                        )
                        .padding(.horizontal, .md)
                        .padding(.vertical, .sm)
                        .background(
                            (viewModel.selectedHabitID ?? activeHabits.first?.id) == habit.id
                            ? .nook(.primary)
                            : .nook(.surface1),
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
        VStack(spacing: NookSpacing.md.value) {
            NookCard {
                VStack(alignment: .leading, spacing: NookSpacing.sm.value) {
                    HStack {
                        Image(systemName: habit.icon)
                            .foregroundStyle(.nook(.primary))
                        Text(habit.name)
                            .font(.nook(.headline))
                            .foregroundStyle(.nook(.text))
                    }

                    HStack(spacing: NookSpacing.lg.value) {
                        VStack {
                            Text("\(StreakCalculator.currentStreak(completions: habit.completions, schedule: habit.schedule))")
                                .font(.nook(.largeTitle))
                                .foregroundStyle(.nook(.warning))
                            Text("Current Streak")
                                .font(.nook(.caption))
                                .foregroundStyle(.nook(.subtext))
                        }
                        VStack {
                            Text("\(StreakCalculator.longestStreak(completions: habit.completions, schedule: habit.schedule))")
                                .font(.nook(.largeTitle))
                                .foregroundStyle(.nook(.primary))
                            Text("Best Streak")
                                .font(.nook(.caption))
                                .foregroundStyle(.nook(.subtext))
                        }
                        VStack {
                            Text("\(Int(viewModel.completionRate(for: habit, period: viewModel.selectedPeriod) * 100))%")
                                .font(.nook(.largeTitle))
                                .foregroundStyle(.nook(.success))
                            Text("Rate")
                                .font(.nook(.caption))
                                .foregroundStyle(.nook(.subtext))
                        }
                    }
                }
            }

            NookCard {
                VStack(alignment: .leading, spacing: NookSpacing.sm.value) {
                    Text("Activity Heatmap")
                        .font(.nook(.headline))
                        .foregroundStyle(.nook(.text))
                    HeatmapView(habit: habit)
                }
            }

            if let insight = viewModel.clusterInsights[habit.id] {
                NookCard {
                    HStack(alignment: .top, spacing: NookSpacing.sm.value) {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.nook(.primary))
                        Text(insight.insightText)
                            .font(.nook(.body))
                            .foregroundStyle(.nook(.text))
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
                    VStack(alignment: .leading, spacing: NookSpacing.sm.value) {
                        Text("Habit Correlations")
                            .font(.nook(.headline))
                            .foregroundStyle(.nook(.text))
                        Text("Pairs that tend to be completed together (last 30 days)")
                            .font(.nook(.caption))
                            .foregroundStyle(.nook(.subtext))

                        ForEach(viewModel.correlationPairs(from: activeHabits).prefix(5), id: \.nameA) { pair in
                            HStack {
                                Text("\(pair.nameA) & \(pair.nameB)")
                                    .font(.nook(.body))
                                    .foregroundStyle(.nook(.text))
                                Spacer()
                                Text(String(format: "%.0f%%", pair.correlation * 100))
                                    .font(.nook(.mono))
                                    .foregroundStyle(.nook(correlationRole(pair.correlation)))
                            }
                        }
                    }
                }
            }
        }
    }

    private func correlationRole(_ r: Double) -> NookColour {
        if r > 0.6 { return .success }
        if r > 0.3 { return .warning }
        return .subtext
    }
}
