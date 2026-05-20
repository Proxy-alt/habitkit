import Foundation
import SwiftData
import Testing
@testable import HabitKitCore

@MainActor
@Suite("StreakCalculator")
struct StreakCalculatorTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Habit.self, HabitCompletion.self, HabitSchedule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeHabit(completedDaysAgo offsets: [Int], in context: ModelContext) -> (Habit, HabitSchedule) {
        let schedule = HabitSchedule(frequency: .daily, reminderTimes: [], habit: nil)
        context.insert(schedule)
        let habit = Habit(name: "Test", icon: "star", colorHex: "#000000", schedule: schedule)
        schedule.habit = habit
        context.insert(habit)
        let calendar = Calendar.current
        for offset in offsets {
            let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let completion = HabitCompletion(completedAt: date, habit: habit)
            context.insert(completion)
            habit.completions.append(completion)
        }
        return (habit, schedule)
    }

    @Test("returns 0 for no completions")
    func emptyCompletions() throws {
        let context = ModelContext(try makeContainer())
        let (habit, schedule) = makeHabit(completedDaysAgo: [], in: context)
        #expect(StreakCalculator.currentStreak(completions: habit.completions, schedule: schedule) == 0)
    }

    @Test("returns 1 for completion today only")
    func completedToday() throws {
        let context = ModelContext(try makeContainer())
        let (habit, schedule) = makeHabit(completedDaysAgo: [0], in: context)
        #expect(StreakCalculator.currentStreak(completions: habit.completions, schedule: schedule) == 1)
    }

    @Test("returns consecutive count for streak")
    func consecutiveStreak() throws {
        let context = ModelContext(try makeContainer())
        let (habit, schedule) = makeHabit(completedDaysAgo: [0, 1, 2, 3], in: context)
        #expect(StreakCalculator.currentStreak(completions: habit.completions, schedule: schedule) == 4)
    }

    @Test("streak breaks on missed day")
    func streakBreaksOnMiss() throws {
        let context = ModelContext(try makeContainer())
        let (habit, schedule) = makeHabit(completedDaysAgo: [0, 1, 3, 4], in: context)
        #expect(StreakCalculator.currentStreak(completions: habit.completions, schedule: schedule) == 2)
    }

    @Test("longest streak across broken streaks")
    func longestStreakAcrossBrokenStreaks() throws {
        let context = ModelContext(try makeContainer())
        let (habit, schedule) = makeHabit(completedDaysAgo: [0, 1, 2, 5, 6, 7, 8, 9], in: context)
        let longest = StreakCalculator.longestStreak(completions: habit.completions, schedule: schedule)
        #expect(longest == 5)
    }

    @Test("streak break date returns most recent missed due day")
    func streakBreakDate() throws {
        let context = ModelContext(try makeContainer())
        let (habit, schedule) = makeHabit(completedDaysAgo: [0, 1, 3], in: context)
        let breakDate = StreakCalculator.streakBreakDate(completions: habit.completions, schedule: schedule)
        #expect(breakDate != nil)
        let expected = Calendar.current.date(
            byAdding: .day,
            value: -2,
            to: Calendar.current.startOfDay(for: Date())
        )
        #expect(breakDate == expected)
    }
}
