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
        // NSPersistentCloudKitContainer's CloudKit mirroring setup runs on a
        // background queue and traps the process (SIGTRAP, not a catchable
        // Swift error) when the process lacks the icloud-services
        // entitlement — which every unsigned debug build does. Check
        // `ubiquityIdentityToken` first: Apple's own docs call it safe to
        // read synchronously at launch, and it's nil whenever iCloud/the
        // entitlement isn't actually usable, letting us skip straight to
        // the local-only store instead of crashing.
        guard FileManager.default.ubiquityIdentityToken != nil else {
            print("No iCloud identity available (unsigned build or no signed-in account) — using local-only store.")
            return Self.makeLocalOnlyContainerOrFatalError()
        }

        do {
            return try ModelContainerConfiguration.makeContainer(cloudKitEnabled: true)
        } catch {
            print("CloudKit-backed ModelContainer failed, falling back to local-only store: \(error)")
            return Self.makeLocalOnlyContainerOrFatalError()
        }
    }()

    private static func makeLocalOnlyContainerOrFatalError() -> ModelContainer {
        do {
            return try ModelContainerConfiguration.makeContainer(cloudKitEnabled: false)
        } catch {
            fatalError("Failed to create local-only ModelContainer: \(error)")
        }
    }

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
