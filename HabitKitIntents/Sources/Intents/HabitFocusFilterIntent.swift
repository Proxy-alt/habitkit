import AppIntents
import Foundation

public struct HabitFocusFilterIntent: SetFocusFilterIntent {
    public static var title: LocalizedStringResource = "Filter Habits by Focus"
    public static var description: LocalizedStringResource =
        "Show only habits tagged for this Focus mode."

    @Parameter(title: "Visible Habits")
    public var habits: [HabitEntity]

    public init() {}

    public func perform() async throws -> some IntentResult {
        // Persist the selected habit IDs to the shared App Group UserDefaults so
        // the main app and widgets can read the Focus-filtered list without an
        // inter-process round trip.
        let habitIDs = habits.map(\.id.uuidString)
        let defaults = UserDefaults(suiteName: "group.com.habitkit.app")
        defaults?.set(habitIDs, forKey: "focusVisibleHabitIDs")
        return .result()
    }
}
