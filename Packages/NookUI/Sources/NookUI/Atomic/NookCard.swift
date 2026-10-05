import NookCore
import SwiftUI

// MARK: - NookCard

/// A themed card container with a surface background, rounded corners and
/// optional drop shadow.
///
/// Usage:
/// ```swift
/// NookCard {
///     Text("Hello, HabitNook")
/// }
/// ```
public struct NookCard<Content: View>: View {

    // MARK: Dependencies

    @Environment(\.nookTheme) private var theme

    // MARK: Properties

    private let showShadow: Bool
    private let content: Content

    // MARK: Init

    /// Creates a new card container.
    ///
    /// - Parameters:
    ///   - shadow: Whether to render a drop shadow beneath the card. Defaults to `true`.
    ///   - content: The view content displayed inside the card.
    public init(
        shadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.showShadow = shadow
        self.content    = content()
    }

    // MARK: Body

    public var body: some View {
        content
            .padding(.md)
            .background(
                RoundedRectangle.nook(.card)
                    .fill(.nook(.surface0))
                    .shadow(
                        color: showShadow
                            ? Color.black.opacity(theme.isDark ? 0.4 : 0.12)
                            : .clear,
                        radius: showShadow ? 8 : 0,
                        x: 0,
                        y: showShadow ? 4 : 0
                    )
            )
    }
}

// MARK: - Preview

#Preview("NookCard -- with and without shadow") {
    VStack(spacing: NookSpacing.lg.value) {
        NookCard(shadow: true) {
            VStack(alignment: .leading, spacing: NookSpacing.xs.value) {
                Text("Card with Shadow")
                    .font(.nook(.headline))
                Text("Supporting detail text goes here.")
                    .font(.nook(.body))
            }
        }

        NookCard(shadow: false) {
            VStack(alignment: .leading, spacing: NookSpacing.xs.value) {
                Text("Card without Shadow")
                    .font(.nook(.headline))
                Text("Supporting detail text goes here.")
                    .font(.nook(.body))
            }
        }
    }
    .padding(.md)
    .background(.nook(.base))
    .nookTheme(.mocha)
}
