import Foundation

// MARK: - NookTheme

/// A complete, named colour theme.
///
/// Themes are plain values: safe to send across actors, compare, and
/// persist. Built-in themes are compiled in (see `NookTheme+BuiltIn.swift`),
/// so reading ``mocha`` never touches the file system.
public struct NookTheme: Codable, Hashable, Identifiable, Sendable {

    /// A stable identifier such as `"catppuccin-mocha"`. Persist this, not the name.
    public let id: String

    /// The display name.
    public let name: String

    /// The author, or `nil` for built-in themes.
    public let author: String?

    /// `true` when the theme is designed for a dark appearance.
    public let isDark: Bool

    /// The colour for every semantic role.
    public let colors: NookPalette

    public init(id: String, name: String, author: String? = nil, isDark: Bool, colors: NookPalette) {
        self.id = id
        self.name = name
        self.author = author
        self.isDark = isDark
        self.colors = colors
    }

    /// Decodes a theme file.
    ///
    /// Accepts both shapes found in the repository: a bare array
    /// (`catppuccin.json`) and an object wrapping a `themes` array
    /// (`themes.json`).
    public static func decodeCollection(from data: Data) throws -> [NookTheme] {
        let decoder = JSONDecoder()
        if let themes = try? decoder.decode([NookTheme].self, from: data) {
            return themes
        }
        return try decoder.decode(Collection.self, from: data).themes
    }

    private struct Collection: Decodable {
        let themes: [NookTheme]
    }
}
