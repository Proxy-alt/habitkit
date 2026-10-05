/// HabitNookUI
/// ==========
/// App-specific SwiftUI support for HabitNook, an open-source iOS habit tracker.
///
/// ## Modules
///
/// HabitNookUI is being migrated onto the suite packages (nookui-design-doc.md 9).
/// Tokens, the theme model, and the shared components now live in
/// `Packages/NookCore` and `Packages/NookUI`; import those directly.
///
/// ### Themes
/// - `NookThemeManager.habitNook()` -- NookUI's theme manager, offering the
///   built-in themes plus the community themes bundled here. Inject it at the
///   app root and apply its theme:
///   ```swift
///   @State private var themeManager = NookThemeManager.habitNook()
///
///   WindowGroup {
///       ContentView()
///           .environment(themeManager)
///           .nookTheme(themeManager.current)
///   }
///   ```
/// - `Themes/Community/themes.json` -- community themes, loaded with
///   `NookTheme.decodeCollection(from:)`.
/// - `Themes/Built-in/catppuccin.json` -- reference copy of the compiled-in
///   Catppuccin themes; NookCore's tests keep the two in sync.
///
/// ### Deprecated forwards
/// - `NookColorRole` (now `NookColour`), `NookThemeColors` (now `NookPalette`).
/// - `NookTheme.primaryColor` and the other `...Color` properties
///   (now `.nook(.primary)` or `theme.color(.primary)`).
/// - `Font.nookHeadline` and the other `Font.nook...` aliases (now `.nook(.headline)`).
///
/// These are removed in Phase 4, once no call sites use them.
///
/// ## Swift 6 Concurrency
/// `NookThemeManager` is `@MainActor` and `@Observable`.
import SwiftUI
