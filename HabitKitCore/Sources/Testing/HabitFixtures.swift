#if DEBUG
import Foundation

public extension Habit {
    /// Creates a sample habit suitable for SwiftUI previews and tests.
    static func preview(
        name: String = "Morning Run",
        icon: String = "figure.run",
        colorHex: String = "#cba6f7"
    ) -> Habit {
        let schedule = HabitSchedule.preview()
        let habit = Habit(name: name, icon: icon, colorHex: colorHex, schedule: schedule)
        schedule.habit = habit
        return habit
    }
}

public extension TimedHabit {
    /// Creates a sample timed habit suitable for SwiftUI previews and tests.
    static func preview(
        name: String = "Meditation",
        icon: String = "brain.head.profile",
        targetSeconds: Int = 600
    ) -> TimedHabit {
        let schedule = HabitSchedule.preview()
        let habit = TimedHabit(
            name: name,
            icon: icon,
            colorHex: "#cba6f7",
            schedule: schedule,
            targetDurationSeconds: targetSeconds
        )
        schedule.habit = habit
        return habit
    }
}

public extension HabitSchedule {
    /// Creates a sample daily schedule suitable for SwiftUI previews and tests.
    ///
    /// The `habit` back-reference is `nil` until a `Habit` is constructed and
    /// assigned. Preview factories set it automatically.
    static func preview() -> HabitSchedule {
        HabitSchedule(frequency: .daily, reminderTimes: [], habit: nil)
    }
}

public extension HabitCompletion {
    /// Creates a sample completion suitable for SwiftUI previews and tests.
    ///
    /// - Parameters:
    ///   - habit: The habit this completion belongs to.
    ///   - daysAgo: How many days in the past to set the `completedAt` date.
    static func preview(habit: Habit, daysAgo: Int = 0) -> HabitCompletion {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return HabitCompletion(completedAt: date, habit: habit)
    }
}
#endif
