Views instantiate their view models via `@State` and inject dependencies from the environment during initialisation. The `@Observable` model cannot read from the SwiftUI environment during its own `init` -- dependencies must be passed explicitly:

```swift
struct HabitListView: View {
    @Environment(HabitRepository.self) private var repository
    @State private var viewModel: HabitListViewModel

    init() {
        // Placeholder -- actual repository injected in onAppear or via environment
        // See preview fakes section for preview-time injection
        _viewModel = State(wrappedValue: HabitListViewModel())
    }

    var body: some View {
        HabitListContent(viewModel: viewModel)
            .task { await viewModel.inject(repository: repository) }
    }
}
```

For preview and test injection, pass a concrete repository at the call site:

```swift
#Preview {
    HabitListView()
        .environment(PreviewHabitRepository() as HabitRepository)
}
```

Not:

```swift
@StateObject private var viewModel = HabitListViewModel()  // iOS 16 pattern, banned
@ObservedObject var viewModel: HabitListViewModel          // owned elsewhere, banned for primary VM
```

# HabitNook Style Guide

This document is the authoritative reference for all code contributed to the Nook suite. CI enforces the rules marked **[ENFORCED]**. Rules without that label are enforced during code review. PRs that violate enforced rules will not pass CI and will not be merged regardless of feature quality.

For monorepo structure, package boundaries, App Group schema, and cross-app architecture see `ARCHITECTURE.md`.

---

## Table of Contents

