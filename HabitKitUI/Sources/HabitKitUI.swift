/// HabitKitUI
/// ==========
/// A SwiftUI design-system package for HabitKit, an open-source iOS habit tracker.
///
/// ## Modules
///
/// ### Themes
/// - ``HKTheme`` — value type representing a complete colour palette.
/// - ``HKThemeColors`` — the semantic hex-string palette inside a theme.
/// - ``HKThemeManager`` — observable class that owns theme selection and
///   persistence. Inject it as an environment object at the app root:
///   ```swift
///   @State private var themeManager = HKThemeManager()
///
///   WindowGroup {
///       ContentView()
///           .environment(themeManager)
///           .environment(\.hkTheme, themeManager.current)
///   }
///   ```
/// - ``HKColorRole`` — semantic color role resolved against any ``HKTheme``.
///
/// ### Design Tokens
/// - ``HKFont``: `largeTitle`, `title`, `headline`, `body`, `caption`, `mono`.
/// - ``HKSpacing``: `xs` (4), `sm` (8), `md` (16), `lg` (24), `xl` (32), `xxl` (48).
/// - ``HKRadius``: `sm` (6), `md` (10), `card` (12), `lg` (16), `pill` (999).
/// - ``HKAnimation``: `standard`, `quick`, `slow`.
/// - ``HKSymbol``: SF Symbol name constants for every symbol used in the codebase.
///
/// ### Components
/// - ``HKButton`` — multi-variant themed button (primary / secondary / danger / ghost).
/// - ``HKCard`` — surface-backed rounded card with optional shadow.
/// - ``HKTextField`` — themed text field with label support and focus ring.
/// - ``HKProgressRing`` — animated circular progress ring with optional centre slot.
/// - ``HKCompletionBadge`` — tap-to-toggle completion indicator.
///
/// ## Built-in Themes (Catppuccin)
/// Latte (light), Frappé, Macchiato, Mocha (dark) are bundled in
/// `Sources/Themes/Built-in/catppuccin.json` and loaded automatically.
/// Use `HKTheme.mocha` and `HKTheme.latte` for quick access to the default themes,
/// especially in Xcode Previews:
/// ```swift
/// #Preview {
///     MyView()
///         .environment(\.hkTheme, .mocha)
/// }
/// ```
///
/// ## Swift 6 Concurrency
/// All public types are `Sendable`. `HKThemeManager` is annotated with
/// `@Observable` and is safe to use from the main actor.
import SwiftUI
