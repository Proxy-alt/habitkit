import AppIntents
import Foundation

/// A Focus Filter intent that controls which habits are visible during a Focus mode.
///
/// Users configure this in the Focus settings screen. The selected habit IDs
/// are written to the shared App Group `UserDefaults` so the main app, widgets,
/// and notification extensions all read the same filtered set without an
/// inter-process round trip.
public struct HabitFocusFilterIntent: SetFocusFilterIntent {
    public static let title: LocalizedStringResource = "Filter Habits by Focus"
    public static let description: LocalizedStringResource =
        "Show only habits tagged for this Focus mode."

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "Filter by Focus")
    }

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
