// MARK: - NookSpacing

/// Spacing scale for padding and stack gaps, on a 4 pt grid.
public enum NookSpacing: String, CaseIterable, Sendable {

    /// 4 pt. Gap between closely related elements.
    case xs

    /// 8 pt. Icon-to-label gap, small internal padding.
    case sm

    /// 16 pt. Standard content padding.
    case md

    /// 24 pt. Card padding, section separation.
    case lg

    /// 32 pt. Large group spacing.
    case xl

    /// 48 pt. Screen-level vertical rhythm.
    case xxl

    public var points: Double {
        switch self {
        case .xs: 4
        case .sm: 8
        case .md: 16
        case .lg: 24
        case .xl: 32
        case .xxl: 48
        }
    }
}
