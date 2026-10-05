import NookCore
import SwiftUI

// MARK: - NookThemeManager

/// Owns the themes an app offers and the one the person has selected.
///
/// The built-in Catppuccin themes are always available. Apps add the
/// community themes they bundle through `additionalThemes`. Create one
/// instance at the app root and apply its theme:
/// ```swift
/// @State private var themeManager = NookThemeManager()
///
/// WindowGroup {
///     ContentView()
///         .environment(themeManager)
///         .nookTheme(themeManager.current)
/// }
/// ```
@MainActor
@Observable
public final class NookThemeManager {

    // MARK: Public state

    /// The theme currently in use.
    public private(set) var current: NookTheme

    /// Every theme the person can pick, built-ins first.
    public private(set) var available: [NookTheme]

    /// `true` once the person has picked a theme. Read once at launch and
    /// then kept in memory, so ``theme(for:)`` never touches `UserDefaults`.
    public private(set) var hasManualSelection: Bool

    // MARK: Persistence

    /// The `UserDefaults` key holding the selected theme's identifier.
    public static let selectedThemeKey = "nook.theme.selected"

    /// The HabitNook key used before the suite-wide rename (DECISIONS #8).
    static let legacySelectedThemeKey = "hk_selected_theme"

    private let defaults: UserDefaults

    // MARK: Init

    /// Creates a manager and restores the persisted selection.
    ///
    /// - Parameters:
    ///   - additionalThemes: Themes beyond the built-ins, such as community
    ///     themes the app bundles. Identifiers already taken are skipped.
    ///   - defaults: Where the selection is stored. Defaults to `.standard`.
    public init(additionalThemes: [NookTheme] = [], defaults: UserDefaults = .standard) {
        var themes = NookTheme.builtIn
        for theme in additionalThemes where !themes.contains(where: { $0.id == theme.id }) {
            themes.append(theme)
        }

        Self.migrateLegacySelection(in: defaults, knownThemes: themes)
        let saved = defaults.string(forKey: Self.selectedThemeKey)
            .flatMap { id in themes.first { $0.id == id } }

        self.defaults = defaults
        self.available = themes
        self.hasManualSelection = saved != nil
        self.current = saved ?? .mocha
    }

    // MARK: Public API

    /// Makes `theme` the active theme and persists the choice.
    public func select(_ theme: NookTheme) {
        current = theme
        hasManualSelection = true
        defaults.set(theme.id, forKey: Self.selectedThemeKey)
    }

    /// The theme to show for `colorScheme`.
    ///
    /// Until the person picks a theme, light appearance gets Latte and dark
    /// appearance gets ``current``. After that, their choice always wins.
    public func theme(for colorScheme: ColorScheme) -> NookTheme {
        if !hasManualSelection, colorScheme == .light {
            return .latte
        }
        return current
    }

    // MARK: Migration

    /// Moves a selection saved under ``legacySelectedThemeKey`` to
    /// ``selectedThemeKey``, then deletes the old key.
    ///
    /// Only an identifier that names a known theme is carried over: the old
    /// key also had a registered default of `"system"`, which is not a choice.
    static func migrateLegacySelection(in defaults: UserDefaults, knownThemes: [NookTheme]) {
        guard let legacyID = defaults.string(forKey: legacySelectedThemeKey) else { return }
        if defaults.string(forKey: selectedThemeKey) == nil,
           knownThemes.contains(where: { $0.id == legacyID }) {
            defaults.set(legacyID, forKey: selectedThemeKey)
        }
        defaults.removeObject(forKey: legacySelectedThemeKey)
    }
}
