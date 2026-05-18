import SwiftUI

// MARK: - HKAnimation

/// Standardised animation presets for HabitKitUI.
///
/// Use these constants instead of raw spring parameters to keep motion
/// consistent across the design system:
/// ```swift
/// withAnimation(HKAnimation.quick) {
///     isCompleted.toggle()
/// }
/// ```
public enum HKAnimation {

    /// Standard interactive animation — used for most state changes.
    ///
    /// Response: 0.35 s · Damping: 0.8
    public static let standard: Animation = .spring(response: 0.35, dampingFraction: 0.8)

    /// Quick feedback animation — used for taps and completions.
    ///
    /// Response: 0.25 s · Damping: 0.75
    public static let quick: Animation = .spring(response: 0.25, dampingFraction: 0.75)

    /// Slow ambient animation — used for page transitions and celebrations.
    ///
    /// Response: 0.5 s · Damping: 0.85
    public static let slow: Animation = .spring(response: 0.5, dampingFraction: 0.85)
}
