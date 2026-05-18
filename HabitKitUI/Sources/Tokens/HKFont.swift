import SwiftUI

// MARK: - HKFont

/// Canonical typography tokens for HabitKitUI.
///
/// Use these static properties wherever a `Font` is required:
/// ```swift
/// Text("Hello")
///     .font(HKFont.body)
/// ```
public enum HKFont {

    /// Extra-large display heading — rounded bold.
    public static var largeTitle: Font { .system(.largeTitle, design: .rounded, weight: .bold) }

    /// Primary screen title — rounded semibold.
    public static var title: Font      { .system(.title2, design: .rounded, weight: .semibold) }

    /// Section heading — rounded semibold.
    public static var headline: Font   { .system(.headline, design: .rounded, weight: .semibold) }

    /// Standard body copy — default regular.
    public static var body: Font       { .system(.body, design: .default, weight: .regular) }

    /// Supporting caption text — default regular.
    public static var caption: Font    { .system(.caption, design: .default, weight: .regular) }

    /// Monospaced body text — for streaks, counts, and numeric displays.
    public static var mono: Font       { .system(.body, design: .monospaced, weight: .regular) }
}

// MARK: - Font extension (deprecated aliases)

public extension Font {

    /// Extra-large display heading — rounded bold.
    ///
    /// - Note: Prefer ``HKFont/largeTitle`` instead.
    @available(*, deprecated, renamed: "HKFont.largeTitle")
    static var hkLargeTitle: Font { HKFont.largeTitle }

    /// Primary screen title — rounded semibold.
    ///
    /// - Note: Prefer ``HKFont/title`` instead.
    @available(*, deprecated, renamed: "HKFont.title")
    static var hkTitle: Font      { HKFont.title }

    /// Section heading — rounded semibold.
    ///
    /// - Note: Prefer ``HKFont/headline`` instead.
    @available(*, deprecated, renamed: "HKFont.headline")
    static var hkHeadline: Font   { HKFont.headline }

    /// Standard body copy — default regular.
    ///
    /// - Note: Prefer ``HKFont/body`` instead.
    @available(*, deprecated, renamed: "HKFont.body")
    static var hkBody: Font       { HKFont.body }

    /// Supporting caption text — default regular.
    ///
    /// - Note: Prefer ``HKFont/caption`` instead.
    @available(*, deprecated, renamed: "HKFont.caption")
    static var hkCaption: Font    { HKFont.caption }

    /// Monospaced body text — for streaks, counts, etc.
    ///
    /// - Note: Prefer ``HKFont/mono`` instead.
    @available(*, deprecated, renamed: "HKFont.mono")
    static var hkMono: Font       { HKFont.mono }
}
