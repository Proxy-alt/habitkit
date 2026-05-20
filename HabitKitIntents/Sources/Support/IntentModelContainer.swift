import Foundation
import SwiftData
import HabitKitCore

/// Shared SwiftData container used by all AppIntents in the extension process.
///
/// Uses the App Group container so data is shared with the main app and widgets.
enum IntentModelContainer {
    nonisolated(unsafe) static let shared: ModelContainer = {
        let schema = Schema([Habit.self, HabitCompletion.self, HabitSchedule.self])
        let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.habitkit.app")?
            .appendingPathComponent("HabitKit.store")
        let config: ModelConfiguration
        if let url = groupURL {
            config = ModelConfiguration(schema: schema, url: url)
        } else {
            config = ModelConfiguration(schema: schema)
        }
        return try! ModelContainer(for: schema, configurations: [config])
    }()
}
