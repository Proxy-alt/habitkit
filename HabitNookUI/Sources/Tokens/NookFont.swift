import NookCore
import NookUI
import SwiftUI

// MARK: - Font extension (deprecated aliases)

// The `NookFont` token enum moved to NookCore; `.font(.nook(.headline))` is
// the NookUI spelling. These forwards keep older call sites compiling until
// Phase 4 of nookui-design-doc.md 9 removes them.
public extension Font {

    /// Extra-large display heading -- rounded bold.
    @available(*, deprecated, message: "Use .nook(.largeTitle)")
    static var nookLargeTitle: Font { .nook(.largeTitle) }

    /// Primary screen title -- rounded semibold.
    @available(*, deprecated, message: "Use .nook(.title)")
    static var nookTitle: Font { .nook(.title) }

    /// Section heading -- rounded semibold.
    @available(*, deprecated, message: "Use .nook(.headline)")
    static var nookHeadline: Font { .nook(.headline) }

    /// Standard body copy -- default regular.
    @available(*, deprecated, message: "Use .nook(.body)")
    static var nookBody: Font { .nook(.body) }

    /// Supporting caption text -- default regular.
    @available(*, deprecated, message: "Use .nook(.caption)")
    static var nookCaption: Font { .nook(.caption) }

    /// Monospaced body text -- for streaks, counts, etc.
    @available(*, deprecated, message: "Use .nook(.mono)")
    static var nookMono: Font { .nook(.mono) }
}
