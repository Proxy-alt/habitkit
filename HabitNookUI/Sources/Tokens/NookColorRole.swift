import NookCore
import NookUI
import SwiftUI

// MARK: - NookColorRole

/// The semantic colour role, now ``NookColour`` in NookCore (DECISIONS #8).
@available(*, deprecated, renamed: "NookColour")
public typealias NookColorRole = NookColour

public extension NookColour {

    /// Resolves this role to a `Color` using the given theme.
    @available(*, deprecated, message: "Use .nook(role) as a shape style, or theme.color(role)")
    func resolve(in theme: NookTheme) -> Color {
        theme.color(self)
    }
}
