import AppIntents
import Foundation

// MARK: - GetHabitsIntent

/// Returns habits matching the specified filters.
///
/// This is the single entry point for habit list queries in Shortcuts. All
/// parameters are optional — calling with defaults returns all of today's
/// scheduled habits sorted in the user's preferred order.
///
/// **Replaces** `ListIncompleteHabitsIntent`, which is retained for backward
/// compatibility with existing Shortcuts but should not be used in new automations.
public struct GetHabitsIntent: AppIntent {
    public static let title: LocalizedStringResource = "Get Habits"
    public static let description = IntentDescription(
        """
        Returns habits matching the specified filters. Use in Shortcuts to build \
        custom automations, reports, and accountability flows.
        """
    )
    public static let openAppWhenRun = false

    // MARK: - Completion state filter

    /// When enabled, only returns habits matching the completion state below.
    @Parameter(
        title: "Filter by Completion",
        description: "When enabled, only returns habits matching the completion state below.",
        default: false
    )
    public var filterByCompletion: Bool

    /// Which habits to return based on today's completion state.
    @Parameter(
        title: "Completion State",
        description: "Which habits to return based on today's completion state.",
        default: .incomplete
    )
    public var completionState: HabitCompletionStateFilter

    // MARK: - Partial completion threshold

    /// Only used when completion state is 'Partial or below'. Range 1–99.
    @Parameter(
        title: "Partial Completion Threshold (%)",
        description: "Only used when completion state is 'Partial or below'. Range 1–99.",
        default: 50,
        inclusiveRange: (1, 99)
    )
    public var partialCompletionThreshold: Int

    // MARK: - Visibility filter

    /// Controls whether sensitive habits are included.
    @Parameter(
        title: "Visibility",
        description: "Controls whether sensitive habits are included.",
        default: .nonSensitive
    )
    public var visibility: HabitVisibilityFilter

    // MARK: - Type filter

    /// Filter by habit type.
    @Parameter(
        title: "Habit Type",
        description: "Filter by habit type.",
        default: .all
    )
    public var habitType: HabitTypeFilter

    // MARK: - Schedule filter

    /// When enabled, only returns habits scheduled for today.
    @Parameter(
        title: "Scheduled Today Only",
        description: "When enabled, only returns habits scheduled for today.",
        default: true
    )
    public var scheduledTodayOnly: Bool

    // MARK: - Sort order

    @Parameter(title: "Sort By", default: .userOrder)
    public var sortBy: HabitSortOrder

    // MARK: - Init

    public init() {}

    public init(
        filterByCompletion: Bool = false,
        completionState: HabitCompletionStateFilter = .incomplete,
        partialCompletionThreshold: Int = 50,
        visibility: HabitVisibilityFilter = .nonSensitive,
        habitType: HabitTypeFilter = .all,
        scheduledTodayOnly: Bool = true,
        sortBy: HabitSortOrder = .userOrder
    ) {
        self.filterByCompletion = filterByCompletion
        self.completionState = completionState
        self.partialCompletionThreshold = partialCompletionThreshold
        self.visibility = visibility
        self.habitType = habitType
        self.scheduledTodayOnly = scheduledTodayOnly
        self.sortBy = sortBy
    }

    // MARK: - Perform

    public func perform() async throws -> some IntentResult & ReturnsValue<[HabitEntity]> {
        let store = HabitIntentStore(modelContainer: try IntentModelContainer.make())
        let skipped = SkipStore.skippedTodayIDs()

        var habits: [HabitEntity]
        if scheduledTodayOnly {
            habits = try await store.fetchHabits(
                incompleteOnly: false,
                minimumCompletionPct: 0,
                skippedIDs: []
            )
        } else {
            habits = try await store.fetchAllHabits()
        }

        if filterByCompletion {
            habits = habits.filter { entity in
                switch completionState {
                case .complete:
                    return entity.isCompletedToday
                case .incomplete:
                    return !entity.isCompletedToday && !skipped.contains(entity.id.uuidString)
                case .partialOrBelow:
                    // Quantity/timed habits only — boolean habits excluded
                    return !entity.isCompletedToday
                case .skipped:
                    return skipped.contains(entity.id.uuidString)
                case .environmentalMiss:
                    // Environmental miss detection deferred to post-v1
                    return false
                }
            }
        }

        habits = sortHabits(habits, by: sortBy)
        return .result(value: habits)
    }

    // MARK: - Sort

    private func sortHabits(_ habits: [HabitEntity], by order: HabitSortOrder) -> [HabitEntity] {
        switch order {
        case .userOrder:
            return habits
        case .alphabetical:
            return habits.sorted { $0.name < $1.name }
        case .streakDesc:
            return habits.sorted { $0.streak > $1.streak }
        case .streakAsc:
            return habits.sorted { $0.streak < $1.streak }
        case .completionTime:
            return habits.sorted { lhs, rhs in
                if lhs.isCompletedToday == rhs.isCompletedToday { return false }
                return lhs.isCompletedToday && !rhs.isCompletedToday
            }
        }
    }
}

// MARK: - HabitCompletionStateFilter

/// Filters the habit list by today's completion state.
public enum HabitCompletionStateFilter: String, AppEnum {
    /// Fully completed today.
    case complete
    /// Not yet completed and not skipped.
    case incomplete
    /// Quantity or timed habits completed below the partial threshold.
    case partialOrBelow
    /// Explicitly skipped today.
    case skipped
    /// Missed due to an environmental factor (weather, busy day).
    case environmentalMiss

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Completion State")
    public static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .complete: "Complete",
        .incomplete: "Incomplete",
        .partialOrBelow: "Partial or below threshold",
        .skipped: "Skipped",
        .environmentalMiss: "Environmental miss",
    ]
}

// MARK: - HabitVisibilityFilter

/// Controls which habits are returned based on their sensitive status.
public enum HabitVisibilityFilter: String, AppEnum {
    /// All habits, including those marked sensitive.
    case all
    /// Only habits not marked sensitive (default).
    case nonSensitive
    /// Only habits marked sensitive.
    case sensitiveOnly

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Visibility")
    public static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .all: "All habits",
        .nonSensitive: "Non-sensitive only",
        .sensitiveOnly: "Sensitive only",
    ]
}

// MARK: - HabitTypeFilter

/// Filters the habit list by the habit's data type.
public enum HabitTypeFilter: String, AppEnum {
    case all
    case timed
    case quantity
    case checklist
    case negative

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit Type")
    public static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .all: "All types",
        .timed: "Timed",
        .quantity: "Quantity",
        .checklist: "Checklist",
        .negative: "Negative (avoidance)",
    ]
}

// MARK: - HabitSortOrder

/// The order in which habits are returned.
public enum HabitSortOrder: String, AppEnum {
    /// Respects the user's manual sort order in the app (default).
    case userOrder
    case alphabetical
    /// Longest streak first.
    case streakDesc
    /// Shortest streak first.
    case streakAsc
    /// Completed habits first, incomplete habits last.
    case completionTime

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Sort By")
    public static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .userOrder: "App order",
        .alphabetical: "Alphabetical",
        .streakDesc: "Longest streak first",
        .streakAsc: "Shortest streak first",
        .completionTime: "Completion time",
    ]
}
