import SwiftUI

// MARK: - HKColorRole

/// A semantic color role that can be resolved against any ``HKTheme``.
///
/// View models and components should pass `HKColorRole` values rather than
/// resolved `Color` instances so that the color adapts automatically when the
/// active theme changes:
/// ```swift
/// let role: HKColorRole = .primary
/// let resolved: Color = role.resolve(in: theme)
/// ```
public enum HKColorRole: String, Sendable, CaseIterable {

    // MARK: Surface roles

    /// The deepest background surface of the theme.
    case base

    /// The first-level surface — cards and sheets.
    case surface0

    /// The second-level surface — nested cards and inputs.
    case surface1

    /// The third-level surface — highlighted or raised elements.
    case surface2

    /// The translucent overlay layer — separators and ghost elements.
    case overlay0

    // MARK: Text roles

    /// Primary readable text color.
    case text

    /// Secondary / supporting text color.
    case subtext

    // MARK: Semantic roles

    /// The theme's brand accent — used for primary actions.
    case primary

    /// A high-urgency color for destructive or error states.
    case danger

    /// A positive color for completions and success states.
    case success

    /// A cautionary color for warnings and pending states.
    case warning

    // MARK: Resolution

    /// Resolves this role to a `Color` using the given theme.
    ///
    /// - Parameter theme: The ``HKTheme`` to resolve against.
    /// - Returns: The `Color` that corresponds to this role in `theme`.
    public func resolve(in theme: HKTheme) -> Color {
        switch self {
        case .base:     return theme.baseColor
        case .surface0: return theme.surface0Color
        case .surface1: return theme.surface1Color
        case .surface2: return theme.surface2Color
        case .overlay0: return theme.overlay0Color
        case .text:     return theme.textColor
        case .subtext:  return theme.subtextColor
        case .primary:  return theme.primaryColor
        case .danger:   return theme.dangerColor
        case .success:  return theme.successColor
        case .warning:  return theme.warningColor
        }
    }
}
