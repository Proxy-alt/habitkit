# HabitKit Style Guide
This document is the authoritative reference for all code contributed to HabitKit. CI enforces the rules marked **[ENFORCED]**. Rules without that label are enforced during code review. PRs that violate enforced rules will not pass CI and will not be merged regardless of feature quality.

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

### Formatter **[ENFORCED]**
All Swift source files are formatted with **swift-format** using the project's `.swift-format` config at the repo root. CI runs `swift-format lint --recursive .` on every PR. A formatting-only diff will cause CI to fail.

Run locally before pushing:
```bash
swift-format format --recursive --in-place .
```

Never disable swift-format for a block unless you add a comment explaining why and get explicit approval in review.

### Naming
Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) strictly. Additions:
- Types: `UpperCamelCase`. No Hungarian notation, no type suffixes on protocols (`Themeable` not `ThemeableProtocol`).
- Variables and functions: `lowerCamelCase`.
- Boolean properties: prefix with `is`, `has`, `can`, `should`, or `allows`. `isCompleted`, not `completed`.
- SwiftData model types: plain noun (`Habit`, `HabitCompletion`), no `Model` suffix.
- SwiftUI views: suffix with `View` only when the name would otherwise collide with a model type (`HabitRowView` vs `Habit`). Do not suffix views that have no collision risk (`TodayTab`, `AnalyticsDashboard`).
- AppIntent types: suffix with `Intent` (`CompleteHabitIntent`).
- Theme token properties: match the semantic name exactly as defined in `HKTheme` — never abbreviate.

### Access Control
Default to the most restrictive access level that works:
- `private` for implementation details within a file.
- `internal` (implicit) for within-package use.
- `public` only at package API boundaries — types and functions explicitly part of a package's public interface.
- `open` is banned. No HabitKit type is designed for subclassing outside the package.

Mark all SwiftData model properties `internal` unless consumed by another package. Do not expose raw SwiftData context or `ModelContainer` across package boundaries — use repository protocols.

### Immutability
Prefer `let` over `var` everywhere. Use `var` only when mutation is genuinely required. In SwiftUI views, all non-`@State`/`@Binding` properties must be `let`.

### Error Handling
Never use `try!` or force-unwrap (`!`) in production code. **[ENFORCED]** CI runs a grep for `try!` and bare `!` on non-test targets and fails the build if found. Exceptions:
- Lazily initialised static constants where the value is guaranteed at compile time — must have a comment explaining why.

Handle errors explicitly. Do not use `try?` to silently discard errors unless you have a written comment explaining that the failure case is intentionally ignored and harmless.

```swift
// ✅
do {
    try context.save()
} catch {
    logger.error("Failed to save context: \(error)")
}
// ❌
try? context.save()
```

### Concurrency
All HabitKit code must compile with `SWIFT_STRICT_CONCURRENCY = complete`. **[ENFORCED]**
- Use `async/await`. No `DispatchQueue` usage in new code.
- `@MainActor` on all SwiftUI views and `@Observable` view models.
- Isolate SwiftData operations to the `@ModelActor` they belong to. Never access a `ModelContext` from an unstructured task without specifying actor context.
- No `nonisolated(unsafe)` without a code review from a maintainer and a comment explaining the invariant that makes it safe.

### Imports
- One import per line.
- No `@testable import` outside test targets.
- Do not import `UIKit` anywhere (this is a SwiftUI project).
- Import order: Apple frameworks first, then third-party (none currently), then internal packages. Separate each group with a blank line. swift-format enforces this automatically.

---

## 2. SwiftUI Component Patterns

### View Structure
Every view file contains exactly one primary `View` type. Helper subviews that are only used by that view live in the same file in extensions or as `private` nested types. When a helper view is used by more than one parent, extract it to its own file in `HabitKitUI`.

```swift
// ✅ — single primary view, private subviews in extension
struct HabitRowView: View {
    let habit: Habit
    var body: some View { ... }
}
private extension HabitRowView {
    var completionIndicator: some View { ... }
}
// ❌ — two unrelated primary views in one file
struct HabitRowView: View { ... }
struct HabitCardView: View { ... }  // belongs in its own file
```

