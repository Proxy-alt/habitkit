import CoreFoundation

// MARK: - HKRadius

/// Standardised corner-radius tokens for HabitKitUI.
///
/// Use these constants wherever a corner radius is needed:
/// ```swift
/// RoundedRectangle(cornerRadius: HKRadius.card, style: .continuous)
/// ```
public enum HKRadius {

    /// 6 pt — small elements such as tags and chips.
    public static let sm: CGFloat = 6

    /// 10 pt — medium elements such as text fields and input controls.
    public static let md: CGFloat = 10

    /// 12 pt — cards and modal sheets.
    public static let card: CGFloat = 12

    /// 16 pt — large surfaces and bottom sheets.
    public static let lg: CGFloat = 16

    /// 999 pt — pill / fully-rounded shape.
    public static let pill: CGFloat = 999
}
