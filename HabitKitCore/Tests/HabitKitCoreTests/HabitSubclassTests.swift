import Foundation
import Testing
@testable import HabitKitCore

@MainActor
@Suite("HabitSubclasses")
struct HabitSubclassTests {

    // MARK: - TimedHabit

    @Test("TimedHabit preserves targetDurationSeconds on init")
    func timedHabitInit() {
        let schedule = HabitSchedule(frequency: .daily)
        let habit = TimedHabit(
            name: "Meditate",
            icon: "brain.head.profile",
            colorHex: "#00F",
            schedule: schedule,
            targetDurationSeconds: 600
        )
        #expect(habit.targetDurationSeconds == 600)
        #expect(habit.name == "Meditate")
        #expect(habit.icon == "brain.head.profile")
        #expect(habit.colorHex == "#00F")
    }

    @Test("TimedHabit targetDurationSeconds is mutable")
    func timedHabitMutation() {
        let schedule = HabitSchedule(frequency: .daily)
        let habit = TimedHabit(
            name: "Run",
            icon: "figure.run",
            colorHex: "#F00",
            schedule: schedule,
            targetDurationSeconds: 300
        )
        habit.targetDurationSeconds = 900
        #expect(habit.targetDurationSeconds == 900)
    }

    @Test("TimedHabit inherits Habit base properties")
    func timedHabitInheritedProperties() {
        let schedule = HabitSchedule(frequency: .weekly(days: [1, 3, 5]))
        let habit = TimedHabit(
            name: "Yoga",
            icon: "figure.yoga",
            colorHex: "#0F0",
            sortOrder: 2,
            isArchived: false,
            schedule: schedule,
            targetDurationSeconds: 1800
        )
        #expect(habit.sortOrder == 2)
        #expect(!habit.isArchived)
        #expect(habit.focusModeID == nil)
    }

    // MARK: - QuantityHabit

    @Test("QuantityHabit preserves targetQuantity and unit on init")
    func quantityHabitInit() {
        let schedule = HabitSchedule(frequency: .daily)
        let habit = QuantityHabit(
            name: "Water",
            icon: "drop",
            colorHex: "#00F",
            schedule: schedule,
            targetQuantity: 8.0,
            unit: "glasses"
        )
        #expect(habit.targetQuantity == 8.0)
        #expect(habit.unit == "glasses")
        #expect(habit.name == "Water")
    }

    @Test("QuantityHabit targetQuantity and unit are mutable")
    func quantityHabitMutation() {
        let schedule = HabitSchedule(frequency: .daily)
        let habit = QuantityHabit(
            name: "Steps",
            icon: "figure.walk",
            colorHex: "#0F0",
            schedule: schedule,
            targetQuantity: 10_000,
            unit: "steps"
        )
        habit.targetQuantity = 12_000
        habit.unit = "paces"
        #expect(habit.targetQuantity == 12_000)
        #expect(habit.unit == "paces")
    }

    @Test("QuantityHabit inherits Habit base properties")
    func quantityHabitInheritedProperties() {
        let id = UUID()
        let schedule = HabitSchedule(frequency: .daily)
        let habit = QuantityHabit(
            id: id,
            name: "Protein",
            icon: "fork.knife",
            colorHex: "#FF0",
            sortOrder: 1,
            schedule: schedule,
            targetQuantity: 150,
            unit: "grams"
        )
        #expect(habit.id == id)
        #expect(habit.sortOrder == 1)
    }

    // MARK: - ChecklistHabit

    @Test("ChecklistHabit preserves steps on init")
    func checklistHabitInit() {
        let schedule = HabitSchedule(frequency: .daily)
        let habit = ChecklistHabit(
            name: "Morning Routine",
            icon: "list.bullet",
            colorHex: "#0F0",
            schedule: schedule,
            steps: ["Brush teeth", "Shower", "Breakfast"]
        )
        #expect(habit.steps == ["Brush teeth", "Shower", "Breakfast"])
        #expect(habit.name == "Morning Routine")
        #expect(habit.steps.count == 3)
    }

    @Test("ChecklistHabit steps are mutable")
    func checklistHabitMutation() {
        let schedule = HabitSchedule(frequency: .daily)
        let habit = ChecklistHabit(
            name: "Routine",
            icon: "checklist",
            colorHex: "#000",
            schedule: schedule,
            steps: ["Step A"]
        )
        habit.steps = ["Step A", "Step B", "Step C"]
        #expect(habit.steps.count == 3)
        #expect(habit.steps.last == "Step C")
    }

