import NookCore
import SwiftUI

public extension NookAnimation {

    /// The SwiftUI animation for this token.
    ///
    /// - Parameter reduceMotion: Pass `accessibilityReduceMotion` from the
    ///   environment. When `true` the spring becomes a short crossfade.
    func swiftUIAnimation(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .easeInOut(duration: reducedMotionDurationSeconds)
            : .spring(duration: durationSeconds, bounce: bounce)
    }
}

/// `withAnimation` for a motion token, honouring Reduce Motion.
///
/// ```swift
/// @Environment(\.accessibilityReduceMotion) private var reduceMotion
///
/// withNookAnimation(.quick, reduceMotion: reduceMotion) {
///     isCompleted = true
/// }
/// ```
@discardableResult
public func withNookAnimation<Result>(
    _ token: NookAnimation,
    reduceMotion: Bool,
    _ body: () throws -> Result
) rethrows -> Result {
    try withAnimation(token.swiftUIAnimation(reduceMotion: reduceMotion), body)
}

public extension View {

    /// Animates changes to `value` with a motion token, honouring Reduce Motion.
    func nookAnimation(_ token: NookAnimation, value: some Equatable) -> some View {
        modifier(NookAnimationModifier(token: token, value: value))
    }
}

// MARK: - NookAnimationModifier

private struct NookAnimationModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let token: NookAnimation
    let value: Value

    func body(content: Content) -> some View {
        content.animation(token.swiftUIAnimation(reduceMotion: reduceMotion), value: value)
    }
}
