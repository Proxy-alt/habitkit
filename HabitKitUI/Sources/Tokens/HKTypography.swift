import SwiftUI

// MARK: - HabitKit Typography scale

public extension Font {
    /// Extra-large display heading — rounded bold.
    static var hkLargeTitle: Font { .system(.largeTitle, design: .rounded, weight: .bold) }

    /// Primary screen title — rounded semibold.
    static var hkTitle: Font      { .system(.title2,     design: .rounded, weight: .semibold) }

    /// Section heading — rounded semibold.
    static var hkHeadline: Font   { .system(.headline,   design: .rounded, weight: .semibold) }

    /// Standard body copy — default regular.
    static var hkBody: Font       { .system(.body,       design: .default, weight: .regular) }

    /// Supporting caption text — default regular.
    static var hkCaption: Font    { .system(.caption,    design: .default, weight: .regular) }

    /// Monospaced body text — for streaks, counts, etc.
    static var hkMono: Font       { .system(.body,       design: .monospaced, weight: .regular) }
}
