import Foundation
import SwiftData
import Testing
@testable import HabitKitCore

@MainActor
@Suite("AnalyticsEngine")
struct AnalyticsEngineTests {

    private let analytics = AnalyticsEngine()

    private func makeContext() throws -> ModelContext {
        ModelContext(try ModelContainerConfiguration.makeInMemoryContainer())
    }

    private func makeHabit(in context: ModelContext, completedDaysAgo offsets: [Int] = []) -> Habit {
        let schedule = HabitSchedule(frequency: .daily)
        context.insert(schedule)
        let habit = Habit(name: "Test", icon: "star", colorHex: "#000", schedule: schedule)
        schedule.habit = habit
        context.insert(habit)
        let calendar = Calendar.current
        for offset in offsets {
            let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let c = HabitCompletion(completedAt: date, habit: habit)
            context.insert(c)
            habit.completions.append(c)
        }
        return habit
    }

    // MARK: - completionRate

    @Test("completionRate returns 0 when no completions")
    func completionRateEmpty() throws {
        let ctx = try makeContext()
        let habit = makeHabit(in: ctx)
        #expect(analytics.completionRate(for: habit, over: .sevenDays) == 0)
        #expect(analytics.completionRate(for: habit, over: .thirtyDays) == 0)
        #expect(analytics.completionRate(for: habit, over: .ninetyDays) == 0)
    }

    @Test("completionRate returns 1 when completed every day in period")
    func completionRateFull() throws {
        let ctx = try makeContext()
        let habit = makeHabit(in: ctx, completedDaysAgo: Array(0...6))
        let rate = analytics.completionRate(for: habit, over: .sevenDays)
        #expect(rate == 1.0)
    }

    @Test("completionRate is partial when some days missed")
    func completionRatePartial() throws {
        let ctx = try makeContext()
        // Complete only 4 of 7 days
        let habit = makeHabit(in: ctx, completedDaysAgo: [0, 1, 2, 3])
        let rate = analytics.completionRate(for: habit, over: .sevenDays)
        #expect(rate == 4.0 / 7.0)
    }

    @Test("completionRate ignores completions outside window")
    func completionRateOutsideWindow() throws {
        let ctx = try makeContext()
        // Completed 100 days ago — outside 30-day window
        let habit = makeHabit(in: ctx, completedDaysAgo: [100])
        let rate = analytics.completionRate(for: habit, over: .thirtyDays)
        #expect(rate == 0)
    }

    @Test("AnalyticsPeriod days are correct")
    func analyticsPeriodDays() {
        #expect(AnalyticsPeriod.sevenDays.days == 7)
        #expect(AnalyticsPeriod.thirtyDays.days == 30)
        #expect(AnalyticsPeriod.ninetyDays.days == 90)
    }

    // MARK: - bestTimeOfDay

    @Test("bestTimeOfDay returns nil with no completions")
    func bestTimeOfDayEmpty() throws {
        let ctx = try makeContext()
        let habit = makeHabit(in: ctx)
        #expect(analytics.bestTimeOfDay(for: habit) == nil)
    }

    @Test("bestTimeOfDay returns the only hour when one completion")
    func bestTimeOfDaySingle() throws {
        let ctx = try makeContext()
        let schedule = HabitSchedule(frequency: .daily)
        ctx.insert(schedule)
        let habit = Habit(name: "Test", icon: "star", colorHex: "#000", schedule: schedule)
        schedule.habit = habit
        ctx.insert(habit)

        var comps = DateComponents()
        comps.year = 2024; comps.month = 1; comps.day = 1
        comps.hour = 9; comps.minute = 30
        let date = Calendar.current.date(from: comps)!
        let c = HabitCompletion(completedAt: date, habit: habit)
        ctx.insert(c)
        habit.completions.append(c)

        let best = analytics.bestTimeOfDay(for: habit)
        #expect(best?.hour == 9)
        #expect(best?.minute == 30)
    }

