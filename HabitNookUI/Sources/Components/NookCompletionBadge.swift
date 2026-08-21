import SwiftUI

// MARK: - NookCompletionBadge

/// A tappable checkmark badge that toggles between completed and incomplete
/// states with a spring scale animation.
///
/// Usage:
/// ```swift
/// NookCompletionBadge(isCompleted: habit.isDoneToday) {
///     habit.toggleToday()
/// }
/// ```
public struct NookCompletionBadge: View {

    // MARK: Dependencies

    @Environment(NookThemeManager.self) private var themeManager

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
            withAnimation(NookAnimation.quick) {
                onTap()
            }
        }) {
            ZStack {
                Circle()
                    .fill(isCompleted
                          ? themeManager.current.successColor
                          : Color.clear)
                    .frame(width: size, height: size)

                Circle()
                    .stroke(
                        isCompleted
                            ? themeManager.current.successColor
                            : themeManager.current.overlay0Color,
                        lineWidth: 2
                    )
                    .frame(width: size, height: size)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(.body, weight: .bold))
                        .scaleEffect(size / 28)
                        .foregroundStyle(themeManager.current.baseColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(NookAnimation.quick, value: isCompleted)
        }
        .buttonStyle(.borderless)
        .scaleEffect(isCompleted ? 1.0 : 0.95)
        .animation(NookAnimation.quick, value: isCompleted)
        .accessibilityLabel(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Double tap to toggle")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("NookCompletionBadge — complete and incomplete") {
    @Previewable @State var themeManager = NookThemeManager()
    @Previewable @State var isCompleted = false

    HStack(spacing: NookSpacing.xl) {
        VStack(spacing: NookSpacing.sm) {
            NookCompletionBadge(isCompleted: false, size: 36) {}
            Text("Incomplete")
                .font(NookFont.caption)
                .foregroundStyle(themeManager.current.subtextColor)
        }

        VStack(spacing: NookSpacing.sm) {
            NookCompletionBadge(isCompleted: true, size: 36) {}
            Text("Complete")
                .font(NookFont.caption)
                .foregroundStyle(themeManager.current.subtextColor)
        }

        VStack(spacing: NookSpacing.sm) {
            NookCompletionBadge(isCompleted: isCompleted, size: 36) {
                isCompleted.toggle()
            }
            Text("Tap me")
                .font(NookFont.caption)
                .foregroundStyle(themeManager.current.subtextColor)
        }
    }
    .padding(NookSpacing.lg)
    .background(themeManager.current.baseColor)
    .environment(themeManager)
}
