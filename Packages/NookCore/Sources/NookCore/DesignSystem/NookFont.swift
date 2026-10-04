// MARK: - NookFont

/// Typography tokens.
///
/// Each token names a Dynamic Type text style rather than a point size, so
/// every Nook app scales with the user's text size setting. Fixed point
/// sizes are not offered: they break Larger Text, which the Elderly-3 apps
/// depend on.
public enum NookFont: String, CaseIterable, Sendable {

    /// Screen hero heading. Rounded bold.
    case largeTitle

    /// Screen title. Rounded semibold.
    case title

    /// Section heading. Rounded semibold.
    case headline

    /// Body copy.
    case body

    /// Supporting copy beside body text.
    case callout

    /// Captions and metadata.
    case caption

    /// Fine print and footnotes.
    case footnote

    /// Streaks, counts, and other numbers that should not shift width.
    case mono

    /// The Dynamic Type style the token scales with.
    public var textStyle: NookTextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title2
        case .headline: .headline
        case .body, .mono: .body
        case .callout: .callout
        case .caption: .caption
        case .footnote: .footnote
        }
    }

    public var weight: NookFontWeight {
        switch self {
        case .largeTitle: .bold
        case .title, .headline: .semibold
        case .body, .callout, .caption, .footnote, .mono: .regular
        }
    }

    public var design: NookFontDesign {
        switch self {
        case .largeTitle, .title, .headline: .rounded
        case .mono: .monospaced
        case .body, .callout, .caption, .footnote: .standard
        }
    }
}

// MARK: - Supporting types

/// Dynamic Type text styles, mirroring the platform set.
public enum NookTextStyle: String, CaseIterable, Sendable {
    case largeTitle, title, title2, title3, headline, subheadline
    case body, callout, footnote, caption, caption2
}

public enum NookFontWeight: String, CaseIterable, Sendable {
    case regular, medium, semibold, bold
}

public enum NookFontDesign: String, CaseIterable, Sendable {
    case standard, rounded, monospaced, serif
}
