import AppIntents
import Foundation

/// Returns today's overall habit completion as a `Double` in the range 0.0–1.0.
///
/// The value is the number of completed habits divided by the total number of
/// habits scheduled for today. Returns 0.0 if no habits are scheduled.
public struct GetTodayProgressIntent: AppIntent {
    public static let title: LocalizedStringResource = "Get Today's Progress"
    public static let description = IntentDescription(
        "Returns the fraction of today's habits that have been completed, as a value between 0.0 and 1.0."
    )
    public static let openAppWhenRun = false

    public init() {}

    public func perform() async throws -> some IntentResult & ReturnsValue<Double> {
        let store = HabitIntentStore(modelContainer: IntentModelContainer.shared)
        let progress = try await store.todayProgress()
        return .result(value: progress)
    }
}
