// MARK: - NookColour

/// A semantic colour role, resolved against a ``NookTheme`` palette.
///
/// View models pass `NookColour` values, never resolved colours, so the
/// result follows the active theme. `NookUI` resolves roles to SwiftUI
/// colours; this type carries no UI framework dependency.
public enum NookColour: String, CaseIterable, Codable, Sendable {

    // MARK: Surfaces

    /// App background.
    case base

    /// Card and sheet background.
    case surface0

    /// Elevated card, selected row.
    case surface1

    /// Input field background, dividers.
    case surface2

    /// Disabled text, placeholder.
    case overlay0

    // MARK: Text

    /// Primary body text.
    case text

    /// Secondary and caption text.
    case subtext

    // MARK: Semantic

    /// Accent, active controls, progress fill.
    case primary

    /// Completion, positive delta.
    case success

    /// Streak at risk, caution state.
    case warning

    /// Destructive actions, missed habit.
    case danger
}
