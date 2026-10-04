import NookCore
import SwiftUI

public extension NookRadius {

    /// The radius in points.
    var value: CGFloat { CGFloat(points) }
}

public extension Shape where Self == RoundedRectangle {

    /// A continuous rounded rectangle for a radius token: `.clipShape(.nook(.card))`.
    ///
    /// For ``NookRadius/pill`` use `Capsule()` where a shape type is
    /// flexible; this returns a rounded rectangle with a very large radius.
    static func nook(_ radius: NookRadius) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius.value, style: .continuous)
    }
}
