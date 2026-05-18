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
///   }
///   ```
///
/// ### Design Tokens
/// - ``Font`` extensions: `hkLargeTitle`, `hkTitle`, `hkHeadline`, `hkBody`,
///   `hkCaption`, `hkMono`.
/// - ``HKSpacing``: `xs` (4), `sm` (8), `md` (16), `lg` (24), `xl` (32),
///   `xxl` (48).
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
///
/// ## Swift 6 Concurrency
/// All public types are `Sendable`. `HKThemeManager` is annotated with
/// `@Observable` and is safe to use from the main actor.
import SwiftUI
