import AppIntents
import Foundation

/// Returns today's scheduled habits, with optional filtering by completion status
/// and 30-day completion rate.
///
/// Use this as the single entry point for habit list queries in Shortcuts:
/// - Toggle **Incomplete Only** to see only what still needs doing today.
/// - Set **Minimum Completion %** (0–100) to surface only your most consistent
///   habits; e.g. 80 returns habits you've completed ≥ 80 % of their scheduled
///   days over the last 30 days.
public struct GetHabitsIntent: AppIntent {
    public static let title: LocalizedStringResource = "Get Habits"
    public static let description = IntentDescription(
        "Returns today's scheduled habits. Optionally filter to incomplete habits and by 30-day completion rate."
    )
    public static let openAppWhenRun = false

    /// When enabled, returns only habits not yet completed or skipped today.
    @Parameter(title: "Incomplete Only", description: "Return only habits you haven't done today.", default: false)
    public var incompleteOnly: Bool

    /// Habits with a 30-day completion rate below this percentage are excluded.
    /// Accepts 0–100; 0 disables the filter.
    @Parameter(
        title: "Minimum Completion %",
        description: "Only include habits completed at least this often in the last 30 days (0 = no filter).",
        default: 0,
        requestValueDialog: "What minimum completion percentage? (0–100)"
    )
    public var minimumCompletionPct: Int

    public init() {}

    public init(incompleteOnly: Bool = false, minimumCompletionPct: Int = 0) {
        self.incompleteOnly = incompleteOnly
        self.minimumCompletionPct = minimumCompletionPct
    }

    public func perform() async throws -> some IntentResult & ReturnsValue<[HabitEntity]> {
        let store = HabitIntentStore(modelContainer: IntentModelContainer.shared)
        let skipped = incompleteOnly ? SkipStore.skippedTodayIDs() : []
        let habits = try await store.fetchHabits(
            incompleteOnly: incompleteOnly,
            minimumCompletionPct: minimumCompletionPct,
            skippedIDs: skipped
        )
        return .result(value: habits)
    }
}
