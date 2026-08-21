import Foundation
import SwiftData

/// The base model representing a single trackable habit.
@Model
public class Habit {
    /// Stable unique identifier for this habit.
    public var id: UUID = UUID()

    /// User-visible name of the habit.
    public var name: String = ""

    /// SF Symbol name used to represent the habit visually.
    public var icon: String = ""

    /// Hex color string (e.g. #FF5733) for the habit's accent color.
    public var colorHex: String = ""

    /// Position of this habit in a user-ordered list.
    public var sortOrder: Int = 0

    /// The date and time this habit was first created.
    public var createdAt: Date = Date()

    /// When true the habit is hidden from the main list but not deleted.
    public var isArchived: Bool = false

    /// Optional identifier linking this habit to a Focus Mode configuration.
    public var focusModeID: String?

    /// Backing storage for `completions`. CloudKit requires to-many
    /// relationships to be Optional; `completions` below hides that behind
    /// the non-optional array callers already expect (same pattern as
    /// `HabitCompletion.tags`/`HabitSchedule.frequency`).
    @Relationship(deleteRule: .cascade)
    var completionsStorage: [HabitCompletion]?

    /// All recorded completions for this habit.
    public var completions: [HabitCompletion] {
        get { completionsStorage ?? [] }
        set { completionsStorage = newValue }
    }

    /// Backing storage for `schedule`. CloudKit requires to-one relationships
    /// to be Optional; every `Habit` is always constructed with a schedule,
    /// so `schedule` below force-unwraps rather than pushing `nil`-handling
    /// onto every call site.
    @Relationship(deleteRule: .cascade)
    var scheduleStorage: HabitSchedule?

    /// The scheduling rule and reminder configuration for this habit.
    public var schedule: HabitSchedule {
        get { scheduleStorage! }
        set { scheduleStorage = newValue }
    }

    /// Optional progressive overload plan.
    /// `nil` means the target is fixed and never automatically adjusted.
    @Relationship(deleteRule: .cascade)
    public var progressionPlan: ProgressionPlan?

    /// Placeholder for post-v1 Vision-based photo completion validation.
    /// Always `nil` in v1.
    @Relationship(deleteRule: .cascade)
    public var visionProfile: VisionProfile?

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
        progressionPlan: ProgressionPlan? = nil,
        visionProfile: VisionProfile? = nil
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
        self.progressionPlan = progressionPlan
        self.visionProfile = visionProfile
    }
}
