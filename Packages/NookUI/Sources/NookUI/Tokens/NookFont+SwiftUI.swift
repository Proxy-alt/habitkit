import NookCore
import SwiftUI

public extension NookFont {

    /// The token as a Dynamic Type SwiftUI font.
    var swiftUIFont: Font {
        .system(textStyle.swiftUITextStyle, design: design.swiftUIDesign, weight: weight.swiftUIWeight)
    }
}

public extension Font {

    /// The font for a typography token: `.font(.nook(.headline))`.
    static func nook(_ token: NookFont) -> Font {
        token.swiftUIFont
    }
}

// MARK: - Supporting conversions

extension NookTextStyle {
    var swiftUITextStyle: Font.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption
        case .caption2: .caption2
        }
    }
}

extension NookFontWeight {
    var swiftUIWeight: Font.Weight {
        switch self {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        }
    }
}

extension NookFontDesign {
    var swiftUIDesign: Font.Design {
        switch self {
        case .standard: .default
        case .rounded: .rounded
        case .monospaced: .monospaced
        case .serif: .serif
        }
    }
}
