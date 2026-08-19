import SwiftUI

// MARK: - HKTheme

/// A complete HabitKit visual theme, loaded from JSON.
///
/// Themes are value types and are safe to pass across concurrency boundaries.
/// Use ``HKThemeManager`` to load and switch themes at runtime, or access the
/// active theme directly via the `\.hkTheme` environment key:
/// ```swift
/// @Environment(\.hkTheme) private var theme
/// ```
public struct HKTheme: Codable, Identifiable, Hashable, Sendable {

    /// A unique string identifier, e.g. `"catppuccin-mocha"`.
    public let id: String

    /// The human-readable display name of the theme.
    public let name: String

    /// The theme author, or `nil` for built-in themes.
    public let author: String?

    /// `true` when the theme is intended for dark environments.
    public let isDark: Bool

    /// The semantic color palette for this theme.
    public let colors: HKThemeColors
}

// MARK: - HKThemeColors

/// The palette of semantic color hex strings for an ``HKTheme``.
///
/// Each property is a CSS-style hex string (`#RRGGBB` or `#RRGGBBAA`).
/// Resolved `Color` values are available via the corresponding properties on
/// ``HKTheme``, e.g. ``HKTheme/primaryColor``.
public struct HKThemeColors: Codable, Hashable, Sendable {

    /// Hex string for the deepest background surface.
    public let base: String

    /// Hex string for the first-level card / sheet surface.
    public let surface0: String

    /// Hex string for the second-level nested surface.
    public let surface1: String

    /// Hex string for the third-level raised surface.
    public let surface2: String

    /// Hex string for the translucent overlay / separator layer.
    public let overlay0: String

    /// Hex string for primary readable text.
    public let text: String

    /// Hex string for secondary / supporting text.
    public let subtext: String

    /// Hex string for the brand accent used in primary actions.
    public let primary: String

    /// Hex string for destructive or error states.
    public let danger: String

    /// Hex string for completion and success states.
    public let success: String

    /// Hex string for cautionary warning states.
    public let warning: String
}

// MARK: - Resolved Color properties

public extension HKTheme {

    /// The resolved `Color` for the deepest background surface.
    var baseColor: Color     { Color(hex: colors.base)     ?? .clear }

    /// The resolved `Color` for the first-level card surface.
    var surface0Color: Color { Color(hex: colors.surface0) ?? .clear }

    /// The resolved `Color` for the second-level nested surface.
    var surface1Color: Color { Color(hex: colors.surface1) ?? .clear }

    /// The resolved `Color` for the third-level raised surface.
    var surface2Color: Color { Color(hex: colors.surface2) ?? .clear }

    /// The resolved `Color` for the overlay / separator layer.
    var overlay0Color: Color { Color(hex: colors.overlay0) ?? .clear }

    /// The resolved `Color` for primary readable text.
    var textColor: Color     { Color(hex: colors.text)     ?? .clear }

    /// The resolved `Color` for secondary supporting text.
    var subtextColor: Color  { Color(hex: colors.subtext)  ?? .clear }

    /// The resolved `Color` for the brand accent / primary actions.
    var primaryColor: Color  { Color(hex: colors.primary)  ?? .clear }

    /// The resolved `Color` for destructive or error states.
    var dangerColor: Color   { Color(hex: colors.danger)   ?? .clear }

    /// The resolved `Color` for completion and success states.
    var successColor: Color  { Color(hex: colors.success)  ?? .clear }

    /// The resolved `Color` for cautionary warning states.
    var warningColor: Color  { Color(hex: colors.warning)  ?? .clear }
}

// MARK: - Static convenience themes

public extension HKTheme {

    /// The Catppuccin **Mocha** dark theme.
    ///
    /// This is the default theme used when no other theme can be loaded. It is
    /// also injected automatically by the `\.hkTheme` environment key.
    static var mocha: HKTheme {
        loadBuiltIn(id: "catppuccin-mocha") ?? mocheFallback
    }

