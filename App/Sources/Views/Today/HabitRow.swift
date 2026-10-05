import SwiftUI
import SwiftData
import HabitNookCore
import HabitNookUI
import NookCore
import NookUI

struct HabitRow: View {
    @Environment(\.nookTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppNavigator.self) private var navigator
    let habit: Habit
    var muted: Bool = false

    private var isCompletedToday: Bool {
        habit.completions.contains { Calendar.current.isDateInToday($0.completedAt) }
    }

    var body: some View {
        HStack(spacing: NookSpacing.md.value) {
            NookCompletionBadge(isCompleted: isCompletedToday) {
                toggleCompletion()
            }
            .accessibilityLabel(isCompletedToday ? "Mark \(habit.name) incomplete" : "Mark \(habit.name) complete")

            Image(systemName: habit.icon)
                .font(.nook(.headline))
                .foregroundStyle(accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.nook(.headline))
                    .foregroundStyle(muted ? .nook(.subtext) : .nook(.text))
                    .strikethrough(muted)

                streakLabel
            }

            Spacer()

            if let timedHabit = habit as? TimedHabit {
                Button {
                    navigator.startTimer(for: timedHabit)
                } label: {
                    Image(nookSymbol: .play)
                        .font(.title2)
                        .foregroundStyle(.nook(.primary))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Start \(habit.name) timer")
            }
        }
        .padding(.vertical, .xs)
    }

    private var streakLabel: some View {
        let streak = currentStreak
        if streak > 0 {
            return AnyView(
                HStack(spacing: 2) {
                    Image(nookSymbol: .flame)
                        .font(.nook(.caption))
                        .foregroundStyle(.nook(.warning))
                    Text("\(streak) day streak")
                        .font(.nook(.caption))
                        .foregroundStyle(.nook(.subtext))
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
            return theme.color(.primary)
        }
        return Color(hex: habit.colorHex) ?? theme.color(.primary)
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
