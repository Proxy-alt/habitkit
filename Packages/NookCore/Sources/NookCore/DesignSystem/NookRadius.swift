// MARK: - NookRadius

/// Corner radius tokens. NookUI draws every radius with continuous corners.
public enum NookRadius: String, CaseIterable, Sendable {

    /// 6 pt. Tags and chips.
    case sm

    /// 10 pt. Text fields and inputs.
    case md

    /// 12 pt. Cards and sheets.
    case card

    /// 16 pt. Large surfaces.
    case lg

    /// Fully rounded ends. NookUI renders this as a capsule.
    case pill

    /// The radius in points. `pill` reports a value larger than any control
    /// so that callers without capsule support still get round ends.
    public var points: Double {
        switch self {
        case .sm: 6
        case .md: 10
        case .card: 12
        case .lg: 16
        case .pill: 999
        }
    }
}
