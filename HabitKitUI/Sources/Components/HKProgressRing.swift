import SwiftUI

// MARK: - HKProgressRing

/// A circular progress ring that animates smoothly between values.
///
/// Usage:
/// ```swift
/// HKProgressRing(progress: 0.72) {
///     Text("72%").font(HKFont.mono)
/// }
/// ```
public struct HKProgressRing<Center: View>: View {

    // MARK: Dependencies

    @Environment(HKThemeManager.self) private var themeManager

    // MARK: Properties

    /// Completion fraction in the range `0.0 ... 1.0`.
    private let progress: Double

    /// The stroke width of both the track and fill arcs.
    private let lineWidth: CGFloat

    /// The outer diameter of the ring in points.
    private let size: CGFloat

    /// Optional view rendered in the centre of the ring.
    private let center: Center

    // MARK: Init — with centre content

    /// Creates a progress ring with custom centre content.
    ///
    /// - Parameters:
    ///   - progress: Completion fraction clamped to `0.0 ... 1.0`.
    ///   - lineWidth: Arc stroke width. Defaults to `8`.
    ///   - size: Outer diameter in points. Defaults to `60`.
    ///   - center: A `ViewBuilder` closure producing the centre content.
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
                .animation(HKAnimation.slow, value: progress)

            // Centre content
            center
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Convenience init with no centre content

public extension HKProgressRing where Center == EmptyView {

    /// Creates a progress ring with no centre content.
    ///
    /// - Parameters:
    ///   - progress: Completion fraction clamped to `0.0 ... 1.0`.
    ///   - lineWidth: Arc stroke width. Defaults to `8`.
    ///   - size: Outer diameter in points. Defaults to `60`.
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

// MARK: - Preview

#Preview("HKProgressRing — 0%, 50%, 100%") {
    @Previewable @State var themeManager = HKThemeManager()

    HStack(spacing: HKSpacing.xl) {
        HKProgressRing(progress: 0.0, size: 70) {
            Text("0%")
                .font(HKFont.caption)
                .foregroundStyle(themeManager.current.subtextColor)
        }

        HKProgressRing(progress: 0.5, size: 70) {
            Text("50%")
                .font(HKFont.caption)
                .foregroundStyle(themeManager.current.textColor)
        }

        HKProgressRing(progress: 1.0, size: 70) {
            Image(systemName: HKSymbol.checkmark)
                .foregroundStyle(themeManager.current.successColor)
        }
    }
    .padding(HKSpacing.lg)
    .background(themeManager.current.baseColor)
    .environment(themeManager)
}
