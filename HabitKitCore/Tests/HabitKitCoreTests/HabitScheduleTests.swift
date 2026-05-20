import Foundation
import SwiftData
import Testing
@testable import HabitKitCore

@MainActor
@Suite("HabitSchedule.isDue")
struct HabitScheduleTests {

    private func makeContext() throws -> ModelContext {
        ModelContext(try ModelContainerConfiguration.makeInMemoryContainer())
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        return Calendar.current.date(from: c)!
    }

    // MARK: - daily

    @Test("daily schedule is always due")
    func dailyAlwaysDue() throws {
        let ctx = try makeContext()
        let schedule = HabitSchedule(frequency: .daily)
        ctx.insert(schedule)
        let habit = Habit(name: "H", icon: "star", colorHex: "#000", schedule: schedule)
        schedule.habit = habit
        ctx.insert(habit)

        #expect(schedule.isDue(on: date(year: 2024, month: 1, day: 1)))
        #expect(schedule.isDue(on: date(year: 2024, month: 7, day: 15)))
        #expect(schedule.isDue(on: Date()))
    }

    // MARK: - weekly

    @Test("weekly schedule is due only on selected weekdays")
    func weeklyDueDays() throws {
        let ctx = try makeContext()
        // 1=Monday, 3=Wednesday (0-based: Sunday=0)
        let schedule = HabitSchedule(frequency: .weekly(days: [1, 3]))
        ctx.insert(schedule)

        // 2024-01-01 is Monday (weekday component 2 → 0-based: 1)
        let monday = date(year: 2024, month: 1, day: 1)
        let tuesday = date(year: 2024, month: 1, day: 2)
        let wednesday = date(year: 2024, month: 1, day: 3)

        #expect(schedule.isDue(on: monday))
        #expect(!schedule.isDue(on: tuesday))
        #expect(schedule.isDue(on: wednesday))
    }

    @Test("weekly schedule with empty set is never due")
    func weeklyEmptySet() throws {
        let ctx = try makeContext()
        let schedule = HabitSchedule(frequency: .weekly(days: []))
        ctx.insert(schedule)
        #expect(!schedule.isDue(on: Date()))
    }

    // MARK: - interval

    @Test("interval schedule is due on creation day")
    func intervalDueOnCreationDay() throws {
        let ctx = try makeContext()
        let schedule = HabitSchedule(frequency: .interval(every: 3))
        ctx.insert(schedule)
        let today = Calendar.current.startOfDay(for: Date())
        let habit = Habit(name: "H", icon: "star", colorHex: "#000", createdAt: today, schedule: schedule)
        schedule.habit = habit
        ctx.insert(habit)

        #expect(schedule.isDue(on: today))
    }

    @Test("interval schedule is due every N days from creation")
    func intervalEveryNDays() throws {
        let ctx = try makeContext()
        let schedule = HabitSchedule(frequency: .interval(every: 3))
        ctx.insert(schedule)
        let calendar = Calendar.current
        let createdAt = calendar.startOfDay(for: date(year: 2024, month: 1, day: 1))
        let habit = Habit(name: "H", icon: "star", colorHex: "#000", createdAt: createdAt, schedule: schedule)
        schedule.habit = habit
        ctx.insert(habit)

        let day0 = createdAt
        let day1 = calendar.date(byAdding: .day, value: 1, to: createdAt)!
        let day3 = calendar.date(byAdding: .day, value: 3, to: createdAt)!
        let day6 = calendar.date(byAdding: .day, value: 6, to: createdAt)!

        #expect(schedule.isDue(on: day0))
        #expect(!schedule.isDue(on: day1))
        #expect(schedule.isDue(on: day3))
        #expect(schedule.isDue(on: day6))
    }

    @Test("interval with every=0 is never due")
    func intervalEveryZero() throws {
        let ctx = try makeContext()
        let schedule = HabitSchedule(frequency: .interval(every: 0))
        ctx.insert(schedule)
        #expect(!schedule.isDue(on: Date()))
    }

    @Test("interval without habit is never due")
    func intervalNoHabit() throws {
        let ctx = try makeContext()
        let schedule = HabitSchedule(frequency: .interval(every: 2), habit: nil)
        ctx.insert(schedule)
        #expect(!schedule.isDue(on: Date()))
    }

    // MARK: - xTimesPerWeek

    @Test("xTimesPerWeek schedule is always due")
    func xTimesPerWeekAlwaysDue() throws {
        let ctx = try makeContext()
        let schedule = HabitSchedule(frequency: .xTimesPerWeek(x: 3))
        ctx.insert(schedule)
        #expect(schedule.isDue(on: Date()))
        #expect(schedule.isDue(on: date(year: 2024, month: 6, day: 15)))
    }

    // MARK: - frequency round-trip

    @Test("frequency survives encode/decode round trip")
    func frequencyRoundTrip() throws {
        let ctx = try makeContext()
        let cases: [ScheduleFrequency] = [
            .daily,
            .weekly(days: [1, 3, 5]),
            .interval(every: 7),
            .xTimesPerWeek(x: 4)
        ]
        for freq in cases {
            let schedule = HabitSchedule(frequency: freq)
            ctx.insert(schedule)
            #expect(schedule.frequency == freq)
        }
    }

    // MARK: - reminderTimes round-trip

    @Test("reminderTimes survives encode/decode round trip")
    func reminderTimesRoundTrip() throws {
        let ctx = try makeContext()
        let times = [Date(timeIntervalSince1970: 3600 * 8), Date(timeIntervalSince1970: 3600 * 20)]
        let schedule = HabitSchedule(frequency: .daily, reminderTimes: times)
        ctx.insert(schedule)
        // JSON Date encoding has second precision; compare with tolerance
        for (stored, original) in zip(schedule.reminderTimes, times) {
            #expect(abs(stored.timeIntervalSince(original)) < 1.0)
        }
    }
}
