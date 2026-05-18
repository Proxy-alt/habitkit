import SwiftUI
import SwiftData
import HabitKitCore
import HabitKitUI

struct HabitDetailView: View {
    @Environment(HKThemeManager.self) private var themes
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var habit: Habit
    @State private var showDeleteConfirm = false

    private var completionRate30Days: Double {
        let calendar = Calendar.current
        let now = Date()
        let days30 = (0..<30).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) }
        let completedDays = days30.filter { day in
            habit.completions.contains { calendar.isDate($0.completedAt, inSameDayAs: day) }
        }
        return Double(completedDays.count) / 30.0
    }

    private var currentStreak: Int {
        StreakCalculator.currentStreak(completions: habit.completions, schedule: habit.schedule)
    }

    private var longestStreak: Int {
        StreakCalculator.longestStreak(completions: habit.completions, schedule: habit.schedule)
    }

    var body: some View {
        ZStack {
            themes.current.baseColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: HKSpacing.lg) {
                    headerCard
                    statsRow
                    heatmapSection
                    recentCompletions
                    dangerZone
                }
                .padding(HKSpacing.md)
            }
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Delete \(habit.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Habit", role: .destructive) {
                modelContext.delete(habit)
                dismiss()
            }
            Button("Archive Instead") {
                habit.isArchived = true
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerCard: some View {
        HKCard {
            HStack(spacing: HKSpacing.md) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 64, height: 64)
                    Image(systemName: habit.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: HKSpacing.xs) {
                    Text(habit.name)
                        .font(.hkTitle)
                        .foregroundStyle(themes.current.textColor)
                    Text(habitTypeLabel)
                        .font(.hkCaption)
                        .foregroundStyle(themes.current.subtextColor)
                }

                Spacer()

                HKProgressRing(progress: completionRate30Days, size: 52)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: HKSpacing.md) {
            statCell(value: "\(currentStreak)", label: "Current Streak", icon: HKSymbol.flame, color: themes.current.warningColor)
            statCell(value: "\(longestStreak)", label: "Longest Streak", icon: HKSymbol.trophy, color: themes.current.primaryColor)
            statCell(value: "\(Int(completionRate30Days * 100))%", label: "30-Day Rate", icon: HKSymbol.chartBar, color: themes.current.successColor)
        }
    }

    private func statCell(value: String, label: String, icon: String, color: Color) -> some View {
        HKCard {
            VStack(spacing: HKSpacing.xs) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(value)
                    .font(.hkTitle)
                    .foregroundStyle(themes.current.textColor)
                Text(label)
                    .font(.hkCaption)
                    .foregroundStyle(themes.current.subtextColor)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var heatmapSection: some View {
        HKCard {
            VStack(alignment: .leading, spacing: HKSpacing.sm) {
                Text("Activity")
                    .font(.hkHeadline)
                    .foregroundStyle(themes.current.textColor)
                HeatmapView(habit: habit)
            }
        }
    }

    private var recentCompletions: some View {
        let recent = habit.completions
            .sorted { $0.completedAt > $1.completedAt }
            .prefix(10)

        return HKCard {
            VStack(alignment: .leading, spacing: HKSpacing.sm) {
                Text("Recent Completions")
                    .font(.hkHeadline)
                    .foregroundStyle(themes.current.textColor)

                if recent.isEmpty {
                    Text("No completions yet.")
                        .font(.hkBody)
                        .foregroundStyle(themes.current.subtextColor)
                } else {
                    ForEach(Array(recent)) { completion in
                        CompletionRow(completion: completion)
                    }
                }
            }
        }
    }

    private var dangerZone: some View {
        VStack(spacing: HKSpacing.sm) {
            HKButton("Archive Habit", variant: .secondary) {
                habit.isArchived = true
                dismiss()
            }
            HKButton("Delete Habit", variant: .danger) {
                showDeleteConfirm = true
            }
        }
    }

    private var accentColor: Color {
        Color(hex: habit.colorHex) ?? themes.current.primaryColor
    }

    private var habitTypeLabel: String {
        switch habit {
        case is TimedHabit: return "Timed Habit"
        case is QuantityHabit: return "Quantity Habit"
        case is ChecklistHabit: return "Checklist Habit"
        case is NegativeHabit: return "Avoidance Habit"
        default: return "Habit"
        }
    }
}

private struct CompletionRow: View {
    @Environment(HKThemeManager.self) private var themes
    let completion: HabitCompletion

    var body: some View {
        HStack {
            Image(systemName: HKSymbol.checkmark)
                .foregroundStyle(themes.current.successColor)

            Text(completion.completedAt, style: .date)
                .font(.hkBody)
                .foregroundStyle(themes.current.textColor)

            Spacer()

            Text(completion.completedAt, style: .time)
                .font(.hkCaption)
                .foregroundStyle(themes.current.subtextColor)
        }
        .padding(.vertical, 2)
    }
}
