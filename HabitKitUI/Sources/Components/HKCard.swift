import SwiftUI

// MARK: - HKCard

/// A themed card container with a surface background, rounded corners and
/// optional drop shadow.
///
/// Usage:
/// ```swift
/// HKCard {
///     Text("Hello, HabitKit")
/// }
/// ```
public struct HKCard<Content: View>: View {

    // MARK: Dependencies

    @Environment(HKThemeManager.self) private var themeManager

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
            .padding(HKSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: HKRadius.card, style: .continuous)
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

#Preview("HKCard — with and without shadow") {
    @Previewable @State var themeManager = HKThemeManager()

    VStack(spacing: HKSpacing.lg) {
        HKCard(shadow: true) {
            VStack(alignment: .leading, spacing: HKSpacing.xs) {
                Text("Card with Shadow")
                    .font(HKFont.headline)
                Text("Supporting detail text goes here.")
                    .font(HKFont.body)
            }
        }

        HKCard(shadow: false) {
            VStack(alignment: .leading, spacing: HKSpacing.xs) {
                Text("Card without Shadow")
                    .font(HKFont.headline)
                Text("Supporting detail text goes here.")
                    .font(HKFont.body)
            }
        }
    }
    .padding(HKSpacing.md)
    .background(themeManager.current.baseColor)
    .environment(themeManager)
}
