import Foundation
import SwiftData
import HabitKitCore

/// Creates a `ModelContainer` for use within AppIntent extension processes.
///
/// Uses the App Group container so data is shared with the main app and widgets.
/// Called once per intent invocation; `ModelContainer` is lightweight to construct.
enum IntentModelContainer {
    static func make() throws -> ModelContainer {
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
        return try ModelContainer(for: schema, configurations: [config])
    }
}