    @Test("bestTimeOfDay returns most frequent hour-minute pair")
    func bestTimeOfDayMostFrequent() throws {
        let ctx = try makeContext()
        let schedule = HabitSchedule(frequency: .daily)
        ctx.insert(schedule)
        let habit = Habit(name: "Test", icon: "star", colorHex: "#000", schedule: schedule)
        schedule.habit = habit
        ctx.insert(habit)

        let calendar = Calendar.current
        // 7am twice, 9am once — 7am should win
        for hour in [7, 7, 9] {
            var comps = DateComponents()
            comps.year = 2024; comps.month = 1; comps.day = 1
            comps.hour = hour; comps.minute = 0
            let date = calendar.date(from: comps)!
            let c = HabitCompletion(completedAt: date, habit: habit)
            ctx.insert(c)
            habit.completions.append(c)
        }

        let best = analytics.bestTimeOfDay(for: habit)
        #expect(best?.hour == 7)
    }

    // MARK: - correlationCoefficient

    @Test("correlationCoefficient is 1 for identical habits")
    func correlationIdentical() throws {
        let ctx = try makeContext()
        let habitA = makeHabit(in: ctx, completedDaysAgo: [0, 1, 2, 5, 6])
        let habitB = makeHabit(in: ctx, completedDaysAgo: [0, 1, 2, 5, 6])
        let r = analytics.correlationCoefficient(between: habitA, and: habitB)
        #expect(abs(r - 1.0) < 0.001)
    }

    @Test("correlationCoefficient is 0 when one habit has no variance")
    func correlationNoVariance() throws {
        let ctx = try makeContext()
        // habitA completed every day → no variance
        let allDays = Array(0...29)
        let habitA = makeHabit(in: ctx, completedDaysAgo: allDays)
        let habitB = makeHabit(in: ctx, completedDaysAgo: [0, 5, 10])
        let r = analytics.correlationCoefficient(between: habitA, and: habitB)
        #expect(r == 0)
    }

    @Test("correlationCoefficient is negative for opposite habits")
    func correlationOpposite() throws {
        let ctx = try makeContext()
        // habitA: even offsets, habitB: odd offsets
        let habitA = makeHabit(in: ctx, completedDaysAgo: stride(from: 0, through: 28, by: 2).map { $0 })
        let habitB = makeHabit(in: ctx, completedDaysAgo: stride(from: 1, through: 29, by: 2).map { $0 })
        let r = analytics.correlationCoefficient(between: habitA, and: habitB)
        #expect(r < 0)
    }

    // MARK: - heatmapData

    @Test("heatmapData returns empty for no completions")
    func heatmapEmpty() throws {
        let ctx = try makeContext()
        let habit = makeHabit(in: ctx)
        let data = analytics.heatmapData(for: habit, in: .current)
        #expect(data.isEmpty)
    }

    @Test("heatmapData counts completions per day")
    func heatmapCounts() throws {
        let ctx = try makeContext()
        let schedule = HabitSchedule(frequency: .daily)
        ctx.insert(schedule)
        let habit = Habit(name: "Test", icon: "star", colorHex: "#000", schedule: schedule)
        schedule.habit = habit
        ctx.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // 2 completions today, 1 yesterday
        for _ in 0..<2 {
            let c = HabitCompletion(completedAt: Date(), habit: habit)
            ctx.insert(c)
            habit.completions.append(c)
        }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let c = HabitCompletion(completedAt: yesterday.addingTimeInterval(3600), habit: habit)
        ctx.insert(c)
        habit.completions.append(c)

        let data = analytics.heatmapData(for: habit, in: calendar)
        #expect(data[today] == 2)
        #expect(data[yesterday] == 1)
    }

    @Test("heatmapData ignores completions older than 365 days")
    func heatmapIgnoresOld() throws {
        let ctx = try makeContext()
        let schedule = HabitSchedule(frequency: .daily)
        ctx.insert(schedule)
        let habit = Habit(name: "Test", icon: "star", colorHex: "#000", schedule: schedule)
        schedule.habit = habit
        ctx.insert(habit)

        let ancient = Calendar.current.date(byAdding: .day, value: -400, to: Date())!
        let c = HabitCompletion(completedAt: ancient, habit: habit)
        ctx.insert(c)
        habit.completions.append(c)

        let data = analytics.heatmapData(for: habit, in: .current)
        #expect(data.isEmpty)
    }
}
