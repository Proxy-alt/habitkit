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
/// - ``NookThemeManager`` -- observable class that owns theme selection and
///   persistence. Inject it at the app root and apply its theme:
///   ```swift
///   @State private var themeManager = NookThemeManager()
///
///   WindowGroup {
///       ContentView()
///           .environment(themeManager)
///           .nookTheme(themeManager.current)
///   }
///   ```
/// - `Themes/Built-in/catppuccin.json` and `Themes/Community/themes.json` --
///   the theme files the manager loads.
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
/// All public types are `Sendable`. `NookThemeManager` is annotated with
/// `@Observable` and is safe to use from the main actor.
import SwiftUI
