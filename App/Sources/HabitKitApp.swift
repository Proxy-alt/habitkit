import SwiftUI
import SwiftData
import HabitKitCore
import HabitKitUI

@main
struct HabitKitApp: App {
    @State private var themeManager = HKThemeManager()
    @AppStorage(DefaultsKeys.icloudSync) private var icloudSyncEnabled = true

    private let modelContainer: ModelContainer = {
        do {
            return try ModelContainerConfiguration.makeContainer(cloudKitEnabled: true)
        } catch {
            // ModelContainer creation failure is unrecoverable at launch.
            // Log the error before terminating so crash reports include context.
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
                .modelContainer(modelContainer)
                .onAppear {
                    DefaultsKeys.registerDefaults()
                }
        }
    }
}
