import SwiftUI

// MARK: - HKTheme

/// A complete HabitKit visual theme, loaded from JSON.
public struct HKTheme: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let author: String?
    public let isDark: Bool
    public let colors: HKThemeColors
}

// MARK: - HKThemeColors

/// The palette of semantic color hex strings for an HKTheme.
public struct HKThemeColors: Codable, Hashable, Sendable {
    public let base: String
    public let surface0: String
    public let surface1: String
    public let surface2: String
    public let overlay0: String
    public let text: String
    public let subtext: String
    public let primary: String
    public let danger: String
    public let success: String
    public let warning: String
}

// MARK: - Color resolved properties

public extension HKTheme {
    var baseColor: Color     { Color(hex: colors.base)     ?? .clear }
    var surface0Color: Color { Color(hex: colors.surface0) ?? .clear }
    var surface1Color: Color { Color(hex: colors.surface1) ?? .clear }
    var surface2Color: Color { Color(hex: colors.surface2) ?? .clear }
    var overlay0Color: Color { Color(hex: colors.overlay0) ?? .clear }
    var textColor: Color     { Color(hex: colors.text)     ?? .clear }
    var subtextColor: Color  { Color(hex: colors.subtext)  ?? .clear }
    var primaryColor: Color  { Color(hex: colors.primary)  ?? .clear }
    var dangerColor: Color   { Color(hex: colors.danger)   ?? .clear }
    var successColor: Color  { Color(hex: colors.success)  ?? .clear }
    var warningColor: Color  { Color(hex: colors.warning)  ?? .clear }
}

// MARK: - Color hex initializer

extension Color {
    /// Parses a CSS-style hex string (#RGB, #RRGGBB, or #RRGGBBAA).
    init?(hex: String) {
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