1. [Swift Code Style & Formatting](#1-swift-code-style--formatting)
2. [SwiftUI Component Patterns](#2-swiftui-component-patterns)
3. [Architecture Rules](#3-architecture-rules)
4. [Design System & Theme Token Usage](#4-design-system--theme-token-usage)
5. [Git & PR Conventions](#5-git--pr-conventions)
6. [Documentation & Comments](#6-documentation--comments)
7. [Testing Requirements](#7-testing-requirements)

---

## 1. Swift Code Style & Formatting

### Tooling overview

The suite uses two complementary tools with distinct responsibilities:

| Tool | Responsibility | Runs |
|---|---|---|
| **swift-format** | Whitespace, indentation, import ordering, line wrapping | CI on every PR, locally before push |
| **SwiftLint** | Static analysis — logic, safety, custom suite rules | CI on every PR, Xcode build phase locally |

swift-format handles style; SwiftLint handles safety and logic. They do not overlap. Do not configure SwiftLint to enforce formatting rules — that is swift-format's job.

### swift-format **[ENFORCED]**

All Swift source files are formatted with **swift-format** using the `.swift-format` config at the repo root. CI runs `swift-format lint --recursive .` on every PR. A formatting-only diff fails CI.

Run locally before pushing:

```bash
swift-format format --recursive --in-place .
```

Never disable swift-format for a block without a comment explaining why and explicit approval in review.

### SwiftLint **[ENFORCED]**

SwiftLint runs static analysis on every PR via `.swiftlint.yml` at the repo root. Errors fail CI. Warnings do not fail CI but accumulate as review debt — address them before the PR is merged.

Run locally:

```bash
swiftlint lint
swiftlint lint --fix   # auto-correct where possible
```

#### Active opt-in rules

Beyond SwiftLint's default rule set, the following opt-in rules are active:

| Rule | Why |
|---|---|
| `force_unwrapping` | Ban `!` on optionals in production code — already required in §3 |
| `prohibited_interface_builder` | SwiftUI-only codebase |
| `strict_fileprivate` | Prefer `private` over `fileprivate` |
| `toggle_bool` | Use `.toggle()` not `= !value` |
| `vertical_whitespace_closing_braces` | Consistency |

#### Custom suite rules

Four custom rules enforce design doc requirements that have no SwiftLint built-in equivalent:

```yaml
custom_rules:
  no_swiftui_in_nookcore:
    name: "No SwiftUI in NookCore"
    regex: "^import\\s+SwiftUI"
    included: "Packages/NookCore/.*\\.swift"
    message: "NookCore must not import SwiftUI. See ARCHITECTURE.md §2.1."
    severity: error

  no_uikit_in_nookcore:
    name: "No UIKit in NookCore"
    regex: "^import\\s+UIKit"
    included: "Packages/NookCore/.*\\.swift"
    message: "NookCore must not import UIKit. See ARCHITECTURE.md §2.1."
    severity: error

  nonisolated_unsafe_requires_comment:
    name: "nonisolated(unsafe) requires comment"
    regex: "nonisolated\\(unsafe\\)(?!.*//)"
    message: "nonisolated(unsafe) requires a comment. See STYLE_GUIDE.md §4."
    severity: error

  no_banner_comments:
    name: "No banner/divider comments"
    regex: "//\\s*([\\-=\\*]|\\xe2\\x94\\x80)\\1{2,}"
    message: "Use // MARK: - instead of banner comments. See STYLE_GUIDE.md §6."
    severity: warning

  no_emoji_in_comments:
    name: "No emoji in code comments"
    regex: "//.*[\\x{1F300}-\\x{1F9FF}\\x{2600}-\\x{27BF}]"
    message: "Use // GOOD: and // AVOID: instead of emoji. See STYLE_GUIDE.md §6.5."
    severity: warning

  no_non_ascii_in_comments:
    name: "No non-ASCII characters in comments"
    regex: "//.*[^\\x00-\\x7F]"
    message: "Comments must contain only ASCII. Use -- for em dash, -> for arrow, ... for ellipsis. See STYLE_GUIDE.md §6.6."
    severity: warning
```

The full `.swiftlint.yml` lives at the repo root. Do not add `# swiftlint:disable` annotations without a code review from a maintainer and an issue reference. Broad file-level disables are never permitted.

### Naming

Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) strictly. Additions:

- Types: `UpperCamelCase`. No Hungarian notation, no type suffixes on protocols (`Themeable` not `ThemeableProtocol`).
- Variables and functions: `lowerCamelCase`.
- Boolean properties: prefix with `is`, `has`, `can`, `should`, or `allows`. `isCompleted`, not `completed`.
- SwiftData model types: plain noun (`Habit`, `HabitCompletion`), no `Model` suffix.
- SwiftUI views: suffix with `View` only when the name would otherwise collide with a model type (`HabitRowView` vs `Habit`). Do not suffix views that have no collision risk (`TodayTab`, `AnalyticsDashboard`).

### Component Naming Taxonomy

Three tiers with distinct naming conventions:

**Feature views and screens** -- named by intent, no suffix. These are the top-level destinations in the app's navigation hierarchy:
`TodayTab`, `AnalyticsDashboard`, `HabitDetailView`, `SettingsRoot`

**Reusable layout elements** -- suffixed with a structural descriptor when they act as containers or compositional patterns:
`HabitCard`, `StatHeader`, `StreakGrid`, `CompletionRow`

**Atomic elements** -- suffixed with the standard primitive type when they extend or replace a standard SwiftUI control:
`PrimaryButton`, `CompletionRingView`, `NookTextField`, `SeveritySlider`

The tier determines the suffix. If a view is a full screen it has no suffix. If it is a container it gets a layout descriptor. If it replaces a control it gets the control type name. Ambiguous cases belong in code review.
- AppIntent types: suffix with `Intent` (`CompleteHabitIntent`).
- Theme token properties: match the semantic name exactly as defined in `NookTheme` — never abbreviate.

### Access Control

Default to the most restrictive access level that works:

- `private` for implementation details within a file.
- `internal` (implicit) for within-package use.
- `public` only at package API boundaries — types and functions explicitly part of a package's public interface.
- `open` is banned. No HabitNook type is designed for subclassing outside the package.

Mark all SwiftData model properties `internal` unless consumed by another package. Do not expose raw SwiftData context or `ModelContainer` across package boundaries — use repository protocols.

### Immutability

Prefer `let` over `var` everywhere. Use `var` only when mutation is genuinely required. In SwiftUI views, all non-`@State`/`@Binding` properties must be `let`.

### Error Handling

Never use `try!` or `force-unwrap` (`!`) in production code. **[ENFORCED]** SwiftLint's `force_unwrapping` rule (severity: error) fails CI. Exceptions:

- `@IBOutlet` (not applicable — no UIKit) 
- Lazily initialised static constants where the value is guaranteed at compile time — must have a comment explaining why

Handle errors explicitly. Do not use `try?` to silently discard errors unless you have a written comment explaining that the failure case is intentionally ignored and harmless.

```swift
//  // correct
do {
    try context.save()
} catch {
    logger.error("Failed to save context: \(error)")
}

//  // avoid
try? context.save()
```

### Concurrency

All HabitNook code must compile with `SWIFT_STRICT_CONCURRENCY = complete`. **[ENFORCED]**

- Use `async/await`. No `DispatchQueue` usage in new code.
- `@MainActor` on all SwiftUI views and `ObservableObject` view models.
- Isolate SwiftData operations to the `@ModelActor` they belong to. Never access a `ModelContext` from an unstructured task without specifying actor context.
- No `nonisolated(unsafe)` without a code review from a maintainer and a comment explaining the invariant that makes it safe.

### Task Lifecycles in Views

How a view initiates asynchronous work determines whether tasks are correctly cancelled and whether state mutations are safe.

Prefer `.task` for operations tied to a view's lifecycle. The modifier automatically cancels the task when the view disappears, preventing mutations on deallocated state:

```swift
// GOOD: lifecycle-bound, auto-cancelled on disappear
.task {
    await viewModel.loadHabits()
}
```

Use `Task { @MainActor in ... }` inside interactive action closures where the operation must outlive the immediate rendering frame:

```swift
// GOOD: user-initiated action, wraps async call in explicit context
Button("Complete") {
    Task { @MainActor in
        do {
            try await viewModel.complete(habit)
        } catch {
            logger.error("Failed to complete habit: \(error)")
            viewModel.presentError(error)
        }
    }
}
```

Never use `Task.detached` without a documented reason for escaping the current actor context. Always handle errors inside structural tasks with `do-catch` -- an unhandled error escaping a view task is a silent failure.

### Imports

- One import per line.
- No `@testable import` outside test targets.
- Do not import a module just for a single type — if you need one type from `Foundation`, you still import `Foundation`, but do not import `UIKit` anywhere (this is a SwiftUI project).
- Import order: Apple frameworks first, then third-party (none currently), then internal packages. Separate each group with a blank line. swift-format enforces this automatically.

---

## 2. SwiftUI Component Patterns

### View Structure

Every view file contains exactly one primary `View` type. Helper subviews that are only used by that view live in the same file in extensions or as `private` nested types. When a helper view is used by more than one parent, extract it to its own file in `HabitNookUI`.

```swift
// GOOD: single primary view, private subviews in extension
struct HabitRowView: View {
    let habit: Habit
    var body: some View { ... }
}

private extension HabitRowView {
    var completionIndicator: some View { ... }
}

// AVOID: two unrelated primary views in one file
struct HabitRowView: View { ... }
struct HabitCardView: View { ... }  // belongs in its own file
```

### View Model Pattern

Views must not contain business logic. Any logic beyond simple view state belongs in a view model:

- View models are `@Observable` classes (iOS 17+ `Observation` framework, not `ObservableObject`).
- View models are `@MainActor`.
- Views instantiate their view model with `@State private var viewModel = HabitListViewModel()`.
- View models must not import SwiftUI. They may import `HabitNookCore` and `Combine`.
- Never pass a `ModelContext` directly to a view. Views receive display data only.

### Previews

Every view in `HabitNookUI` must have a `#Preview` block.

### Preview Fakes and Test Data

`HabitNookUI` must compile and render previews without importing production engines from `HabitNookCore`. Write lightweight stateless implementations of repository protocols specifically for previews. These live inside `#if DEBUG` blocks within `HabitNookUI` or a dedicated `HabitNookUITestSupport` target -- never in production source:

```swift
#if DEBUG
final class PreviewHabitRepository: HabitRepository {
    var sampleHabits: [Habit] = Habit.sampleData
    func fetchAll() async throws -> [Habit] { sampleHabits }
    func save(_ habit: Habit) async throws {}
    func delete(_ habit: Habit) async throws {}
}

#Preview {
    TodayTab()
        .environment(PreviewHabitRepository())
}
#endif
```

Preview fakes must implement the full protocol -- stub only the methods that are genuinely unused in the preview context. A partial fake that compiles today breaks when the protocol gains a method tomorrow. **[ENFORCED]** CI checks that all public view files contain at least one `#Preview`. Previews must compile and must not crash on launch.

Provide at least two preview variants for any view that has meaningful state variation (empty state, populated state, loading state, etc.).

```swift
#Preview("With habits") {
    HabitListView(viewModel: .preview(habits: .sample))
        .environment(NookTheme.mocha)
}

#Preview("Empty state") {
    HabitListView(viewModel: .preview(habits: []))
        .environment(NookTheme.mocha)
}
```

### State Ownership

- `@State` — view-local ephemeral state (animation triggers, sheet presentation booleans, text field content).
- `@Binding` — state owned by a parent that a child needs to read and write.
- `@Environment` — app-wide values (`NookTheme`, `ModelContext`, custom environment keys).
- `@Query` — SwiftData fetch results. Used only in views, never in view models.
- Never store derived values in `@State`. Compute them from source of truth.

### Complex Derived Data

Where computation lives depends on its cost:

**Lightweight filtering and mapping** -- a computed property directly on the view is acceptable when the input collection is small and the transformation is a single pass:

```swift
// GOOD: simple filter, runs fast, no caching needed
var activeHabits: [Habit] {
    habits.filter { !$0.isArchived }
}
```

**Expensive calculations** -- streak math over hundreds of records, analytics aggregations, sorting by multi-field comparators -- belong on the `@Observable` view model, not in the view body. The view model computes once when source data changes; the view observes the result:

```swift
// GOOD: computed in view model, view just reads
@Observable final class AnalyticsViewModel {
    private(set) var streakSummaries: [StreakSummary] = []

    func refresh(habits: [Habit]) async {
        do {
            streakSummaries = try await Task.detached(priority: .userInitiated) {
                habits.map { StreakCalculator.summary(for: $0) }
            }.value
        } catch {
            logger.error("Failed to compute streak summaries: \(error)")
        }
    }
}
```

Never compute heavy analytical loops directly inside a SwiftUI `body` property. SwiftUI calls `body` on every layout pass -- database queries and O(n²) loops in `body` produce visible frame drops.

### Accessibility

Every interactive element must have an accessibility label. **[ENFORCED]** CI runs the accessibility audit in test builds and fails on unlabelled interactive elements.

```swift
// GOOD: correct button syntax with accessibility label
Button {
    Task { @MainActor in
        do {
            try await viewModel.complete(habit)
        } catch {
            logger.error("Failed to complete habit: \(error)")
            viewModel.presentError(error)
        }
    }
} label: {
    CompletionRingView(progress: habit.progress)
}
.accessibilityLabel("Mark \(habit.name) complete")
.accessibilityHint("Double-tap to log today's completion")

// AVOID: missing accessibilityLabel -- CI accessibility audit will fail
Button {
    Task { @MainActor in
        do {
            try await viewModel.complete(habit)
        } catch {
            logger.error("Failed to complete habit: \(error)")
            viewModel.presentError(error)
        }
    }
} label: {
    CompletionRingView(progress: habit.progress)
}
```

Do not use `.accessibilityHidden(true)` on elements that convey information — only on purely decorative elements.

### Animation

Use `withAnimation` at the call site, not inside the view body. Animation curves must use the project's defined constants in `NookAnimation`, not raw `spring()` or `easeInOut` values, so durations are consistent across the app.

```swift
//  // correct
withAnimation(NookAnimation.standard) {
    isCompleted = true
}

//  // avoid
withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
    isCompleted = true
}
```

---

## 3. Architecture Rules

### Package Boundaries **[ENFORCED]**

The repository contains three Swift packages. Import rules are strict and enforced by `PackageGraph` checks in CI:

| Package | May import | May NOT import |
|---|---|---|
| `HabitNookCore` | Foundation, SwiftData, CloudKit, HealthKit, CoreLocation, CoreMotion | SwiftUI, `HabitNookUI`, `HabitNookIntents` |
| `HabitNookUI` | SwiftUI, `HabitNookCore` | `HabitNookIntents`, HealthKit directly |
| `HabitNookIntents` | AppIntents, `HabitNookCore` | SwiftUI, `HabitNookUI` |

The main app target may import all three packages.

Violating these boundaries — even if it compiles — will be rejected in review. If you believe a boundary needs to change, open a discussion issue before writing code.

### Layering Within HabitNookCore

Within `HabitNookCore`, enforce this layering (outer layers may depend on inner, not the reverse):

```
Models (SwiftData)
    ↓
Repositories (protocol + SwiftData implementation)
    ↓
Services (HealthKit sync, CloudKit, notification scheduling)
    ↓
Public API (typealiases, re-exports, convenience inits)
```

A `Service` may not directly access a `ModelContext` — it goes through a `Repository`. A `Repository` must not call another `Repository` — shared logic goes in a `Model` or a `Service`.

### Dependency Injection

All dependencies are injected. No service locator, no singletons except:

- `Logger` instances (one per subsystem, created at file scope with `let logger = Logger(...)`)
- `ModelContainer` (one per app process, created at app entry point and passed through the environment)

Use protocols at all package boundaries. Concrete types stay within their package. This makes testing possible without live system dependencies.

```swift
// GOOD: HabitNookCore exposes a protocol
public protocol HabitRepository {
    func fetchAll() async throws -> [Habit]
    func save(_ habit: Habit) async throws
}

// AVOID: concrete SwiftData type leaking to UI layer
public final class SwiftDataHabitRepository { ... }
```

### No Business Logic in App Target

The main app target contains:

- `@main` entry point
- `ModelContainer` configuration
- Root environment setup (`NookTheme`, repositories)
- Tab bar / navigation shell

Nothing else. All business logic lives in a package.

---

## 4. Design System & Theme Token Usage

### The Rule **[ENFORCED]**

No hardcoded colors anywhere in the codebase. **Ever.** CI runs a grep for `Color(red:`, `Color(hex:`, `Color(.sRGB`, `UIColor(red:`, and any hex string literal adjacent to a `Color` initialiser. Any match outside of `NookTheme.swift` itself fails the build.

All color usage goes through `NookTheme` semantic tokens:

```swift
//  // correct
Rectangle()
    .fill(theme.colors.surface0)

//  // avoid
Rectangle()
    .fill(Color(hex: "#313244"))

//  // avoid
Rectangle()
    .fill(Color(.systemBackground))  // use theme.colors.base instead
```

### Accessing the Theme

The current theme is injected as an `@Environment` value:

```swift
struct HabitRowView: View {
    @Environment(NookTheme.self) private var theme
    
    var body: some View {
        Text(habit.name)
            .foregroundStyle(theme.colors.text)
            .background(theme.colors.surface0)
    }
}
```

Never store a theme reference in a view model. View models are theme-agnostic. If a view model needs to pass a color to a view, it passes a semantic token name (`NookColorRole`), not a resolved `Color`.

### Token Reference

Use only these semantic tokens. Do not reference Catppuccin palette names (e.g. `mauve`, `flamingo`) directly — always use the semantic role:

| Token | Usage |
|---|---|
| `theme.colors.base` | App background |
| `theme.colors.surface0` | Card / sheet background |
| `theme.colors.surface1` | Elevated card, selected row |
| `theme.colors.surface2` | Input field background, dividers |
| `theme.colors.overlay0` | Disabled text, placeholder |
| `theme.colors.text` | Primary body text |
| `theme.colors.subtext` | Secondary / caption text |
| `theme.colors.primary` | Accent, active controls, progress fill |
| `theme.colors.success` | Completion, positive delta |
| `theme.colors.warning` | Streak at risk, caution state |
| `theme.colors.danger` | Destructive actions, missed habit |

### Typography

Use `NookFont` text styles, not raw `Font` values:

```swift
//  // correct
Text(habit.name).font(NookFont.body)
Text("7-day streak").font(NookFont.caption)

//  // avoid
Text(habit.name).font(.system(size: 16, weight: .medium))
```

### Spacing and Radius

Use `NookSpacing` and `NookRadius` constants. Do not write raw `CGFloat` literals for padding or corner radius values.

```swift
//  // correct
.padding(NookSpacing.md)
.cornerRadius(NookRadius.card)

//  // avoid
.padding(16)
.cornerRadius(12)
```

### Icons

Use SF Symbols only. No bundled image assets for icons. Symbol names are defined as `NookSymbol` string constants — use those, do not inline symbol name strings in views.

```swift
//  // correct
Image(systemName: NookSymbol.checkmark)

//  // avoid
Image(systemName: "checkmark.circle.fill")
```

---

## 5. Git & PR Conventions

### Branch Naming

```
feature/short-description
fix/short-description
chore/short-description
docs/short-description
```

All lowercase, hyphen-separated. No ticket numbers (there is no ticketing system). Branch names must describe what the branch does, not who wrote it.

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/). Format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `style`.

Scopes match package or area: `core`, `ui`, `intents`, `theme`, `widget`, `liveactivity`, `healthkit`, `ci`.

- Description: present tense, lowercase, no period, 72 characters max.
- Body: wrap at 72 characters. Explain *why*, not *what* (the diff shows what).
- Footer: `BREAKING CHANGE:` if the public API changes. `Closes #NNN` for issue references.

```
feat(ui): add swipe-to-complete gesture on habit row

Replaces the tap-only completion with a directional swipe matching
the gesture used in Apple Reminders. Tap still works. The swipe
threshold is defined in NookGesture constants so it can be tuned
without searching the view layer.

Closes #42
```

Do not write commit messages like `fix stuff`, `WIP`, `update`, or `changes`. These will be asked to be rewritten before merge.

### Pull Requests

- One logical change per PR. Do not combine a feature and a refactor in one PR unless the refactor is required to make the feature possible.
- PR title follows the same Conventional Commits format as commit messages.
- PR description must include: what changed, why it changed, how to test it manually, and any screenshots or screen recordings for UI changes.
- All CI checks must pass before requesting review.
- Request at least one review before merging. Maintainers may self-merge documentation-only PRs.
- Squash-merge is the default. Your branch commits are your working history — the squashed commit message is the permanent record. Write it carefully.
- Do not force-push to `main` under any circumstances.

### Release Tagging

Tags follow semver: `v1.0.0`. Release notes are generated from Conventional Commits since the previous tag. `feat` commits increment the minor version, `fix` and `perf` increment the patch version, `BREAKING CHANGE` footer increments the major version.

---

## 6. Documentation & Comments

### What Requires Documentation

All `public` and `internal` declarations in `HabitNookCore` and `HabitNookUI` that form a package boundary must have a doc comment. **[ENFORCED]** CI runs `swift-doc` on public symbols and fails if coverage drops below 90%.

All `public` declarations in `HabitNookIntents` must have a doc comment.

Private implementation details do not require doc comments unless the logic is genuinely non-obvious.

### Doc Comment Format

Use `///` triple-slash, not `/* */` block comments. Use DocC-compatible markup:

```swift
/// Represents a single trackable behaviour the user wants to build or break.
///
/// `Habit` is the root model type stored in SwiftData. Type variants are
/// differentiated via a concrete type enum property, not class inheritance.
/// `Habit` is not `open` and cannot be subclassed outside `HabitNookCore`.
///
/// - Note: Never mutate a `Habit` directly from the UI layer.
///   Use ``HabitRepository`` instead to ensure CloudKit sync triggers correctly.
public class Habit {
    /// The user-facing name of the habit. Maximum 100 characters.
    public var name: String
    
    /// Completes this habit for today, creating a ``HabitCompletion`` record.
    ///
    /// - Parameter note: Optional note to attach to the completion. Defaults to `nil`.
    /// - Throws: ``HabitError/alreadyCompletedToday`` if a completion already exists for today.
    public func complete(note: String? = nil) async throws { ... }
}
```

### Inline Comments

Write inline comments to explain *why*, not *what*. If the code needs a comment to explain what it does, consider renaming or restructuring first.

```swift
// GOOD: explains a non-obvious reason
// AlarmKit requires the trigger to be set at least 5 seconds in the future.
// Subtract 5s from the user's intended time to account for scheduling latency.
let adjustedDate = triggerDate.addingTimeInterval(-5)

// AVOID: restates the code
// Add 1 to the count
count += 1
```

Mark known issues and technical debt with `// TODO:` or `// FIXME:` followed by a GitHub issue number:

```swift
// TODO: #88 — migrate to AlarmKit 2.0 API when seed 3 ships
```

Do not commit `// TODO:` comments without an associated open issue.

### Prohibited Comments

- `// HACK:` without an explanation and an issue reference.
- Commented-out code. Delete it — git history preserves it.
- Comments that are older than the code they describe. If you touch code with a stale comment, update the comment.
- **Banner/divider comments.** [ENFORCED via CI grep]
- **Emoji in code comments.** Use `// GOOD:` and `// AVOID:` instead of `// ✅` and `// ❌`. Use plain text descriptions instead of symbols. See §6.5.
- **Non-ASCII characters in comments or string literals.** [ENFORCED via SwiftLint] See §6.6. Quick reference:

| Avoid | Use instead |
|---|---|
| `—` em dash | `--` or rephrase |
| `–` en dash | `-` |
| `→` Unicode right arrow | `->` |
| `…` Unicode ellipsis | `...` |
| `“` `”` curly quotes | `"` straight quotes |

Banner comments use repeated punctuation characters to create visual separators. They look like any of these:

```swift
// ── Section name ─────────────────────────────────────  // avoid
// === Section name ====================================  // avoid
// --- Section name -----------------------------------  // avoid
// ****************************************************  // avoid
```

**Why they are prohibited:**

They are visually inconsistent by nature — contributors match the length by eye and produce different lengths every time. They are invisible to tooling — Xcode's minimap and swift-format ignore them entirely. They go stale — the section name rarely gets updated when the code it describes changes. They add no semantic information that a properly named type, function, or `// MARK:` cannot convey better.

**Use `// MARK:` instead for file-level section organisation within a single Swift file:**

```swift
// MARK: - Public interface  // correct

// MARK: - Private helpers  // correct

// MARK: - Completion state  // correct
```

`// MARK: -` creates a visible separator in Xcode's jump bar and minimap. It is semantically meaningful, tooling-visible, zero-length, and trivially consistent across contributors.

**Prefer named types and extensions over `// MARK:` sectioning where possible:**

If a type is large enough to need multiple `// MARK:` sections, consider whether the functionality should be split across extensions or separate types instead. `// MARK:` within a file is acceptable. A file with ten `// MARK:` sections is a signal to refactor.

**Doc comments (`///`) are the correct way to describe what a declaration does.** If you are tempted to write a banner comment above a function to explain it, write a `///` doc comment on the function instead.

```swift
// ── Compute the progress fraction for the current period ──────  // avoid

/// Returns the completion fraction (0.0–1.0) for the current period.
///
/// Uses the schedule's `period` and `amount` to determine how many
/// completions exist in the relevant window relative to the target.
func progressFraction(...) -> Double { ... }  // correct
```

---

## 6.5 Emoji Policy

**Avoid emoji in code and in app-facing strings. Use SF Symbols instead.**

Emoji are rendered inconsistently across platforms, operating system versions, and font configurations. An emoji that renders correctly on iOS 26 may render differently or not at all on macOS, in Spotlight, in Siri responses, in notification banners, or in CarPlay. SF Symbols are vector assets that scale correctly at any size, respect the system accent colour, respond to accessibility settings (Dynamic Type, Bold Text, Increased Contrast), and render identically everywhere Apple's frameworks run.

**In code comments:**

```swift
// GOOD: triggers on explicit tap, not during layout
handleTap()

// AVOID: triggers during layout — causes UIKit re-entrance
handleTap()
```

Not:

```swift
// ✅ triggers on explicit tap, not during layout
// ❌ triggers during layout — causes UIKit re-entrance
```

**In app-facing strings:**

Use SF Symbol names rendered via `Image(systemName:)` or `Label`. Never embed emoji characters directly in strings that appear in the UI, Spotlight index, Siri responses, accessibility labels, or notification payloads.

```swift
// GOOD: SF Symbol — scales, tints, respects accessibility
Label("Completed", systemImage: "checkmark.circle.fill")

// GOOD: plain text for strings that must be text-only
detailText: habit.isCompletedToday ? "Done" : "\(habit.streak) day streak"

// AVOID: emoji in UI string
detailText: habit.isCompletedToday ? "✓ Done" : "\(habit.streak) day streak"

// AVOID: emoji in notification payload
UNMutableNotificationContent().body = "🎉 Streak milestone reached"
// Use instead:
UNMutableNotificationContent().body = "Streak milestone reached"
```

**Exceptions — where emoji are permitted:**

- User-generated content. If the user types an emoji in a habit name, note, or completion journal entry, preserve it — it is their data.
- Reaction features. If a future feature adds emoji reactions (e.g., accountability partner reactions), emoji are appropriate there by design.
- Documentation tables. `✅`, `❌`, and `⚠️` in Markdown documentation tables (not code) are acceptable as status indicators — they significantly improve scannability of large transfer and compatibility tables. This exception does not apply to code blocks within documentation.

**In practice:**

The SF Symbol library covers the full range of concepts the Nook suite needs — checkmarks (`checkmark.circle.fill`), warnings (`exclamationmark.triangle`), health (`heart.fill`), streaks (`flame.fill`), completion (`checkmark`), skipping (`forward.fill`). There is no case in the app where an emoji conveys a concept that an SF Symbol cannot.

---

## 6.6 Non-ASCII Characters in Code **[ENFORCED]**

Swift source files must contain only ASCII characters outside of string literals that explicitly require Unicode (e.g. localised user-facing strings). Non-ASCII in comments, identifiers, and operator sequences is prohibited. SwiftLint's `no_non_ascii_in_comments` custom rule enforces this.

**Why this matters:**

Non-ASCII characters that look like ASCII sequences are the most dangerous category. The Unicode right arrow `→` (U+2192) looks identical to Swift's return type operator `->` at most font sizes. An em dash `—` (U+2014) looks identical to two hyphens `--`. Copying from a rendered Markdown preview, a PDF, or a word processor silently substitutes Unicode lookalikes for ASCII. The code appears correct on screen but fails to compile or behaves unexpectedly in stricter environments and cross-platform tooling.

**Required substitutions in Swift source:**

```swift
// AVOID: Unicode lookalikes
func transform() -> Result  // use ASCII -> not Unicode right arrow U+2192
// delay -- apply after layout  // use -- not em dash U+2014
let range = 0.0...1.0  // use ... not Unicode ellipsis U+2026

// GOOD: ASCII throughout
func transform() -> Result
// delay -- apply after layout
let range = 0.0...1.0
```

**Substitution reference:**

| Avoid | Codepoint | Use instead |
|---|---|---|
| `—` em dash | U+2014 | `--` or rephrase the sentence |
| `–` en dash | U+2013 | `-` |
| `→` right arrow | U+2192 | `->` |
| `←` left arrow | U+2190 | `<-` or rephrase |
| `…` ellipsis | U+2026 | `...` |
| `"` `"` curly quotes | U+201C/D | `"` straight double quote |
| `'` `'` curly apostrophes | U+2018/9 | `'` straight single quote |

**Permitted Unicode in Swift source:**

- Localised user-facing string values: `NSLocalizedString("Habitues", ...)` -- Unicode in the string value is correct
- Intentional Unicode escapes: `let arrow = "\u{2192}"` -- intentional and self-documenting
- Raw string literals for regex patterns where Unicode ranges are required

Everything else must be ASCII.

---

## 7. Testing Requirements

### Coverage Minimums **[ENFORCED]**

| Target | Minimum line coverage |
|---|---|
| `HabitNookCore` | 80% |
| `HabitNookUI` | 60% (view models only; views are covered by previews) |
| `HabitNookIntents` | 70% |

CI will fail a PR that reduces coverage below these thresholds in the affected target. Increasing coverage is always welcome.

### Test File Naming and Location

Test files live in the `Tests/` directory of their respective package. Naming: `{TypeUnderTest}Tests.swift`. One test file per type under test.

```
HabitNookCore/
  Sources/
    HabitNookCore/
      Models/Habit.swift
  Tests/
    HabitNookCoreTests/
      Models/HabitTests.swift
```

### Test Structure

Use Swift Testing (`import Testing`), not XCTest, for all new tests. **[ENFORCED]** New XCTest-based test files will not be accepted. Existing XCTest files may remain until they are naturally touched and migrated.

```swift
import Testing
@testable import HabitNookCore

@Suite("Habit completion")
struct HabitCompletionTests {

    @Test("completing a habit creates a completion record for today")
    func completionCreatesRecord() async throws {
        let habit = Habit.preview()
        try await habit.complete()
        #expect(habit.completions.count == 1)
        #expect(Calendar.current.isDateInToday(habit.completions[0].completedAt))
    }

    @Test("completing an already-completed habit throws")
    func doubleCompletionThrows() async throws {
        let habit = Habit.preview()
        try await habit.complete()
        await #expect(throws: HabitError.alreadyCompletedToday) {
            try await habit.complete()
        }
    }
}
```

### What to Test

**Always test:**
- All `HabitNookCore` model methods and service logic
- All repository protocol implementations
- All `AppIntent` `perform()` implementations
- Error paths, not just happy paths
- Boundary conditions (empty collections, nil optionals, date edge cases)

**Do not test:**
- SwiftUI view body directly — use previews for visual verification
- Private implementation details — test through the public interface
- Third-party code or Apple framework behaviour

### Test Data

All test and preview fixtures live in a `Testing` directory within each package target, gated behind `#if DEBUG`. Never use production data shapes in tests. Provide a `.preview()` static factory on model types:

```swift
#if DEBUG
public extension Habit {
    static func preview(
        name: String = "Morning run",
        frequency: HabitFrequency = .daily
    ) -> Habit {
        Habit(name: name, frequency: frequency)
    }
}
#endif
```

### HealthKit and System Dependencies

Tests must not require a live HealthKit store, CloudKit container, or network. All system dependencies must be abstracted behind protocols and replaced with fakes in tests:

```swift
// In HabitNookCore
public protocol HealthStore {
    func requestAuthorization(toShare: Set<HKSampleType>) async throws
    func save(_ sample: HKSample) async throws
}

// In test target
final class FakeHealthStore: HealthStore {
    var savedSamples: [HKSample] = []
    func requestAuthorization(toShare: Set<HKSampleType>) async throws {}
    func save(_ sample: HKSample) async throws { savedSamples.append(sample) }
}
```

---

## Enforcement Summary

| Rule | How enforced |
|---|---|
| Formatting (whitespace, indentation, imports) | CI: `swift-format lint --recursive .` |
| No force-unwrap or `try!` in production | SwiftLint: `force_unwrapping` rule (error) |
| No SwiftUI in NookCore | SwiftLint: `no_swiftui_in_nookcore` custom rule (error) |
| No UIKit in NookCore | SwiftLint: `no_uikit_in_nookcore` custom rule (error) |
| `nonisolated(unsafe)` requires comment | SwiftLint: `nonisolated_unsafe_requires_comment` (error) |
| No banner comments | SwiftLint: `no_banner_comments` (warning) |
| No emoji in code comments | SwiftLint: `no_emoji_in_comments` (warning) |
| No non-ASCII in comments | SwiftLint: `no_non_ascii_in_comments` (warning) |
| Strict concurrency | CI: `SWIFT_STRICT_CONCURRENCY=complete` compiler flag |
| Package import boundaries | CI: PackageGraph check |
| No hardcoded colors | CI: grep for color literals outside `NookTheme.swift` |
| Preview required on all UI views | CI: symbol presence check |
| Accessibility labels on interactive elements | CI: `performAccessibilityAudit()` in test builds |
| Doc comment coverage ≥ 90% on public API | CI: swift-doc |
| Test coverage minimums | CI: `xcodebuild test -enableCodeCoverage YES` |
| No XCTest in new files | Code review |
| Conventional commit messages | Code review |
| One change per PR | Code review |

**Error vs warning:** SwiftLint errors fail CI immediately. Warnings do not fail CI but must be addressed before merge — they accumulate as review debt and block approval if unresolved at review time.

Rules not in this table are enforced during code review. Repeated violations of review-enforced rules may result in a contributor being asked to read this document before their next PR is reviewed.
