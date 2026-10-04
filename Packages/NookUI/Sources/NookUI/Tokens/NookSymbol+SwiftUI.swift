import NookCore
import SwiftUI

public extension Image {

    /// An SF Symbol image for a symbol token.
    init(nookSymbol symbol: NookSymbol) {
        self.init(systemName: symbol.rawValue)
    }
}

public extension Label where Title == Text, Icon == Image {

    /// A label with a localised title and a symbol token.
    init(_ titleKey: LocalizedStringKey, nookSymbol symbol: NookSymbol) {
        self.init(titleKey, systemImage: symbol.rawValue)
    }
}
