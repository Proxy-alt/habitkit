import Foundation

/// Centralised namespace for all `UserDefaults` keys used by HabitKit.
public enum DefaultsKeys {

    // MARK: - Key constants

    /// Whether iCloud sync is enabled. Default: `true`.
    public static let iCloudSync = "hk_icloud_sync"

    /// Whether haptic feedback is enabled throughout the app. Default: `true`.
    public static let hapticsEnabled = "hk_haptics_enabled"

    /// The identifier of the selected colour theme. Default: `"system"`.
    public static let selectedTheme = "hk_selected_theme"

    /// The notification sound identifier. Default: `"default"`.
    public static let notificationSound = "hk_notification_sound"

    // MARK: - Registration

    /// Registers factory defaults for all HabitKit `UserDefaults` keys.
    ///
    /// Call once at app launch (e.g. in `AppDelegate` or the `@main` struct
    /// `init`). Subsequent calls are safe and have no effect on values that
    /// have already been set by the user.
    public static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            iCloudSync: true,
            hapticsEnabled: true,
            selectedTheme: "system",
            notificationSound: "default"
        ])
    }
}
