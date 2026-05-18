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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
