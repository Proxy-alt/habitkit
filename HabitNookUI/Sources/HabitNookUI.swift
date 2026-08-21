/// HabitNookUI
/// ==========
/// A SwiftUI design-system package for HabitNook, an open-source iOS habit tracker.
///
/// ## Modules
///
/// ### Themes
/// - ``NookTheme`` — value type representing a complete colour palette.
/// - ``NookThemeColors`` — the semantic hex-string palette inside a theme.
/// - ``NookThemeManager`` — observable class that owns theme selection and
///   persistence. Inject it as an environment object at the app root:
///   ```swift
///   @State private var themeManager = NookThemeManager()
///
///   WindowGroup {
///       ContentView()
///           .environment(themeManager)
///           .environment(\.nookTheme, themeManager.current)
///   }
///   ```
/// - ``NookColorRole`` — semantic color role resolved against any ``NookTheme``.
///
/// ### Design Tokens
/// - ``NookFont``: `largeTitle`, `title`, `headline`, `body`, `caption`, `mono`.
/// - ``NookSpacing``: `xs` (4), `sm` (8), `md` (16), `lg` (24), `xl` (32), `xxl` (48).
/// - ``NookRadius``: `sm` (6), `md` (10), `card` (12), `lg` (16), `pill` (999).
/// - ``NookAnimation``: `standard`, `quick`, `slow`.
/// - ``NookSymbol``: SF Symbol name constants for every symbol used in the codebase.
///
/// ### Components
/// - ``NookButton`` — multi-variant themed button (primary / secondary / danger / ghost).
/// - ``NookCard`` — surface-backed rounded card with optional shadow.
/// - ``NookTextField`` — themed text field with label support and focus ring.
/// - ``NookProgressRing`` — animated circular progress ring with optional centre slot.
/// - ``NookCompletionBadge`` — tap-to-toggle completion indicator.
///
/// ## Built-in Themes (Catppuccin)
/// Latte (light), Frappé, Macchiato, Mocha (dark) are bundled in
/// `Sources/Themes/Built-in/catppuccin.json` and loaded automatically.
/// Use `NookTheme.mocha` and `NookTheme.latte` for quick access to the default themes,
/// especially in Xcode Previews:
/// ```swift
/// #Preview {
///     MyView()
///         .environment(\.nookTheme, .mocha)
/// }
/// ```
///
/// ## Swift 6 Concurrency
/// All public types are `Sendable`. `NookThemeManager` is annotated with
/// `@Observable` and is safe to use from the main actor.
import SwiftUI
