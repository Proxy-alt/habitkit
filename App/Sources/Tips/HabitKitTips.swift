import TipKit

// MARK: - HabitKit Tips (§8.17)

/// Tip shown when the user has 3+ habits but hasn't used the Focus Filter yet.
public struct FocusFilterTip: Tip {
    public static let tipID = "com.habitkit.tip.focusFilter"

    public var title: Text {
        Text("Focus your habits")
    }

    public var message: Text? {
        Text("Connect HabitKit to a Focus Mode to only show relevant habits during Work, Sleep, or Exercise.")
    }

    public var image: Image? {
        Image(systemName: "moon.fill")
    }

    // NOTE: `#Rule` is unusable on this Xcode 27 beta toolchain — its macro
    // expansion drops the closure's enclosing braces regardless of closure
    // syntax, producing "anonymous closure argument not contained in a
    // closure" at every call site. Falling back to no rules (TipKit shows
    // an unconditional tip until dismissed) until the beta bug is fixed.
    public var rules: [Rule] { [] }

    public var options: [any TipOption] {
        [Tips.MaxDisplayCount(1)]
    }

    public init() {}
}

/// Tip shown on first streak milestone (7 days).
public struct StreakMilestoneTip: Tip {
    public static let tipID = "com.habitkit.tip.streakMilestone"

    public var title: Text {
        Text("Keep your streak alive")
    }

    public var message: Text? {
        Text("Tap the 🔥 flame to see your streak calendar and identify the days you're most likely to miss.")
    }

    public var image: Image? {
        Image(systemName: "flame.fill")
    }

    // See NOTE on FocusFilterTip.rules above — `#Rule` is unusable on this
    // beta toolchain.
    public var rules: [Rule] { [] }

    public var options: [any TipOption] {
        [Tips.MaxDisplayCount(2)]
    }

    public init() {}
}

/// Tip shown when the user has never used habit templates.
public struct TemplateTip: Tip {
    public static let tipID = "com.habitkit.tip.template"

    public var title: Text {
        Text("Start faster with templates")
    }

    public var message: Text? {
        Text("Browse the template library to add popular habits in seconds.")
    }

    public var image: Image? {
        Image(systemName: "square.grid.2x2.fill")
    }

    // See NOTE on FocusFilterTip.rules above — `#Rule` is unusable on this
    // beta toolchain.
    public var rules: [Rule] { [] }

    public var options: [any TipOption] {
        [Tips.MaxDisplayCount(1)]
    }

    public init() {}
}

/// Tip shown after the user's first archive export.
public struct ArchiveEncryptionTip: Tip {
    public static let tipID = "com.habitkit.tip.archiveEncryption"

    public var title: Text {
        Text("Encrypt your backups")
    }

    public var message: Text? {
        Text("Enable encryption in Export settings to protect your habit history with your device's Secure Enclave.")
    }

    public var image: Image? {
        Image(systemName: "lock.shield.fill")
    }

    // See NOTE on FocusFilterTip.rules above — `#Rule` is unusable on this
    // beta toolchain.
    public var rules: [Rule] { [] }

    public var options: [any TipOption] {
        [Tips.MaxDisplayCount(1)]
    }

    public init() {}
}

// MARK: - Tip Events

/// Centralised tip event types used in `Rule` closures.
public enum HabitKitTipEvents {
    public static let habitCount = Tips.Event(id: "habitkit.habitCount")
    public static let focusFilterConfigured = Tips.Event(id: "habitkit.focusFilterConfigured")
    public static let streakReached7Days = Tips.Event(id: "habitkit.streakReached7Days")
    public static let streakCalendarViewed = Tips.Event(id: "habitkit.streakCalendarViewed")
    public static let templatesViewed = Tips.Event(id: "habitkit.templatesViewed")
    public static let archiveExported = Tips.Event(id: "habitkit.archiveExported")
    public static let encryptionEnabled = Tips.Event(id: "habitkit.encryptionEnabled")
}
