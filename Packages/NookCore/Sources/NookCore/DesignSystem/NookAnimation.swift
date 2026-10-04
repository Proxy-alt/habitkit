// MARK: - NookAnimation

/// Motion tokens, described as springs by perceptual duration and bounce.
///
/// Values match the previous HabitNookUI `spring(response:dampingFraction:)`
/// presets: duration equals response and bounce equals `1 - dampingFraction`.
/// NookUI swaps each spring for a short crossfade when Reduce Motion is on.
public enum NookAnimation: String, CaseIterable, Sendable {

    /// Most state changes.
    case standard

    /// Taps and completions.
    case quick

    /// Page transitions and celebrations.
    case slow

    /// Perceptual duration of the spring, in seconds.
    public var durationSeconds: Double {
        switch self {
        case .standard: 0.35
        case .quick: 0.25
        case .slow: 0.5
        }
    }

    /// Spring bounce, `0` for no overshoot.
    public var bounce: Double {
        switch self {
        case .standard: 0.2
        case .quick: 0.25
        case .slow: 0.15
        }
    }

    /// Duration of the crossfade used in place of the spring under Reduce Motion.
    public var reducedMotionDurationSeconds: Double {
        min(durationSeconds, 0.2)
    }
}
