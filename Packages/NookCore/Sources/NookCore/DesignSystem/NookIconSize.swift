// MARK: - NookIconSize

/// Icon size tokens for SF Symbols.
///
/// Each size is a default that scales with Dynamic Type relative to
/// ``textStyle``, so icons keep their proportion to nearby text.
public enum NookIconSize: String, CaseIterable, Sendable {

    /// 22 pt. Row accessories and badges.
    case sm

    /// 28 pt. Card headers and list cells.
    case md

    /// 48 pt. Section header decoration.
    case lg

    /// 56 pt. Empty-state and feature icons.
    case xl

    /// 64 pt. Oversized empty-state icons.
    case xxl

    /// 72 pt. Celebration hero.
    case hero

    /// Size at the default Dynamic Type setting, in points.
    public var points: Double {
        switch self {
        case .sm: 22
        case .md: 28
        case .lg: 48
        case .xl: 56
        case .xxl: 64
        case .hero: 72
        }
    }

    /// The text style the icon scales alongside.
    public var textStyle: NookTextStyle {
        switch self {
        case .sm, .md: .body
        case .lg, .xl, .xxl, .hero: .largeTitle
        }
    }
}
