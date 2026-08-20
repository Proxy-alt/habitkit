import SwiftUI
import SwiftData
import AppIntents
import HabitKitCore
import HabitKitUI

@main
struct HabitKitApp: App {
    @State private var themeManager = HKThemeManager()
    @State private var navigator = AppNavigator()
    @State private var alarmMonitor = InAppAlarmMonitor()
    @AppStorage(DefaultsKeys.iCloudSync) private var icloudSyncEnabled = true

    private let modelContainer: ModelContainer = {
        do {
            return try ModelContainerConfiguration.makeContainer(cloudKitEnabled: true)
        } catch {
            // The current schema does not yet meet CloudKit's requirements
            // (every attribute needs a default value, every relationship
            // must be optional with a declared inverse) — see the schema
            // validation error this throws. Fall back to a local-only store
            // rather than crashing the app; fix the schema to restore sync.
            print("CloudKit-backed ModelContainer failed, falling back to local-only store: \(error)")
            do {
                return try ModelContainerConfiguration.makeContainer(cloudKitEnabled: false)
            } catch {
                fatalError("Failed to create local-only ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
                .environment(navigator)
                .environment(alarmMonitor)
                .modelContainer(modelContainer)
                .preferredColorScheme(themeManager.current.isDark ? .dark : .light)
                .onAppear {
                    DefaultsKeys.registerDefaults()
                    AppDependencyManager.shared.add(dependency: navigator as any TimerLaunching)
                    AppDependencyManager.shared.add(dependency: modelContainer)
                    alarmMonitor.start(modelContainer: modelContainer)
                    Task { await HabitCoach.shared.prewarm() }
                }
        }
    }
}
