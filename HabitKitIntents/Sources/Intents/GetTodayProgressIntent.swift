import AppIntents
import Foundation

public struct GetTodayProgressIntent: AppIntent {
    public static let title: LocalizedStringResource = "Get Today's Progress"
    public static let description = IntentDescription(
        "Returns the fraction of today's habits that have been completed, as a value between 0.0 and 1.0."
    )
    public static let openAppWhenRun = false

    public init() {}

    public func perform() async throws -> some IntentResult & ReturnsValue<Double> {
        // In a real app, this would query SwiftData for all habits scheduled
        // for today and divide the completed count by the total count.
        let progress: Double = 0.0
        return .result(value: progress)
    }
}
