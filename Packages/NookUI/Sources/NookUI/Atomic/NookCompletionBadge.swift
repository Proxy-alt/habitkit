import NookCore
import SwiftUI

// MARK: - NookCompletionBadge

/// A tappable checkmark badge that toggles between completed and incomplete
/// states with a spring scale animation, or a crossfade under Reduce Motion.
///
/// Usage:
/// ```swift
/// NookCompletionBadge(isCompleted: habit.isDoneToday) {
///     habit.toggleToday()
/// }
/// ```
public struct NookCompletionBadge: View {

    // MARK: Dependencies

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Properties

    /// Whether the habit is currently marked as complete.
    private let isCompleted: Bool

    /// The diameter of the badge in points.
    private let size: CGFloat

    /// The closure invoked when the badge is tapped.
    private let onTap: () -> Void

    // MARK: Init

    /// Creates a new completion badge.
    ///
    /// - Parameters:
    ///   - isCompleted: The current completion state.
    ///   - size: Diameter of the badge in points. Defaults to `28`.
    ///   - onTap: The closure invoked when the badge is tapped.
    public init(
        isCompleted: Bool,
        size: CGFloat = 28,
        onTap: @escaping () -> Void
    ) {
        self.isCompleted = isCompleted
        self.size        = size
        self.onTap       = onTap
    }

    // MARK: Body

    public var body: some View {
        Button(action: {
            withNookAnimation(.quick, reduceMotion: reduceMotion) {
                onTap()
            }
        }) {
            ZStack {
                Circle()
                    .fill(.nook(.success))
                    .opacity(isCompleted ? 1 : 0)
                    .frame(width: size, height: size)

                Circle()
                    .stroke(.nook(isCompleted ? .success : .overlay0), lineWidth: 2)
                    .frame(width: size, height: size)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(.body, weight: .bold))
                        .scaleEffect(size / 28)
                        .foregroundStyle(.nook(.base))
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }
            }
            .nookAnimation(.quick, value: isCompleted)
        }
        .buttonStyle(.borderless)
        .scaleEffect(isCompleted ? 1.0 : 0.95)
        .nookAnimation(.quick, value: isCompleted)
        .accessibilityLabel(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Double tap to toggle")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("NookCompletionBadge -- complete and incomplete") {
    @Previewable @State var isCompleted = false

    HStack(spacing: NookSpacing.xl.value) {
        VStack(spacing: NookSpacing.sm.value) {
            NookCompletionBadge(isCompleted: false, size: 36) {}
            Text("Incomplete")
                .font(.nook(.caption))
                .foregroundStyle(.nook(.subtext))
        }

        VStack(spacing: NookSpacing.sm.value) {
            NookCompletionBadge(isCompleted: true, size: 36) {}
            Text("Complete")
                .font(.nook(.caption))
                .foregroundStyle(.nook(.subtext))
        }

        VStack(spacing: NookSpacing.sm.value) {
            NookCompletionBadge(isCompleted: isCompleted, size: 36) {
                isCompleted.toggle()
            }
            Text("Tap me")
                .font(.nook(.caption))
                .foregroundStyle(.nook(.subtext))
        }
    }
    .padding(.lg)
    .background(.nook(.base))
    .nookTheme(.mocha)
}
