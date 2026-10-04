import Foundation
import Testing
@testable import NookCore

@Suite("NookTheme")
struct NookThemeTests {

    /// The HabitNookUI theme files, read from the repository so drift fails here.
    private static let repositoryRoot = URL(filePath: #filePath)
        .deletingLastPathComponent() // DesignSystem
        .deletingLastPathComponent() // NookCoreTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // NookCore
        .deletingLastPathComponent() // Packages
        .deletingLastPathComponent()
    private static let themesDirectory = repositoryRoot.appending(path: "HabitNookUI/Sources/Themes")

    @Test("compiled-in themes match catppuccin.json")
    func builtInsMatchJSON() throws {
        let data = try Data(contentsOf: Self.themesDirectory.appending(path: "Built-in/catppuccin.json"))
        let decoded = try NookTheme.decodeCollection(from: data)
        #expect(decoded == NookTheme.builtIn)
    }

    @Test("decodes the wrapped community themes.json shape")
    func decodesWrappedCollection() throws {
        let data = try Data(contentsOf: Self.themesDirectory.appending(path: "Community/themes.json"))
        let decoded = try NookTheme.decodeCollection(from: data)
        #expect(decoded.map(\.id) == ["nord"])
    }

    @Test("built-in identifiers are unique")
    func uniqueIdentifiers() {
        #expect(Set(NookTheme.builtIn.map(\.id)).count == NookTheme.builtIn.count)
    }

    @Test("encoding then decoding preserves a theme")
    func roundTrips() throws {
        let data = try JSONEncoder().encode([NookTheme.mocha])
        #expect(try NookTheme.decodeCollection(from: data) == [.mocha])
    }

    @Test("palette subscript covers every role")
    func paletteSubscript() {
        let palette = NookTheme.mocha.colors
        #expect(palette[.base] == palette.base)
        #expect(palette[.danger] == palette.danger)
        #expect(Set(NookColour.allCases.map { palette[$0] }).count == NookColour.allCases.count)
    }
}
