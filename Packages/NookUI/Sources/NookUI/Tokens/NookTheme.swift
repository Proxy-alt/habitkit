import NookCore
import SwiftUI

// This is the only NookUI file that constructs a Color from components. The
// STYLE_GUIDE 4 hardcoded-colour CI grep allows NookTheme.swift and nothing else.

// MARK: - Colour conversion

public extension NookRGBA {

    /// The colour as a SwiftUI `Color` in the sRGB colour space.
    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

public extension NookTheme {

    /// The SwiftUI colour for `role`.
    ///
    /// Prefer the `.nook(_:)` shape style inside views; use this for APIs
    /// that take a `Color` rather than a `ShapeStyle`.
    func color(_ role: NookColour) -> Color {
        colors[role].swiftUIColor
    }
}

// MARK: - Environment

public extension EnvironmentValues {

    /// The active theme. Defaults to ``NookTheme/mocha``.
    ///
    /// Set it once near the root with `nookTheme(_:)` or
    /// `nookTheme(light:dark:)` rather than writing the key directly.
    @Entry var nookTheme: NookTheme = .mocha
}

public extension View {

    /// Applies `theme` to this hierarchy and tints controls with its primary colour.
    func nookTheme(_ theme: NookTheme) -> some View {
        environment(\.nookTheme, theme)
            .tint(theme.color(.primary))
    }

    /// Applies `light` or `dark` to follow the system appearance.
    ///
    /// Use this when the person has not picked a theme explicitly.
    func nookTheme(light: NookTheme, dark: NookTheme) -> some View {
        modifier(NookAdaptiveThemeModifier(light: light, dark: dark))
    }
}

// MARK: - NookAdaptiveThemeModifier

private struct NookAdaptiveThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let light: NookTheme
    let dark: NookTheme

    func body(content: Content) -> some View {
        content.nookTheme(colorScheme == .dark ? dark : light)
    }
}
