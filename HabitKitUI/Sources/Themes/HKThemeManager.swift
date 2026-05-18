import SwiftUI

// MARK: - HKThemeManager

/// Observable manager that owns the list of available themes and the currently
/// selected theme.
///
/// Themes are loaded from the bundled `catppuccin.json` and an optional
/// community `themes.json` resource. Inject an instance at the app root:
/// ```swift
/// @State private var themeManager = HKThemeManager()
///
/// WindowGroup {
///     ContentView()
///         .environment(themeManager)
///         .environment(\.hkTheme, themeManager.current)
/// }
/// ```
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

    /// Creates a new manager, loads all bundled themes, and restores any
    /// previously persisted theme selection.
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

    /// Makes `theme` the active theme and persists the choice to `UserDefaults`.
    ///
    /// - Parameter theme: The ``HKTheme`` to activate.
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
    ///
    /// - Parameter colorScheme: The current `ColorScheme` from the environment.
    /// - Returns: The ``HKTheme`` appropriate for `colorScheme`.
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
        HKTheme.mocha
    }
}
