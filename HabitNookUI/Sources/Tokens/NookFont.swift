import SwiftUI

// MARK: - NookFont

/// Canonical typography tokens for HabitNookUI.
///
/// Use these static properties wherever a `Font` is required:
/// ```swift
/// Text("Hello")
///     .font(NookFont.body)
/// ```
public enum NookFont {

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
    /// - Note: Prefer ``NookFont/largeTitle`` instead.
    @available(*, deprecated, renamed: "NookFont.largeTitle")
    static var nookLargeTitle: Font { NookFont.largeTitle }

    /// Primary screen title — rounded semibold.
    ///
    /// - Note: Prefer ``NookFont/title`` instead.
    @available(*, deprecated, renamed: "NookFont.title")
    static var nookTitle: Font      { NookFont.title }

    /// Section heading — rounded semibold.
    ///
    /// - Note: Prefer ``NookFont/headline`` instead.
    @available(*, deprecated, renamed: "NookFont.headline")
    static var nookHeadline: Font   { NookFont.headline }

    /// Standard body copy — default regular.
    ///
    /// - Note: Prefer ``NookFont/body`` instead.
    @available(*, deprecated, renamed: "NookFont.body")
    static var nookBody: Font       { NookFont.body }

    /// Supporting caption text — default regular.
    ///
    /// - Note: Prefer ``NookFont/caption`` instead.
    @available(*, deprecated, renamed: "NookFont.caption")
    static var nookCaption: Font    { NookFont.caption }

    /// Monospaced body text — for streaks, counts, etc.
    ///
    /// - Note: Prefer ``NookFont/mono`` instead.
    @available(*, deprecated, renamed: "NookFont.mono")
    static var nookMono: Font       { NookFont.mono }
}
