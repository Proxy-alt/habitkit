import SwiftUI
import SwiftData
import HabitKitCore
import HabitKitUI

struct HabitRow: View {
    @Environment(HKThemeManager.self) private var themes
    @Environment(\.modelContext) private var modelContext
    @Environment(AppNavigator.self) private var navigator
    let habit: Habit
    var muted: Bool = false

    private var isCompletedToday: Bool {
        habit.completions.contains { Calendar.current.isDateInToday($0.completedAt) }
    }

    var body: some View {
        HStack(spacing: HKSpacing.md) {
            HKCompletionBadge(isCompleted: isCompletedToday) {
                toggleCompletion()
            }
            .accessibilityLabel(isCompletedToday ? "Mark \(habit.name) incomplete" : "Mark \(habit.name) complete")

            Image(systemName: habit.icon)
                .font(.hkHeadline)
                .foregroundStyle(accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.hkHeadline)
                    .foregroundStyle(muted ? themes.current.subtextColor : themes.current.textColor)
                    .strikethrough(muted)

                streakLabel
            }

            Spacer()

            if let timedHabit = habit as? TimedHabit {
                Button {
                    navigator.startTimer(for: timedHabit)
                } label: {
                    Image(systemName: HKSymbol.play)
                        .font(.title2)
                        .foregroundStyle(themes.current.primaryColor)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Start \(habit.name) timer")
            }
        }
        .padding(.vertical, HKSpacing.xs)
    }

    private var streakLabel: some View {
        let streak = currentStreak
        if streak > 0 {
            return AnyView(
                HStack(spacing: 2) {
                    Image(systemName: HKSymbol.flame)
                        .font(.hkCaption)
                        .foregroundStyle(themes.current.warningColor)
                    Text("\(streak) day streak")
                        .font(.hkCaption)
                        .foregroundStyle(themes.current.subtextColor)
                }
            )
        }
        return AnyView(EmptyView())
    }

    private var currentStreak: Int {
        StreakCalculator.currentStreak(completions: habit.completions, schedule: habit.schedule)
    }

    private var accentColor: Color {
        if habit.colorHex.isEmpty {
            return themes.current.primaryColor
        }
        return Color(hex: habit.colorHex) ?? themes.current.primaryColor
    }

    private func toggleCompletion() {
        if isCompletedToday {
            if let completion = habit.completions.first(where: { Calendar.current.isDateInToday($0.completedAt) }) {
                modelContext.delete(completion)
            }
        } else {
            let completion = HabitCompletion(completedAt: Date(), habit: habit)
            modelContext.insert(completion)
        }
    }
}
