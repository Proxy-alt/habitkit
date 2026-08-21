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

    @Environment(NookThemeManager.self) private var themeManager

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
            .padding(NookSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: NookRadius.card, style: .continuous)
                    .fill(themeManager.current.surface0Color)
                    .shadow(
                        color: showShadow
                            ? Color.black.opacity(themeManager.current.isDark ? 0.4 : 0.12)
                            : .clear,
                        radius: showShadow ? 8 : 0,
                        x: 0,
                        y: showShadow ? 4 : 0
                    )
            )
    }
}

// MARK: - Preview

#Preview("NookCard — with and without shadow") {
    @Previewable @State var themeManager = NookThemeManager()

    VStack(spacing: NookSpacing.lg) {
        NookCard(shadow: true) {
            VStack(alignment: .leading, spacing: NookSpacing.xs) {
                Text("Card with Shadow")
                    .font(NookFont.headline)
                Text("Supporting detail text goes here.")
                    .font(NookFont.body)
            }
        }

        NookCard(shadow: false) {
            VStack(alignment: .leading, spacing: NookSpacing.xs) {
                Text("Card without Shadow")
                    .font(NookFont.headline)
                Text("Supporting detail text goes here.")
                    .font(NookFont.body)
            }
        }
    }
    .padding(NookSpacing.md)
    .background(themeManager.current.baseColor)
    .environment(themeManager)
}
