import Foundation
import SwiftData

/// A habit that is completed by performing an activity for a target duration.
public class TimedHabit: Habit {
    /// The number of seconds the user should spend on this habit per session.
    public var targetDurationSeconds: Int

    required init(backingData: any SwiftData.BackingData<Habit>) {
        self.targetDurationSeconds = 0
        super.init(backingData: backingData)
    }

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        isArchived: Bool = false,
        focusModeID: String? = nil,
        completions: [HabitCompletion] = [],
        schedule: HabitSchedule,
        targetDurationSeconds: Int
    ) {
        self.targetDurationSeconds = targetDurationSeconds
        super.init(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortOrder: sortOrder,
            createdAt: createdAt,
            isArchived: isArchived,
            focusModeID: focusModeID,
            completions: completions,
            schedule: schedule
        )
    }
}

/// A habit that is completed by reaching a measurable quantity (e.g. 8 glasses of water).
public class QuantityHabit: Habit {
    /// The numeric amount the user must reach to consider the habit complete.
    public var targetQuantity: Double

    /// Human-readable unit label for the quantity (e.g. "glasses", "km", "reps").
    public var unit: String

    required init(backingData: any SwiftData.BackingData<Habit>) {
        self.targetQuantity = 1
        self.unit = ""
        super.init(backingData: backingData)
    }

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        isArchived: Bool = false,
        focusModeID: String? = nil,
        completions: [HabitCompletion] = [],
        schedule: HabitSchedule,
        targetQuantity: Double,
        unit: String
    ) {
        self.targetQuantity = targetQuantity
        self.unit = unit
        super.init(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortOrder: sortOrder,
            createdAt: createdAt,
            isArchived: isArchived,
            focusModeID: focusModeID,
            completions: completions,
            schedule: schedule
        )
    }
}

/// A habit that is completed by checking off every step in an ordered list.
public class ChecklistHabit: Habit {
    /// Ordered list of step descriptions the user must complete.
    public var steps: [String]

    required init(backingData: any SwiftData.BackingData<Habit>) {
        self.steps = []
        super.init(backingData: backingData)
    }

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        isArchived: Bool = false,
        focusModeID: String? = nil,
        completions: [HabitCompletion] = [],
        schedule: HabitSchedule,
        steps: [String]
    ) {
        self.steps = steps
        super.init(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortOrder: sortOrder,
            createdAt: createdAt,
            isArchived: isArchived,
            focusModeID: focusModeID,
            completions: completions,
            schedule: schedule
        )
    }
}

/// A habit that tracks avoidance of a behaviour rather than performing one.
public class NegativeHabit: Habit {
    /// Description of what the user is trying to avoid (e.g. "Avoid social media").
    public var avoidTarget: String

    required init(backingData: any SwiftData.BackingData<Habit>) {
        self.avoidTarget = ""
        super.init(backingData: backingData)
    }

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        isArchived: Bool = false,
        focusModeID: String? = nil,
        completions: [HabitCompletion] = [],
        schedule: HabitSchedule,
        avoidTarget: String
    ) {
        self.avoidTarget = avoidTarget
        super.init(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortOrder: sortOrder,
            createdAt: createdAt,
            isArchived: isArchived,
            focusModeID: focusModeID,
            completions: completions,
            schedule: schedule
        )
    }
}