    @Test("ChecklistHabit empty steps list")
    func checklistHabitEmptySteps() {
        let schedule = HabitSchedule(frequency: .daily)
        let habit = ChecklistHabit(
            name: "Empty",
            icon: "checklist",
            colorHex: "#000",
            schedule: schedule,
            steps: []
        )
        #expect(habit.steps.isEmpty)
    }

    // MARK: - NegativeHabit

    @Test("NegativeHabit preserves avoidTarget on init")
    func negativeHabitInit() {
        let schedule = HabitSchedule(frequency: .daily)
        let habit = NegativeHabit(
            name: "No Phone",
            icon: "iphone.slash",
            colorHex: "#F00",
            schedule: schedule,
            avoidTarget: "Avoid social media"
        )
        #expect(habit.avoidTarget == "Avoid social media")
        #expect(habit.name == "No Phone")
    }

    @Test("NegativeHabit avoidTarget is mutable")
    func negativeHabitMutation() {
        let schedule = HabitSchedule(frequency: .daily)
        let habit = NegativeHabit(
            name: "No Junk Food",
            icon: "fork.knife",
            colorHex: "#F0F",
            schedule: schedule,
            avoidTarget: "No fast food"
        )
        habit.avoidTarget = "No sweets either"
        #expect(habit.avoidTarget == "No sweets either")
    }

    @Test("NegativeHabit inherits Habit base properties")
    func negativeHabitInheritedProperties() {
        let focusID = "com.example.focus"
        let schedule = HabitSchedule(frequency: .interval(every: 3))
        let habit = NegativeHabit(
            name: "Quit Smoking",
            icon: "smoke",
            colorHex: "#888",
            focusModeID: focusID,
            schedule: schedule,
            avoidTarget: "No cigarettes"
        )
        #expect(habit.focusModeID == focusID)
    }

    // MARK: - HabitFixtures (#if DEBUG)

    @Test("Habit.preview() creates a valid habit with defaults")
    func habitPreviewDefaults() {
        let habit = Habit.preview()
        #expect(habit.name == "Morning Run")
        #expect(habit.icon == "figure.run")
    }

    @Test("Habit.preview() accepts custom name and icon")
    func habitPreviewCustom() {
        let habit = Habit.preview(name: "Walk", icon: "figure.walk", colorHex: "#abc")
        #expect(habit.name == "Walk")
        #expect(habit.icon == "figure.walk")
        #expect(habit.colorHex == "#abc")
    }

    @Test("TimedHabit.preview() creates a valid timed habit")
    func timedHabitPreview() {
        let habit = TimedHabit.preview(targetSeconds: 600)
        #expect(habit.name == "Meditation")
        #expect(habit.targetDurationSeconds == 600)
    }

    @Test("TimedHabit.preview() accepts custom parameters")
    func timedHabitPreviewCustom() {
        let habit = TimedHabit.preview(name: "Yoga", icon: "figure.yoga", targetSeconds: 1800)
        #expect(habit.name == "Yoga")
        #expect(habit.targetDurationSeconds == 1800)
    }

    @Test("HabitSchedule.preview() creates a daily schedule")
    func habitSchedulePreview() {
        let schedule = HabitSchedule.preview()
        #expect(schedule.frequency == .daily)
        #expect(schedule.reminderTimes.isEmpty)
        #expect(schedule.habit == nil)
    }

    @Test("HabitCompletion.preview() creates a completion for today")
    func habitCompletionPreview() {
        let habit = Habit.preview()
        let completion = HabitCompletion.preview(habit: habit)
        let calendar = Calendar.current
        #expect(calendar.isDateInToday(completion.completedAt))
    }

    @Test("HabitCompletion.preview(daysAgo:) offsets the date correctly")
    func habitCompletionPreviewOffset() {
        let habit = Habit.preview()
        let completion = HabitCompletion.preview(habit: habit, daysAgo: 3)
        let calendar = Calendar.current
        let expected = calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        let diff = abs(completion.completedAt.timeIntervalSince(expected))
        #expect(diff < 5.0)
    }
}
