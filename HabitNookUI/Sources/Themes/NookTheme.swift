import NookCore
import NookUI
import SwiftUI

// `NookTheme`, its built-in Catppuccin themes, and the `\.nookTheme`
// environment value now live in NookCore and NookUI. This file keeps the
// old HabitNookUI spellings as deprecated forwards until Phase 4 of
// nookui-design-doc.md 9.

// MARK: - NookThemeColors

/// The palette inside a theme, now ``NookPalette`` with parsed colours.
@available(*, deprecated, renamed: "NookPalette")
public typealias NookThemeColors = NookPalette

// MARK: - Resolved Color properties

public extension NookTheme {

    @available(*, deprecated, message: "Use .nook(.base), or color(.base)")
    var baseColor: Color { color(.base) }

    @available(*, deprecated, message: "Use .nook(.surface0), or color(.surface0)")
    var surface0Color: Color { color(.surface0) }

    @available(*, deprecated, message: "Use .nook(.surface1), or color(.surface1)")
    var surface1Color: Color { color(.surface1) }

    @available(*, deprecated, message: "Use .nook(.surface2), or color(.surface2)")
    var surface2Color: Color { color(.surface2) }

    @available(*, deprecated, message: "Use .nook(.overlay0), or color(.overlay0)")
    var overlay0Color: Color { color(.overlay0) }

    @available(*, deprecated, message: "Use .nook(.text), or color(.text)")
    var textColor: Color { color(.text) }

    @available(*, deprecated, message: "Use .nook(.subtext), or color(.subtext)")
    var subtextColor: Color { color(.subtext) }

    @available(*, deprecated, message: "Use .nook(.primary), or color(.primary)")
    var primaryColor: Color { color(.primary) }

    @available(*, deprecated, message: "Use .nook(.danger), or color(.danger)")
    var dangerColor: Color { color(.danger) }

    @available(*, deprecated, message: "Use .nook(.success), or color(.success)")
    var successColor: Color { color(.success) }

    @available(*, deprecated, message: "Use .nook(.warning), or color(.warning)")
    var warningColor: Color { color(.warning) }
}

// MARK: - Color hex initializer

extension Color {
    /// Parses a CSS-style hex string (`#RGB`, `#RRGGBB`, or `#RRGGBBAA`).
    ///
    /// Returns `nil` if the string cannot be parsed. Used for per-habit
    /// accent colours, which are user data rather than theme tokens.
    public init?(hex: String) {
        guard let colour = NookRGBA(hex: hex) else { return nil }
        self = colour.swiftUIColor
    }
}
