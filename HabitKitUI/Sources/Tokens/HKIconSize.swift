import SwiftUI

/// Semantic icon size tokens for SF Symbol images.
///
/// Use these instead of `.font(.system(size:))` to keep icon scales consistent
/// and refactorable from a single location.
///
/// ```swift
/// Image(systemName: "star.fill")
///     .font(HKIconSize.md)
/// ```
public enum HKIconSize {
    /// 22 pt — small inline icon (row accessory, badge).
    // swiftlint:disable:next no_hardcoded_font_size
    public static let sm: Font = .system(size: 22)

    /// 28 pt — medium icon in a card header or list cell.
    // swiftlint:disable:next no_hardcoded_font_size
    public static let md: Font = .system(size: 28)

    /// 48 pt — large decorative icon in a section header.
    // swiftlint:disable:next no_hardcoded_font_size
    public static let lg: Font = .system(size: 48)

    /// 56 pt — extra-large empty-state or feature icon.
    // swiftlint:disable:next no_hardcoded_font_size
    public static let xl: Font = .system(size: 56)

    /// 64 pt — oversized decorative icon for empty states.
    // swiftlint:disable:next no_hardcoded_font_size
    public static let xxl: Font = .system(size: 64)

    /// 72 pt — hero celebration icon.
    // swiftlint:disable:next no_hardcoded_font_size
    public static let hero: Font = .system(size: 72)
}
