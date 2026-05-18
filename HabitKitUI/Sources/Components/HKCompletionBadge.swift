import SwiftUI

// MARK: - HKCompletionBadge

/// A tappable checkmark badge that toggles between completed and incomplete
/// states with a spring scale animation.
///
/// Usage:
/// ```swift
/// HKCompletionBadge(isCompleted: habit.isDoneToday) {
///     habit.toggleToday()
/// }
/// ```
public struct HKCompletionBadge: View {

    // MARK: Dependencies

    @Environment(HKThemeManager.self) private var themeManager

    // MARK: Properties

    private let isCompleted: Bool
    private let size: CGFloat
    private let onTap: () -> Void

    // MARK: Init

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
            onTap()
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
                        .font(.system(size: size * 0.45, weight: .bold))
                        .foregroundStyle(themeManager.current.baseColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
        }
        .buttonStyle(.plain)
        .scaleEffect(isCompleted ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
        .accessibilityLabel(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Double tap to toggle")
        .accessibilityAddTraits(.isButton)
    }
}
