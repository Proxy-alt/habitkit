import SwiftUI

// MARK: - HKThemeManager

/// Observable manager that owns the list of available themes and the currently
/// selected theme. Themes are loaded from the bundled catppuccin.json and an
/// optional community themes.json resource.
@Observable
public final class HKThemeManager {

    // MARK: Public state

    /// The theme currently in use.
    public private(set) var current: HKTheme

    /// All themes that were successfully loaded at initialisation.
    public private(set) var available: [HKTheme]

    // MARK: Private constants

    private static let userDefaultsKey = "hk_selected_theme"
    private static let defaultThemeID  = "catppuccin-mocha"
    private static let lightThemeID    = "catppuccin-latte"

    // MARK: Init

    public init() {
        let themes = Self.loadThemes()
        self.available = themes

        // Restore the previously selected theme, or fall back to the default.
        let savedID = UserDefaults.standard.string(forKey: Self.userDefaultsKey)
        let resolved =
            themes.first(where: { $0.id == savedID }) ??
            themes.first(where: { $0.id == Self.defaultThemeID }) ??
            themes.first ??
            HKThemeManager.placeholderTheme()

        self.current = resolved
    }

    // MARK: Public API

    /// Make `theme` the active theme and persist the choice.
    public func select(_ theme: HKTheme) {
        current = theme
        UserDefaults.standard.set(theme.id, forKey: Self.userDefaultsKey)
    }

    /// Returns the appropriate theme for the given colour scheme.
    ///
    /// When no manual selection has been saved the manager automatically
    /// returns the Catppuccin Latte (light) variant for `.light` and the
    /// current dark theme for `.dark`. Once the user has explicitly picked a
    /// theme that selection is honoured regardless of colour scheme.
    public func theme(for colorScheme: ColorScheme) -> HKTheme {
        let hasManualSelection =
            UserDefaults.standard.string(forKey: Self.userDefaultsKey) != nil

        if !hasManualSelection, colorScheme == .light {
            return available.first(where: { $0.id == Self.lightThemeID }) ?? current
        }
        return current
    }

    // MARK: Private helpers

    private static func loadThemes() -> [HKTheme] {
        var themes: [HKTheme] = []

        // Load the built-in Catppuccin bundle.
        if let catppuccin = loadJSON(named: "catppuccin") {
            themes.append(contentsOf: catppuccin)
        }

        // Optionally load community themes (not required to be present).
        if let community = loadJSON(named: "themes") {
            // Avoid duplicating IDs that are already present.
            let existingIDs = Set(themes.map(\.id))
            let fresh = community.filter { !existingIDs.contains($0.id) }
            themes.append(contentsOf: fresh)
        }

        return themes
    }

    private static func loadJSON(named name: String) -> [HKTheme]? {
        guard
            let url = Bundle.module.url(forResource: name, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }

        return try? JSONDecoder().decode([HKTheme].self, from: data)
    }

    /// A safe fallback used only when the bundle contains no theme data at all.
    private static func placeholderTheme() -> HKTheme {
        HKTheme(
            id: "catppuccin-mocha",
            name: "Mocha",
            author: nil,
            isDark: true,
            colors: HKThemeColors(
                base:     "#1e1e2e",
                surface0: "#313244",
                surface1: "#45475a",
                surface2: "#585b70",
                overlay0: "#6c7086",
                text:     "#cdd6f4",
                subtext:  "#bac2de",
                primary:  "#cba6f7",
                danger:   "#f38ba8",
                success:  "#a6e3a1",
                warning:  "#fab387"
            )
        )
    }
}
