import Foundation
import SwiftData

/// The base model representing a single trackable habit.
@Model
public class Habit {
    /// Stable unique identifier for this habit.
    public var id: UUID

    /// User-visible name of the habit.
    public var name: String

    /// SF Symbol name used to represent the habit visually.
    public var icon: String

    /// Hex color string (e.g. #FF5733) for the habit's accent color.
    public var colorHex: String

    /// Position of this habit in a user-ordered list.
    public var sortOrder: Int

    /// The date and time this habit was first created.
    public var createdAt: Date

    /// When true the habit is hidden from the main list but not deleted.
    public var isArchived: Bool

    /// Optional identifier linking this habit to a Focus Mode configuration.
    public var focusModeID: String?

    /// All recorded completions for this habit.
    @Relationship(deleteRule: .cascade)
    public var completions: [HabitCompletion]

    /// The scheduling rule and reminder configuration for this habit.
    @Relationship(deleteRule: .cascade)
    public var schedule: HabitSchedule

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
        schedule: HabitSchedule
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.focusModeID = focusModeID
        self.completions = completions
        self.schedule = schedule
    }
}
