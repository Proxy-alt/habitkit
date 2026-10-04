import NookCore
import SwiftUI

public extension View {

    /// Sizes SF Symbols in this view with an icon token that scales with Dynamic Type.
    ///
    /// ```swift
    /// Image(nookSymbol: .flame)
    ///     .nookIconSize(.md)
    /// ```
    func nookIconSize(_ size: NookIconSize) -> some View {
        modifier(NookIconSizeModifier(size: size))
    }
}

// MARK: - NookIconSizeModifier

private struct NookIconSizeModifier: ViewModifier {
    @ScaledMetric private var points: CGFloat

    init(size: NookIconSize) {
        _points = ScaledMetric(wrappedValue: CGFloat(size.points), relativeTo: size.textStyle.swiftUITextStyle)
    }

    func body(content: Content) -> some View {
        content.font(.system(size: points))
    }
}
