import NookCore
import SwiftUI

// MARK: - NookColourStyle

/// A shape style that resolves a ``NookColour`` role against the theme in the
/// environment at render time.
///
/// Views do not need to read the theme to colour themselves:
/// ```swift
/// Text(habit.name)
///     .foregroundStyle(.nook(.text))
///     .background(.nook(.surface0), in: .nook(.card))
/// ```
public struct NookColourStyle: ShapeStyle {

    public let role: NookColour

    public init(_ role: NookColour) {
        self.role = role
    }

    public func resolve(in environment: EnvironmentValues) -> Color {
        environment.nookTheme.color(role)
    }
}

public extension ShapeStyle where Self == NookColourStyle {

    /// The theme colour for `role`, resolved from the environment.
    static func nook(_ role: NookColour) -> NookColourStyle {
        NookColourStyle(role)
    }
}
