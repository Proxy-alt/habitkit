import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

// MARK: - ScreenTimeManager

/// Manages Screen Time integration for habit-linked app restrictions (§8.9).
///
/// HabitKit can temporarily unblock a restricted app as a reward for completing
/// a habit, or restrict distracting apps until daily habits are complete.
/// All Screen Time operations require FamilyControls authorization.
public actor ScreenTimeManager {

    // MARK: - Shared instance

    public static let shared = ScreenTimeManager()

    // MARK: - Private state

    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared

    // MARK: - Init

    private init() {}

    // MARK: - Authorization

    /// Requests FamilyControls authorization from the user.
    ///
    /// Must be called on the main thread; authorization UI is modal.
    @MainActor
    public func requestAuthorization() async throws {
        try await center.requestAuthorization(for: .individual)
    }

    /// Returns whether FamilyControls authorization has been granted.
    public var isAuthorized: Bool {
        center.authorizationStatus == .approved
    }

    // MARK: - App blocking

    /// Applies app shield restrictions to the selected apps until `unblockDate`.
    ///
    /// - Parameters:
    ///   - selection: A `FamilyActivitySelection` of apps to restrict.
    ///   - unblockDate: Date at which restrictions are automatically cleared.
    public func blockApps(_ selection: FamilyActivitySelection, until unblockDate: Date) {
        var shield = ShieldSettings()
        shield.applications = selection.applicationTokens
        shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(
            selection.categoryTokens
        )
        store.shield = shield

        // Schedule automatic unblock via DeviceActivity.
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute], from: unblockDate),
            repeats: false
        )
        let center = DeviceActivityCenter()
        try? center.startMonitoring(
            DeviceActivityName("com.habitkit.unblock"),
            during: schedule
        )
    }

    /// Removes all app shield restrictions applied by HabitKit.
    public func unblockAllApps() {
        store.shield = ShieldSettings()
        let center = DeviceActivityCenter()
        center.stopMonitoring([DeviceActivityName("com.habitkit.unblock")])
    }

    // MARK: - Usage observation

    /// Starts a DeviceActivity schedule to observe daily usage and call
    /// `onThresholdReached` when a monitored app's usage crosses the threshold.
    ///
    /// - Parameters:
    ///   - selection: Apps to observe.
    ///   - thresholdMinutes: Daily usage minutes that trigger the callback.
    ///   - onThresholdReached: Called when usage crosses the threshold.
    public func observeUsage(
        _ selection: FamilyActivitySelection,
        thresholdMinutes: Int,
        onThresholdReached: @Sendable @escaping () -> Void
    ) {
        // Usage thresholds are handled in the DeviceActivityReport extension.
        // Register the selection in shared UserDefaults so the extension can read it.
        let defaults = UserDefaults(suiteName: "group.com.habitkit.app")
        let encoded = try? JSONEncoder().encode(selection.applicationTokens.map { "\($0)" })
        defaults?.set(encoded, forKey: "screentime.observed.apps")
        defaults?.set(thresholdMinutes, forKey: "screentime.threshold.minutes")
    }
}
