import SwiftUI
import SwiftData
import HabitKitCore
import HabitKitUI

@main
struct HabitKitApp: App {
    @State private var themeManager = HKThemeManager()
    @AppStorage(DefaultsKeys.icloudSync) private var icloudSyncEnabled = true

    private let modelContainer: ModelContainer = {
        guard let container = try? ModelContainerConfiguration.makeContainer(cloudKitEnabled: true) else {
            fatalError("Failed to create ModelContainer")
        }
        return container
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
