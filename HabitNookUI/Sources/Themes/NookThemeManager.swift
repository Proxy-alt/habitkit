import Foundation
import NookCore
import NookUI

// `NookThemeManager` moved to NookUI (nookui-design-doc.md 9, Phase 3). This
// file supplies the HabitNook-specific part: the community themes bundled
// with this package.

public extension NookThemeManager {

    /// A manager offering the built-in themes plus HabitNook's bundled
    /// community themes.
    ///
    /// ```swift
    /// @State private var themeManager = NookThemeManager.habitNook()
    /// ```
    static func habitNook(defaults: UserDefaults = .standard) -> NookThemeManager {
        NookThemeManager(additionalThemes: NookTheme.habitNookCommunity, defaults: defaults)
    }
}

public extension NookTheme {

    /// The community themes in `Themes/Community/themes.json`.
    ///
    /// The file is validated in CI, so a decoding failure is a packaging bug:
    /// it traps in debug builds and yields no community themes in release.
    static var habitNookCommunity: [NookTheme] {
        guard let url = Bundle.module.url(forResource: "themes", withExtension: "json") else {
            return []
        }
        do {
            return try NookTheme.decodeCollection(from: Data(contentsOf: url))
        } catch {
            assertionFailure("Community themes failed to decode: \(error)")
            return []
        }
    }
}
