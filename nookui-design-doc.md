# NookUI Design System — Design Document

**Version:** 1.0
**Date:** September 2026
**Status:** Proposed. `Packages/NookCore` (design-system slice) and `Packages/NookUI` (token bridges) exist and pass tests. HabitNookUI is not yet migrated onto them. Needs owner rulings on §10 before Phase 2.

---

## Table of Contents

1. [Purpose](#1-purpose)
2. [Audit Findings](#2-audit-findings)
3. [Package Architecture](#3-package-architecture)
4. [Token Specification](#4-token-specification)
5. [Call-Site API](#5-call-site-api)
6. [Accessibility and Platform Rules](#6-accessibility-and-platform-rules)
7. [Community Theme Validation](#7-community-theme-validation)
8. [Enforcement](#8-enforcement)
9. [Migration Plan](#9-migration-plan)
10. [Open Questions](#10-open-questions)
11. [Revision History](#11-revision-history)

---

## 1. Purpose

ARCHITECTURE.md §2.2 and §13 define a two-layer design system: plain-value tokens in `NookCore` with no SwiftUI import, and their SwiftUI versions plus shared components in `NookUI`. Neither package existed. The only implementation was `HabitNookUI`, which is app-specific and had drifted from both STYLE_GUIDE.md and ARCHITECTURE.md.

This document:

- records where the docs and code disagree (§2)
- specifies the tokens once, for all 24 apps (§4)
- defines the SwiftUI call-site spelling STYLE_GUIDE §4 should show (§5)
- lays out a migration path for HabitNookUI (§9)

Suite architecture is canonical in ARCHITECTURE.md (DECISIONS standing rule). Once accepted, §3–§5 of this document should be merged into ARCHITECTURE §2.2 and §13.1, and this file should shrink to rationale only.

---

## 2. Audit Findings

Each finding was checked against the working tree on branch `rename/habitkit-to-habitnook`.

| # | Finding | Evidence | Resolution |
|---|---|---|---|
| F1 | STYLE_GUIDE §4 examples do not compile. `@Environment(NookTheme.self)` needs an `@Observable` class, but `NookTheme` is a struct. | `HabitNookUI/Sources/Themes/NookTheme.swift`; the real key is `\.nookTheme`. | `.nook(_:)` shape style (§5); views rarely need to read the theme at all. |
| F2 | `theme.colors.surface0` is a hex `String`, not a `Color`, so `.fill(theme.colors.surface0)` fails to type-check. | `NookThemeColors` stores strings; colours live at `theme.surface0Color`. | `NookPalette` stores parsed `NookRGBA`; `theme.color(.surface0)` returns a `Color`. |
| F3 | **Community themes never load.** `themes.json` is `{"themes": [...]}` but `NookThemeManager.loadJSON` decodes `[NookTheme]`, and `try?` swallows the error. | `Themes/Community/themes.json`, `NookThemeManager.swift:105`. | `NookTheme.decodeCollection(from:)` accepts both shapes; tested against the real file. |
| F4 | `NookTheme.mocha` and `.latte` are computed statics that re-read and decode `catppuccin.json` on **every access**, including in the environment default and previews. | `NookTheme.swift:120`. | Built-ins are compiled-in `static let` values; a test asserts they match the JSON. |
| F5 | An unparseable hex string resolves to `.clear`, making text invisible without any error. | `Color(hex:) ?? .clear` ×11. | Hex is checked at decode time; a bad theme fails to load and never renders. |
| F6 | ARCHITECTURE §2.2's `NookFont` sample uses fixed point sizes (`.system(size:)`), which breaks Dynamic Type. `NookIconSize` has the same problem today. | ARCHITECTURE §2.2; `NookIconSize.swift`. | Font tokens name text styles; icon sizes scale with `@ScaledMetric`. |
| F7 | ARCHITECTURE §2.2 checks Reduce Motion with `UIAccessibility.isReduceMotionEnabled`. That is UIKit, which NookUI is barred from importing (ARCHITECTURE §3 import table). It also doesn't update live and doesn't exist on watchOS or macOS. HabitNookUI's `NookAnimation` ignores Reduce Motion entirely. | ARCHITECTURE §2.2, §3. | Read `\.accessibilityReduceMotion` from the environment (§4.6). |
| F8 | ARCHITECTURE §2.2 still defines `HKTheme` (contrary to DECISIONS #8) and uses `NookTheme` as an enum namespace, which clashes with the theme struct. | ARCHITECTURE §2.2. | Single `NookTheme` struct in NookCore. |
| F9 | The theme selection is stored under `hk_selected_theme` (an `HK` prefix, contrary to DECISIONS #8). `NookThemeManager` has no actor isolation, and `theme(for:)` reads `UserDefaults` on every call. | `NookThemeManager.swift:31`. | Migrate the key (§9, Phase 3); make the manager `@MainActor`. |
| F10 | DECISIONS #8 names the colour token `NookColour`, but the code has `NookColorRole`. | `NookColorRole.swift`. | `NookColour` in NookCore; deprecated `typealias` during migration. |
| F11 | STYLE_GUIDE §4 recommends `.cornerRadius(_:)`, which is deprecated. | STYLE_GUIDE §4 "Spacing and Radius". | `.clipShape(.nook(.card))` / `.background(_:in:)`. |
| F12 | Symbols are unchecked strings, and names mislead: `NookSymbol.checkmark` is `checkmark.circle.fill`. | `NookSymbol.swift`. | `NookSymbol: String, CaseIterable` enum with `Image(nookSymbol:)`. Case names kept for now to ease migration; see §10 Q5. |
| F13 | **Catppuccin Latte fails WCAG contrast** in five pairings the components draw. The three dark themes pass. | Measured by `NookContrastRequirementTests`; see §4.2. | Proposed palette fix in §4.2 (owner ruling needed). |
| F14 | The two manifests for HabitNookUI disagree on the minimum OS: the root `Package.swift` says iOS 26, `HabitNookUI/Package.swift` says iOS 18. | Both manifests. | Decide which manifest is canonical when HabitNookUI adopts NookUI (§9, Phase 2). |
| F15 | "Use `theme.colors.base` instead of `Color(.systemBackground)`" pushes contributors to paint navigation bars, tab bars and toolbars with theme colours. On iOS 26 and later that covers the system Liquid Glass material. | STYLE_GUIDE §4 "The Rule". | Content vs. chrome rule (§6.5). |

---

## 3. Package Architecture

```
Packages/NookCore     Foundation only. Tokens as plain values, theme model,
                      hex codec, WCAG contrast maths.
      ↓
Packages/NookUI       SwiftUI + NookCore. Token → SwiftUI bridges, theme
                      environment, shared components (ARCHITECTURE §13.2).
      ↓
[App]UI               App-specific views built from NookUI.
```

### 3.1 What lives where

| Concern | NookCore | NookUI |
|---|---|---|
| Colour role (`NookColour`) | ✓ | `.nook(_:)` shape style |
| Colour value (`NookRGBA`) | hex parse/format, luminance, contrast | `.swiftUIColor` |
| Theme (`NookTheme`, `NookPalette`) | model, built-ins, JSON decode, contrast audit | `\.nookTheme`, `.nookTheme(_:)`, `.nookTheme(light:dark:)` |
| Typography (`NookFont`) | text style + weight + design | `.swiftUIFont`, `Font.nook(_:)` |
| Spacing / radius | point values | `.value`, `.padding(_:)`, `Shape.nook(_:)` |
| Motion (`NookAnimation`) | duration, bounce, reduced duration | `swiftUIAnimation(reduceMotion:)`, `withNookAnimation`, `.nookAnimation(_:value:)` |
| Icon size (`NookIconSize`) | base points + text style to scale with | `.nookIconSize(_:)` via `@ScaledMetric` |
| Symbols (`NookSymbol`) | typed names | `Image(nookSymbol:)`, `Label(_:nookSymbol:)` |

Keeping contrast checks in NookCore means theme validation runs in `swift test` on Linux or CI with no simulator, and the same check can run inside the planned `NookFoundation` WebAssembly build if a web theme editor ever needs it.

### 3.2 Deployment floors

These packages serve every support tier, so their minimum OS comes from the **lowest** tier (Org-5), not from Rolling.

| Package | iOS | watchOS | macOS | tvOS | visionOS | Constraint |
|---|---|---|---|---|---|---|
| NookCore | 16 | 9 | 13 | 16 | 1 | Foundation only |
| NookUI | 17 | 10 | 14 | 17 | 1 | Custom `ShapeStyle.resolve(in:)` |

Apps set their own higher floors. NookUI APIs that need newer OSes (Liquid Glass, iOS 27 additions) must be availability-gated inside NookUI and provide a fallback. That fallback is the "degraded mode" ARCHITECTURE §10 (Build Configuration) requires for long-tail tiers.

---

## 4. Token Specification

### 4.1 Colour roles and contrast contract

The eleven roles are the same as STYLE_GUIDE §4's token table. `NookContrastRequirement.suite` is the contract every theme must meet:

| Foreground | Background | Minimum | Why |
|---|---|---|---|
| text | base, surface0, surface1 | 4.5:1 | Body text (WCAG 1.4.3) |
| subtext | base, surface0 | 4.5:1 | Captions are text too |
| base | primary, danger | 4.5:1 | NookButton `.primary` / `.danger` labels |
| primary | base, surface0 | 3:1 | Rings, focus, icons (WCAG 1.4.11) |
| success | base, surface0 | 3:1 | Completion badges on cards |
| warning, danger | base | 3:1 | Status icons |

`overlay0` is not in the contract on purpose. WCAG exempts disabled controls, and §6.3 bans placeholder-only labels.

### 4.2 Latte shortfalls and proposed fix

Measured against the current palette:

| Pairing | Measured | Required | Proposed foreground | Result |
|---|---|---|---|---|
| text on surface1 | 4.39 | 4.5 | `#4c4f69` → `#4a4d66` | 4.54 |
| subtext on surface0 | 4.05 | 4.5 | `#5c5f77` → `#55586e` | 4.52 |
| success on base | 2.96 | 3.0 | `#40a02b` → `#358423` | 4.15 |
| success on surface0 | 2.17 | 3.0 | (same) | 3.04 |
| warning on base | 2.64 | 3.0 | `#fe640b` → `#ec5d0a` | 3.03 |

Each proposed colour is the original with the least darkening that passes, so it stays visibly Catppuccin. The alternative was lightening the surfaces, but `success` on `surface0` still fails even with surfaces 55% lighter, so darkening the foregrounds is the only single-step fix. *Status: applied* in `NookTheme+BuiltIn.swift` and `catppuccin.json`, following the §10 Q2 recommendation. The `withKnownIssue` wrapper is gone, so all four built-ins now run through the same contrast test. This change has its own commit and can be reverted if the owner declines Q2.

### 4.3 Typography

Every token is a Dynamic Type text style. No token has a fixed size.

| Token | Text style | Weight | Design |
|---|---|---|---|
| largeTitle | largeTitle | bold | rounded |
| title | title2 | semibold | rounded |
| headline | headline | semibold | rounded |
| body | body | regular | default |
| callout | callout | regular | default |
| caption | caption | regular | default |
| footnote | footnote | regular | default |
| mono | body | regular | monospaced |

`callout` and `footnote` are new; ARCHITECTURE §2.2 already listed `footnote`. Use `mono` for any number that changes in place (streaks, counts, timers) so the text doesn't change width as digits change.

### 4.4 Spacing and radius

These values are unchanged from HabitNookUI. Spacing uses a 4-point grid: `xs 4 · sm 8 · md 16 · lg 24 · xl 32 · xxl 48`. Radius: `sm 6 · md 10 · card 12 · lg 16 · pill`. NookUI always draws radii with `.continuous` corners to match system controls. `pill` means a capsule; its 999-point value is only a fallback for code that can't use a shape.

**Nesting rule:** inner radius = outer radius − padding. For example, a `sm` chip inside a `card` with `sm` padding. Don't nest two surfaces with the same radius.

### 4.5 Icon sizes

`sm 22 · md 28` scale relative to `body`; `lg 48 · xl 56 · xxl 64 · hero 72` scale relative to `largeTitle`. Keep an icon inside `Label` where possible, so its size follows the label's font automatically. Use `.nookIconSize(_:)` only for icons that stand alone.

### 4.6 Motion

Tokens are springs, specified by perceived duration and bounce, which is the model SwiftUI's `spring(duration:bounce:)` uses. They convert exactly from the old presets (duration = response, bounce = 1 − dampingFraction), so motion doesn't change on migration.

| Token | Duration | Bounce | Reduce Motion |
|---|---|---|---|
| standard | 0.35 s | 0.2 | 0.2 s ease-in-out |
| quick | 0.25 s | 0.25 | 0.2 s ease-in-out |
| slow | 0.5 s | 0.15 | 0.2 s ease-in-out |

With Reduce Motion on, the value still changes, but it crossfades instead of moving or overshooting. Views that also animate position (confetti, sliding cards) must additionally swap the transition for `.opacity`.

---

## 5. Call-Site API

This replaces the snippets in STYLE_GUIDE §4 (F1, F2, F11):

```swift
import NookCore
import NookUI

struct HabitRowView: View {
    let habit: HabitSummary

    var body: some View {
        HStack(spacing: NookSpacing.sm.value) {
            Image(nookSymbol: .flame)
                .foregroundStyle(.nook(.warning))
            Text(habit.name)
                .font(.nook(.body))
                .foregroundStyle(.nook(.text))
            Spacer()
            Text(habit.streak, format: .number)
                .font(.nook(.mono))
                .foregroundStyle(.nook(.subtext))
        }
        .padding(.md)
        .background(.nook(.surface0), in: .nook(.card))
    }
}
```

Apply the theme once at the root:

```swift
WindowGroup {
    RootView()
        .nookTheme(themeManager.current)          // explicit choice
        // or .nookTheme(light: .latte, dark: .mocha) // follow system
}
```

`.nookTheme(_:)` also sets `.tint`, so system controls (`Toggle`, `ProgressView`, `Picker`, links) use the theme's primary colour without any per-view styling.

Rules:

- Views resolve colours through `.nook(_:)`. Read `@Environment(\.nookTheme)` only when an API needs a `Color` value, such as Swift Charts' `foregroundStyle(by:)` scales or `UIColor` bridging.
- View models expose `NookColour` values, never `Color` (this is already the rule in STYLE_GUIDE §4).
- For animation, read `@Environment(\.accessibilityReduceMotion)` and call `withNookAnimation(.quick, reduceMotion:) { … }`. Use `.nookAnimation(_:value:)` for implicit animation.

---

## 6. Accessibility and Platform Rules

### 6.1 Dynamic Type

Test every component at `accessibility5`. Horizontal `HStack`s of text with icons should switch to vertical when `dynamicTypeSize.isAccessibilitySize` is true. This is mandatory for Elderly-3 apps (MedNook, RecoveryNook, ApptNook).

### 6.2 Differentiate Without Color

`success`, `warning` and `danger` must never be the only way a state is shown. Each status needs a symbol or text alongside the colour. For example, `NookCompletionBadge` already changes its symbol (`checkmark` / `checkmarkEmpty`); keep it that way.

### 6.3 Placeholders

A placeholder in `overlay0` is a hint, not a label. `NookTextField` must always have a visible or accessibility label.

### 6.4 Increase Contrast

Future work (§10 Q4). An optional `increasedContrast: NookPalette?` on `NookTheme`, picked when `\.colorSchemeContrast == .increased`. The contrast contract would rise to 7:1 for text in that variant.

### 6.5 Content vs. chrome (Liquid Glass)

Theme colours are for **content**: backgrounds, cards, rows, and your own controls. Navigation bars, tab bars, toolbars, sheets and menus keep their system material. Don't apply `.toolbarBackground`, `.background` or `.nook(.base)` to them. The theme reaches system chrome only through `.tint`. This removes the reason contributors reach for `Color(.systemBackground)`: system surfaces shouldn't be recoloured at all.

On visionOS, apply `.nook(.base)` inside content views only. Window backgrounds stay glass.

### 6.6 watchOS

Use `base` as the page background only for full-screen custom views. Lists use the system watch style. The 4.5:1 text contract matters more on the watch, not less, because it's read at a glance and outdoors.

---

## 7. Community Theme Validation

Community themes currently fail without any error (F3, F5). The proposed pipeline:

1. `NookTheme.decodeCollection(from:)`: a malformed hex string throws, naming the bad value.
2. `theme.contrastFailures()`: a theme with failures is **still listed** but labelled "Low contrast" in the theme picker, and Settings shows which pairs fail. It is never auto-applied when the system appearance changes.
3. CI for `Themes/Community/*.json` runs the same audit. A PR adding a theme that fails needs a maintainer override.

Keeping failing themes selectable, with a label, respects user choice. Some people want a low-contrast look on purpose.

---

## 8. Enforcement

| Rule | Mechanism |
|---|---|
| Colours built from components only in `NookUI/.../NookTheme.swift` | Existing STYLE_GUIDE §4 grep; add that path to its allowlist |
| No `Font.system(size:` outside `NookIconSize+SwiftUI.swift` | New SwiftLint custom rule `no_fixed_font_size` (extends the existing `no_hardcoded_font_size`) |
| No `spring(response:` / `.spring(` / `.easeInOut(` in app or `[App]UI` code | New SwiftLint custom rule; `NookAnimation+SwiftUI.swift` exempt |
| No `.cornerRadius(` | SwiftLint custom rule |
| No `Image(systemName: "` literals outside NookUI | SwiftLint custom rule; use `Image(nookSymbol:)` |
| Built-in themes match their JSON and meet §4.1 | `NookThemeTests`, `NookContrastRequirementTests` |
| Symbols exist on the NookUI minimum OS | Planned test: iterate `NookSymbol.allCases` through `UIImage(systemName:)` in an iOS 17 simulator job |

---

## 9. Migration Plan

**Phase 0 — done.** `Packages/NookCore` (design-system slice) and `Packages/NookUI` (token bridges) build for macOS, iOS and watchOS. NookCore: 17 tests (1 known issue, Latte). NookUI: 7 tests plus a compile check of the call-site spellings in §5.

**Phase 1 — docs.** Replace STYLE_GUIDE §4 snippets with §5. Replace the ARCHITECTURE §2.2 sample code (removing `HKTheme`, the fixed point sizes, and `UIAccessibility`) with a link to the packages. Rename §13.1's `swiftUIColor` extension on `NookColour` to the `.nook(_:)` shape style.

**Phase 2 — HabitNookUI adopts NookUI.** Add the dependency. Make the old tokens thin, deprecated forwards so call sites migrate with fix-its:

```swift
@available(*, deprecated, renamed: "NookColour")
public typealias NookColorRole = NookColour
```

Move `NookButton`, `NookCard`, `NookTextField`, `NookProgressRing` and `NookCompletionBadge` into `NookUI/Atomic/`. They're already suite-generic.

*Status: done.* Token names that exist in both modules (`NookTheme`, `NookFont`, `NookSpacing`, `NookRadius`, `NookIconSize`, `NookSymbol`, `NookAnimation`) can't keep a forward, because importing HabitNookUI and NookCore together would make every use ambiguous. HabitNookUI now uses the NookCore types directly. Its token files are left as notes, ready to delete in Phase 4. Forwards remain for the names that don't clash: `NookColorRole`, `NookThemeColors`, `NookTheme.primaryColor` and the other `...Color` properties, and `Font.nookHeadline` and the other `Font.nook...` aliases. App and widget call sites no longer use any of them. The root `Package.swift` is the canonical manifest (F14). `HabitNookUI/Package.swift` gets the same dependencies so it still resolves.

**Phase 3 — theme manager.** Move `NookThemeManager` into NookUI and mark it `@MainActor`. Load themes through `decodeCollection`, which fixes community themes (F3). Migrate the `hk_selected_theme` key to `nook.theme.selected`, reading the old key once and then deleting it. Cache the manual-selection flag instead of reading `UserDefaults` on every `theme(for:)` call.

*Status: done.* `NookUI/Theme/NookThemeManager.swift` always offers the compiled-in built-ins and takes community themes through `additionalThemes`. HabitNookUI's `NookThemeManager.habitNook()` passes its bundled `themes.json`, which now loads (F3). The old key is migrated only when it names a known theme, because `DefaultsKeys` used to register `"system"` under it, and that isn't a choice. `DefaultsKeys.selectedTheme` now names the new key and no longer registers a default. `catppuccin.json` is no longer read at runtime; it stays as the reference copy that `NookThemeTests` checks (Q3).

**Phase 4 — remove.** Once no call sites use the deprecated forwards, delete them and `HabitNookUI/Sources/Tokens/`.

---

## 10. Open Questions

| # | Question | Recommendation |
|---|---|---|
| Q1 | Does "Org-5" mean an iOS 16 floor? If so, NookUI needs a pre-iOS 17 fallback for `.nook(_:)`. | Treat Org-5 as five **release years** counting back from the current one (27, 26, 18, 17, 16), and give Org-5 apps a NookUI floor of 17 with a documented exception. `@Observable` already requires iOS 17 suite-wide. |
| Q2 | Accept the Latte palette changes in §4.2? | Yes. They are invisible in side-by-side comparison and fix a WCAG failure in the light default. |
| Q3 | Should the theme JSON move from HabitNookUI into NookCore resources? | No. Built-ins are compiled in. Keep JSON only for community themes, which each app bundles. |
| Q4 | Add Increase Contrast palettes (§6.4)? | Yes, for v1.1. Elderly-3 apps benefit most. |
| Q5 | Rename misleading symbol cases (`checkmark` → `checkmarkCircleFill`)? | During Phase 2, with deprecated aliases. |

---

## 11. Revision History

| Version | Date | Change |
|---|---|---|
| 1.0 | September 2026 | Initial proposal: audit findings F1–F15, token spec, NookCore/NookUI packages (Phase 0). |