### View Model Pattern
Views must not contain business logic. Any logic beyond simple view state belongs in a view model:
- View models are `@Observable` classes (iOS 17+ `Observation` framework, not `ObservableObject`).
- View models are `@MainActor`.
- Views instantiate their view model with `@State private var viewModel = HabitListViewModel()`.
- View models must not import SwiftUI. They may import `HabitKitCore` and `Combine`.
- Never pass a `ModelContext` directly to a view. Views receive display data only.

### Previews
Every view in `HabitKitUI` must have a `#Preview` block. **[ENFORCED]** CI checks that all public view files contain at least one `#Preview`. Previews must compile and must not crash on launch.

Provide at least two preview variants for any view that has meaningful state variation (empty state, populated state, loading state, etc.).

```swift
#Preview("With habits") {
    HabitListView(viewModel: .preview(habits: .sample))
        .environment(HKTheme.mocha)
}
#Preview("Empty state") {
    HabitListView(viewModel: .preview(habits: []))
        .environment(HKTheme.mocha)
}
```

### State Ownership
- `@State` — view-local ephemeral state (animation triggers, sheet presentation booleans, text field content).
- `@Binding` — state owned by a parent that a child needs to read and write.
- `@Environment` — app-wide values (`HKTheme`, `ModelContext`, custom environment keys).
- `@Query` — SwiftData fetch results. Used only in views, never in view models.
- Never store derived values in `@State`. Compute them from source of truth.

### Accessibility
Every interactive element must have an accessibility label. **[ENFORCED]** CI runs the accessibility audit in test builds and fails on unlabelled interactive elements.

```swift
// ✅
Button(action: complete) {
    CompletionRingView(progress: habit.progress)
}
.accessibilityLabel("Mark \(habit.name) complete")
.accessibilityHint("Double-tap to log today's completion")
// ❌
Button(action: complete) {
    CompletionRingView(progress: habit.progress)
}
```

Do not use `.accessibilityHidden(true)` on elements that convey information — only on purely decorative elements.

### Animation
Use `withAnimation` at the call site, not inside the view body. Animation curves must use the project's defined constants in `HKAnimation`, not raw `spring()` or `easeInOut` values, so durations are consistent across the app.

```swift
// ✅
withAnimation(HKAnimation.standard) {
    isCompleted = true
}
// ❌
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
| `HabitKitCore` | Foundation, SwiftData, CloudKit, HealthKit, CoreLocation, CoreMotion | SwiftUI, `HabitKitUI`, `HabitKitIntents` |
| `HabitKitUI` | SwiftUI, `HabitKitCore` | `HabitKitIntents`, HealthKit directly |
| `HabitKitIntents` | AppIntents, `HabitKitCore` | SwiftUI, `HabitKitUI` |

The main app target may import all three packages.

Violating these boundaries — even if it compiles — will be rejected in review. If you believe a boundary needs to change, open a discussion issue before writing code.

### Layering Within HabitKitCore
Within `HabitKitCore`, enforce this layering (outer layers may depend on inner, not the reverse):
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
// ✅ — HabitKitCore exposes a protocol
public protocol HabitRepository {
    func fetchAll() async throws -> [Habit]
    func save(_ habit: Habit) async throws
}
// ❌ — concrete SwiftData type leaking to UI layer
public final class SwiftDataHabitRepository { ... }
```

### No Business Logic in App Target
The main app target contains:
- `@main` entry point
- `ModelContainer` configuration
- Root environment setup (`HKTheme`, repositories)
- Tab bar / navigation shell

Nothing else. All business logic lives in a package.

---

## 4. Design System & Theme Token Usage

### The Rule **[ENFORCED]**
No hardcoded colors anywhere in the codebase. **Ever.** CI runs a grep for `Color(red:`, `Color(hex:`, `Color(.sRGB`, `UIColor(red:`, and any hex string literal adjacent to a `Color` initialiser. Any match outside of `HKTheme.swift` itself fails the build.

All color usage goes through `HKTheme` semantic tokens:

```swift
// ✅
Rectangle()
    .fill(theme.colors.surface0)
// ❌
Rectangle()
    .fill(Color(hex: "#313244"))
// ❌
Rectangle()
    .fill(Color(.systemBackground))  // use theme.colors.base instead
```

### Accessing the Theme
The current theme is injected as an `@Environment` value:

