import SwiftUI

// MARK: - HKProgressRing

/// A circular progress ring that animates smoothly between values.
///
/// Usage:
/// ```swift
/// HKProgressRing(progress: 0.72) {
///     Text("72%").font(.hkMono)
/// }
/// ```
public struct HKProgressRing<Center: View>: View {

    // MARK: Dependencies

    @Environment(HKThemeManager.self) private var themeManager

    // MARK: Properties

    /// Completion fraction in the range `0.0 ... 1.0`.
    private let progress: Double
    private let lineWidth: CGFloat
    private let size: CGFloat
    private let center: Center

    // MARK: Init — with centre content

    public init(
        progress: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 60,
        @ViewBuilder center: () -> Center
    ) {
        self.progress  = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.size      = size
        self.center    = center()
    }

    // MARK: Body

    public var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(
                    themeManager.current.overlay0Color.opacity(0.3),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Fill
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    themeManager.current.primaryColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)

            // Centre content
            center
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Convenience init with no centre content

public extension HKProgressRing where Center == EmptyView {
    init(
        progress: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 60
    ) {
        self.init(progress: progress, lineWidth: lineWidth, size: size) {
            EmptyView()
        }
    }
}
