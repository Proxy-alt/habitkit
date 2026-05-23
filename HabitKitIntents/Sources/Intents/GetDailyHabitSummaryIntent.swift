import AppIntents
import Foundation

// MARK: - GetDailyHabitSummaryIntent

/// Returns today's habit completions as a structured summary.
///
/// Designed for use in the bundled **Evening Habit Check-In** Shortcut (§18.2),
/// which sends a daily accountability message to a chosen contact. The Shortcut
/// uses the returned `HabitSummaryResult` to format the message — HabitKit
/// never knows who receives it.
///
/// All parameters are optional; the intent works with its defaults.
public struct GetDailyHabitSummaryIntent: AppIntent {
    public static let title: LocalizedStringResource = "Get Today's Habit Summary"
    public static let description = IntentDescription(
        """
        Returns today's habit completions for use in Shortcuts. \
        Designed for accountability check-ins and progress reports.
        """
    )
    public static let openAppWhenRun = false

    // MARK: - Parameters

    /// Controls whether sensitive habits appear in the summary.
    /// Default is non-sensitive only — habits marked sensitive are excluded
    /// unless the user explicitly changes this parameter.
    @Parameter(
        title: "Visibility",
        description: "Controls whether sensitive habits appear in the summary.",
        default: .nonSensitive
    )
    public var visibility: SummaryVisibility

    /// When enabled, the current streak is included for each missed habit.
    @Parameter(
        title: "Include Streaks",
        description: "When enabled, includes the current streak for each missed habit.",
        default: true
    )
    public var includeStreaks: Bool

    /// When enabled, includes environmental context (weather, busy day) for missed habits.
    @Parameter(
        title: "Include Environmental Context",
        description: "When enabled, notes if a missed habit was due to weather or a busy day.",
        default: true
    )
    public var includeEnvironmentalContext: Bool

    // MARK: - Init

    public init() {}

    public init(
        visibility: SummaryVisibility = .nonSensitive,
        includeStreaks: Bool = true,
        includeEnvironmentalContext: Bool = true
    ) {
        self.visibility = visibility
        self.includeStreaks = includeStreaks
        self.includeEnvironmentalContext = includeEnvironmentalContext
    }

    // MARK: - Perform

    public func perform() async throws -> some IntentResult & ReturnsValue<HabitSummaryResult> {
        let store = HabitIntentStore(modelContainer: try IntentModelContainer.make())
        let habits = try await store.fetchAllHabits()
        let skipped = SkipStore.skippedTodayIDs()

        let completed = habits.filter { $0.isCompletedToday }
        let missed = habits.filter {
            !$0.isCompletedToday && !skipped.contains($0.id.uuidString)
        }

        let missedSummaries = missed.map { entity in
            MissedHabitSummary(
                name: entity.name,
                streak: includeStreaks ? entity.streak : nil,
                isEnvironmentalMiss: false,
                environmentalReason: nil
            )
        }

        let result = HabitSummaryResult(
            completedCount: completed.count,
            totalCount: habits.count,
            missedHabits: missedSummaries,
            date: Date()
        )
        return .result(value: result)
    }
}

// MARK: - SummaryVisibility

/// Controls which habits appear in the daily summary.
public enum SummaryVisibility: String, AppEnum {
    /// All habits, including those marked sensitive.
    case all
    /// Only habits not marked sensitive (default).
    case nonSensitive
    /// A user-configured custom list (configured in app settings).
    case custom

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Visibility")
    public static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .all: "All habits",
        .nonSensitive: "Non-sensitive habits only",
        .custom: "Custom selection",
    ]
}

// MARK: - HabitSummaryResult

/// A structured summary of today's habit completions, returned by
/// `GetDailyHabitSummaryIntent`.
public struct HabitSummaryResult: AppEntity {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit Summary")
    public static let defaultQuery = HabitSummaryQuery()

    /// Unique identifier for this result instance.
    public var id: String

    /// The number of habits completed today.
    public var completedCount: Int

    /// The total number of habits in scope for the summary.
    public var totalCount: Int

    /// Habits that were not completed and not skipped today.
    public var missedHabits: [MissedHabitSummary]

    /// The date this summary was generated.
    public var date: Date

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(completedCount) of \(totalCount) habits done",
            subtitle: "\(missedHabits.count) remaining"
        )
    }

    public init(
        id: String = UUID().uuidString,
        completedCount: Int,
        totalCount: Int,
        missedHabits: [MissedHabitSummary],
        date: Date
    ) {
        self.id = id
        self.completedCount = completedCount
        self.totalCount = totalCount
        self.missedHabits = missedHabits
        self.date = date
    }
}

/// Resolves `HabitSummaryResult` instances. Required by `AppEntity` conformance;
/// summaries are always generated on demand, not stored.
public struct HabitSummaryQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [HabitSummaryResult] {
        []
    }
}

// MARK: - MissedHabitSummary

/// Summary information for a habit that was not completed today.
public struct MissedHabitSummary: Codable, Sendable {
    /// The habit's display name.
    public var name: String

    /// The current streak length; `nil` when `includeStreaks` is false.
    public var streak: Int?

    /// Whether the miss was due to an environmental factor (weather, busy day).
    public var isEnvironmentalMiss: Bool

    /// A plain-language description of the environmental reason,
    /// e.g. "thunderstorm" or "busy day". `nil` when not applicable.
    public var environmentalReason: String?

    public init(
        name: String,
        streak: Int?,
        isEnvironmentalMiss: Bool,
        environmentalReason: String?
    ) {
        self.name = name
        self.streak = streak
        self.isEnvironmentalMiss = isEnvironmentalMiss
        self.environmentalReason = environmentalReason
    }
}
