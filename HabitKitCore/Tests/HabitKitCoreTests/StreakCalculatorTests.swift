import Foundation
import Testing
@testable import HabitKitCore

@Suite("StreakCalculator")
struct StreakCalculatorTests {

    // Helper: build a Habit with completions on specific days-ago offsets
    private func makeHabit(completedDaysAgo offsets: [Int]) -> (Habit, HabitSchedule) {
        let schedule = HabitSchedule(frequency: .daily, reminderTimes: [], habit: nil)
        let habit = Habit(name: "Test", icon: "star", colorHex: "#000000", schedule: schedule)
        schedule.habit = habit
        let calendar = Calendar.current
        for offset in offsets {
            let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let completion = HabitCompletion(completedAt: date, habit: habit)
            habit.completions.append(completion)
        }
        return (habit, schedule)
    }

    @Test("returns 0 for no completions")
    func emptyCompletions() {
        let (habit, schedule) = makeHabit(completedDaysAgo: [])
        #expect(StreakCalculator.currentStreak(completions: habit.completions, schedule: schedule) == 0)
    }

    @Test("returns 1 for completion today only")
    func completedToday() {
        let (habit, schedule) = makeHabit(completedDaysAgo: [0])
        #expect(StreakCalculator.currentStreak(completions: habit.completions, schedule: schedule) == 1)
    }

    @Test("returns consecutive count for streak")
    func consecutiveStreak() {
        let (habit, schedule) = makeHabit(completedDaysAgo: [0, 1, 2, 3])
        #expect(StreakCalculator.currentStreak(completions: habit.completions, schedule: schedule) == 4)
    }

    @Test("streak breaks on missed day")
    func streakBreaksOnMiss() {
        let (habit, schedule) = makeHabit(completedDaysAgo: [0, 1, 3, 4]) // gap at day 2
        #expect(StreakCalculator.currentStreak(completions: habit.completions, schedule: schedule) == 2)
    }

    @Test("longest streak across broken streaks")
    func longestStreakAcrossBrokenStreaks() {
        let (habit, schedule) = makeHabit(completedDaysAgo: [0, 1, 2, 5, 6, 7, 8, 9])
        let longest = StreakCalculator.longestStreak(completions: habit.completions, schedule: schedule)
        #expect(longest == 5)
    }

    @Test("streak break date returns most recent missed due day")
    func streakBreakDate() {
        let (habit, schedule) = makeHabit(completedDaysAgo: [0, 1, 3]) // day 2 missed
        let breakDate = StreakCalculator.streakBreakDate(completions: habit.completions, schedule: schedule)
        #expect(breakDate != nil)
        let expected = Calendar.current.date(byAdding: .day, value: -2, to: Calendar.current.startOfDay(for: Date()))
        #expect(breakDate == expected)
    }
}