```swift
struct HabitRowView: View {
    @Environment(HKTheme.self) private var theme

    var body: some View {
        Text(habit.name)
            .foregroundStyle(theme.colors.text)
            .background(theme.colors.surface0)
    }
}
```

Or via the environment key:

```swift
@Environment(\.hkTheme) private var theme
```

Never store a theme reference in a view model. View models are theme-agnostic. If a view model needs to pass a color to a view, it passes a semantic token name (`HKColorRole`), not a resolved `Color`.

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
Use `HKFont` text styles, not raw `Font` values:

```swift
// ✅
Text(habit.name).font(HKFont.body)
Text("7-day streak").font(HKFont.caption)
// ❌
Text(habit.name).font(.system(size: 16, weight: .medium))
```

### Spacing and Radius
Use `HKSpacing` and `HKRadius` constants. Do not write raw `CGFloat` literals for padding or corner radius values.

```swift
// ✅
.padding(HKSpacing.md)
.cornerRadius(HKRadius.card)
// ❌
.padding(16)
.cornerRadius(12)
```

### Icons
Use SF Symbols only. No bundled image assets for icons. Symbol names are defined as `HKSymbol` string constants — use those, do not inline symbol name strings in views.

```swift
// ✅
Image(systemName: HKSymbol.checkmark)
// ❌
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
threshold is defined in HKGesture constants so it can be tuned
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
All `public` and `internal` declarations in `HabitKitCore` and `HabitKitUI` that form a package boundary must have a doc comment. **[ENFORCED]** CI runs `swift-doc` on public symbols and fails if coverage drops below 90%.

All `public` declarations in `HabitKitIntents` must have a doc comment.

Private implementation details do not require doc comments unless the logic is genuinely non-obvious.

### Doc Comment Format
Use `///` triple-slash, not `/* */` block comments. Use DocC-compatible markup:

```swift
/// Represents a single trackable behaviour the user wants to build or break.
///
/// `Habit` is the root model type stored in SwiftData. Subclass via class inheritance
/// for typed variants (``TimedHabit``, ``QuantityHabit``).
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
// ✅ — explains a non-obvious reason
// AlarmKit requires the trigger to be set at least 5 seconds in the future.
// Subtract 5s from the user's intended time to account for scheduling latency.
let adjustedDate = triggerDate.addingTimeInterval(-5)
// ❌ — restates the code
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

---

## 7. Testing Requirements

### Coverage Minimums **[ENFORCED]**

| Target | Minimum line coverage |
|---|---|
| `HabitKitCore` | 80% |
| `HabitKitUI` | 60% (view models only; views are covered by previews) |
| `HabitKitIntents` | 70% |

CI will fail a PR that reduces coverage below these thresholds in the affected target. Increasing coverage is always welcome.

### Test File Naming and Location
Test files live in the `Tests/` directory of their respective package. Naming: `{TypeUnderTest}Tests.swift`. One test file per type under test.

```
HabitKitCore/
  Sources/
    Models/Habit.swift
  Tests/
    HabitKitCoreTests/
      Models/HabitTests.swift
```

### Test Structure
Use Swift Testing (`import Testing`), not XCTest, for all new tests. **[ENFORCED]** New XCTest-based test files will not be accepted. Existing XCTest files may remain until they are naturally touched and migrated.

```swift
import Testing
@testable import HabitKitCore

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
- All `HabitKitCore` model methods and service logic
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
// In HabitKitCore
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
| swift-format compliance | CI: `swift-format lint` |
| No force-unwrap or `try!` in production | CI: grep on non-test targets |
| Strict concurrency | CI: `SWIFT_STRICT_CONCURRENCY=complete` |
| Package import boundaries | CI: grep checks |
| No hardcoded colors | CI: grep for color literals |
| Preview required on all UI views | CI: symbol presence check |
| Accessibility labels on interactive elements | CI: accessibility audit in test builds |
| Doc comment coverage ≥ 90% on public API | CI: swift-doc |
| Test coverage minimums | CI: `xcodebuild test` with coverage flags |
| No XCTest in new files | Code review |
| Conventional commit messages | Code review |
| One change per PR | Code review |

Rules not in this table are enforced during code review. Repeated violations of review-enforced rules may result in a contributor being asked to read this document again before their next PR is reviewed.
