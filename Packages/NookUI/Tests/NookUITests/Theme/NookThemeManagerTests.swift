import Foundation
import NookCore
import SwiftUI
import Testing
@testable import NookUI

@MainActor
@Suite("NookThemeManager")
struct NookThemeManagerTests {

    private let suiteName = "NookThemeManagerTests.\(UUID().uuidString)"

    private func makeDefaults() throws -> UserDefaults {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private static let nord = NookTheme(
        id: "nord", name: "Nord", author: "someone", isDark: true, colors: NookTheme.mocha.colors
    )

    @Test("defaults to Mocha with no manual selection")
    func defaultsToMocha() throws {
        let manager = NookThemeManager(defaults: try makeDefaults())
        #expect(manager.current == .mocha)
        #expect(!manager.hasManualSelection)
        #expect(manager.available == NookTheme.builtIn)
    }

    @Test("appends additional themes and skips duplicate identifiers")
    func additionalThemes() throws {
        let duplicate = NookTheme(id: "catppuccin-mocha", name: "Fake", isDark: true, colors: NookTheme.latte.colors)
        let manager = NookThemeManager(additionalThemes: [Self.nord, duplicate], defaults: try makeDefaults())
        #expect(manager.available == NookTheme.builtIn + [Self.nord])
    }

    @Test("persists a selection under the suite key")
    func persistsSelection() throws {
        let defaults = try makeDefaults()
        NookThemeManager(additionalThemes: [Self.nord], defaults: defaults).select(Self.nord)
        #expect(defaults.string(forKey: NookThemeManager.selectedThemeKey) == "nord")

        let restored = NookThemeManager(additionalThemes: [Self.nord], defaults: defaults)
        #expect(restored.current == Self.nord)
        #expect(restored.hasManualSelection)
    }

    @Test("follows the system appearance until a theme is picked")
    func followsAppearance() throws {
        let manager = NookThemeManager(defaults: try makeDefaults())
        #expect(manager.theme(for: .light) == .latte)
        #expect(manager.theme(for: .dark) == .mocha)

        manager.select(.frappe)
        #expect(manager.theme(for: .light) == .frappe)
    }

    @Test("migrates the legacy hk_selected_theme key once, then deletes it")
    func migratesLegacyKey() throws {
        let defaults = try makeDefaults()
        defaults.set("catppuccin-latte", forKey: NookThemeManager.legacySelectedThemeKey)

        let manager = NookThemeManager(defaults: defaults)
        #expect(manager.current == .latte)
        #expect(manager.hasManualSelection)
        #expect(defaults.string(forKey: NookThemeManager.selectedThemeKey) == "catppuccin-latte")
        #expect(defaults.object(forKey: NookThemeManager.legacySelectedThemeKey) == nil)
    }

    @Test("does not migrate a legacy value that names no theme")
    func ignoresUnknownLegacyValue() throws {
        let defaults = try makeDefaults()
        defaults.set("system", forKey: NookThemeManager.legacySelectedThemeKey)

        let manager = NookThemeManager(defaults: defaults)
        #expect(!manager.hasManualSelection)
        #expect(defaults.string(forKey: NookThemeManager.selectedThemeKey) == nil)
        #expect(defaults.object(forKey: NookThemeManager.legacySelectedThemeKey) == nil)
    }

    @Test("an existing suite key wins over the legacy key")
    func suiteKeyWins() throws {
        let defaults = try makeDefaults()
        defaults.set("catppuccin-frappe", forKey: NookThemeManager.selectedThemeKey)
        defaults.set("catppuccin-latte", forKey: NookThemeManager.legacySelectedThemeKey)

        #expect(NookThemeManager(defaults: defaults).current == .frappe)
        #expect(defaults.object(forKey: NookThemeManager.legacySelectedThemeKey) == nil)
    }
}