    /// The Catppuccin **Latte** light theme.
    static var latte: HKTheme {
        loadBuiltIn(id: "catppuccin-latte") ?? latteFallback
    }

    // MARK: Private helpers

    private static func loadBuiltIn(id: String) -> HKTheme? {
        guard
            let url = Bundle.module.url(forResource: "catppuccin", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let themes = try? JSONDecoder().decode([HKTheme].self, from: data)
        else { return nil }
        return themes.first(where: { $0.id == id })
    }

    /// Hardcoded Mocha fallback used when Bundle is unavailable (e.g. unit tests).
    private static var mocheFallback: HKTheme {
        HKTheme(
            id: "catppuccin-mocha",
            name: "Mocha",
            author: nil,
            isDark: true,
            colors: HKThemeColors(
                base:     "#1e1e2e",
                surface0: "#313244",
                surface1: "#45475a",
                surface2: "#585b70",
                overlay0: "#6c7086",
                text:     "#cdd6f4",
                subtext:  "#bac2de",
                primary:  "#cba6f7",
                danger:   "#f38ba8",
                success:  "#a6e3a1",
                warning:  "#fab387"
            )
        )
    }

    /// Hardcoded Latte fallback used when Bundle is unavailable (e.g. unit tests).
    private static var latteFallback: HKTheme {
        HKTheme(
            id: "catppuccin-latte",
            name: "Latte",
            author: nil,
            isDark: false,
            colors: HKThemeColors(
                base:     "#eff1f5",
                surface0: "#ccd0da",
                surface1: "#bcc0cc",
                surface2: "#acb0be",
                overlay0: "#9ca0b0",
                text:     "#4c4f69",
                subtext:  "#5c5f77",
                primary:  "#8839ef",
                danger:   "#d20f39",
                success:  "#40a02b",
                warning:  "#fe640b"
            )
        )
    }
}

// MARK: - EnvironmentKey

private struct HKThemeKey: EnvironmentKey {
    /// Default value is the bundled Mocha theme.
    static let defaultValue: HKTheme = HKTheme.mocha
}

// MARK: - EnvironmentValues extension

public extension EnvironmentValues {
    /// The active ``HKTheme`` injected into the SwiftUI environment.
    ///
    /// Use this key as a lightweight alternative to `@Environment(HKThemeManager.self)`:
    /// ```swift
    /// @Environment(\.hkTheme) private var theme
    /// ```
    /// Set it at the root of your view hierarchy:
    /// ```swift
    /// ContentView()
    ///     .environment(\.hkTheme, themeManager.current)
    /// ```
    var hkTheme: HKTheme {
        get { self[HKThemeKey.self] }
        set { self[HKThemeKey.self] = newValue }
    }
}

// MARK: - Color hex initializer

extension Color {
    /// Parses a CSS-style hex string (`#RGB`, `#RRGGBB`, or `#RRGGBBAA`).
    ///
    /// Returns `nil` if the string cannot be parsed.
    public init?(hex: String) {
        var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("#") { raw = String(raw.dropFirst()) }

        let length = raw.count
        guard length == 3 || length == 6 || length == 8 else { return nil }

        // Expand shorthand #RGB → #RRGGBB
        if length == 3 {
            raw = raw.map { "\($0)\($0)" }.joined()
        }

        guard let value = UInt64(raw, radix: 16) else { return nil }

        let r, g, b, a: Double
        if raw.count == 6 {
            r = Double((value >> 16) & 0xFF) / 255.0
            g = Double((value >> 8)  & 0xFF) / 255.0
            b = Double( value        & 0xFF) / 255.0
            a = 1.0
        } else {
            r = Double((value >> 24) & 0xFF) / 255.0
            g = Double((value >> 16) & 0xFF) / 255.0
            b = Double((value >> 8)  & 0xFF) / 255.0
            a = Double( value        & 0xFF) / 255.0
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
