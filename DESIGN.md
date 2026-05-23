# HabitKit — Design Document
**Version 1.2 · May 2026**

---

## 1. Overview

HabitKit is a free, open-source, iOS-native habit tracker built for people who treat habits as systems, not streaks. It is the app Apple would ship if they built a habit tracker: deep OS integration, zero accounts required, full data portability, and a design system rooted in the Catppuccin palette.

The app earns revenue through voluntary community patronage (Patreon/Ko-fi), not in-app purchase. Contributors who submit merged features are credited by GitHub handle in the changelog and in App Store release notes.

---

## 2. North Star

> "What would Apple ship if they built a Habits app?"

Every feature, API choice, and scope decision is evaluated against this question. If Craig Federighi would cut it from v1, it is either scope creep or not integrated enough. If it could ship in the first version of a first-party Apple app, it belongs here.

---

## 3. Target Platform

| Attribute | Value |
|---|---|
| Minimum iOS | iOS 26 |
| Primary target | iPhone |
| Secondary targets | iPad, Apple Watch, Mac (Catalyst) |
| Language | Swift 6 (strict concurrency) |
| UI framework | SwiftUI |
| Toolchain | Xcode 26 |
| Architecture | No third-party analytics, no crash SDKs, no accounts |

**Rationale for iOS 26 minimum:** iOS 26 shipped September 2025 and reached over 75% of active iPhones within 90 days. AlarmKit, the Foundation Models framework, interactive App Intents snippets, and RelevanceConfiguration widgets are all iOS 26-only APIs that are core to the product. Targeting iOS 25 or below would require stripping or conditionally compiling the app's most differentiated features.

### Rolling Minimum OS Policy

HabitKit tracks the current iOS release minus one. When Apple ships a new major iOS version, the minimum deployment target advances to the previous major release on the following schedule:

| Event | Action |
|---|---|
| New iOS ships (e.g. iOS 27) | Begin progressive enhancement work targeting iOS 27 APIs |
| New iOS reaches ~50% adoption (typically 60–90 days post-release) | Raise minimum to the previous release (iOS 26) in the next minor version |
| Two major releases after a version (e.g. iOS 28 ships) | Drop support for iOS 26 entirely in the next major version |

**In practice:** when iOS 28 is the current release, iOS 27 is the minimum. iOS 26 devices can no longer install new versions but retain the last compatible build via the App Store's automatic version gating.

This policy is intentional and non-negotiable. It means:

- No `if #available(iOS 27, *)` guards accumulate in the codebase beyond one generation
- No compatibility shims for APIs superseded more than one release ago
- New APIs are adopted as first-class features, not bolted-on conditionals
- The CI matrix always tests against exactly two targets: current release and current release minus one

**Progressive enhancement** means new iOS APIs are used unconditionally on supported versions — not wrapped in availability checks that water down the feature. If an API requires iOS 27, the minimum is raised to iOS 27 before shipping that feature, not after. A feature that exists only behind `#available` is not a shipped feature — it is a preview that half your users never see.

The one exception is APIs that are device-capability-gated rather than OS-gated — Foundation Models (requires Apple Intelligence hardware), CoreHaptics (requires Taptic Engine), CMHeadphoneMotionManager (requires AirPods Pro/Max), EnergyKit (requires HomeKit + US location). These use capability checks, not OS version checks, and remain in the codebase permanently since the capability gap never closes regardless of OS version.

---

## 4. Monetization & Community Model

### 4.1 Revenue

HabitKit is free with no paywalled features. Revenue is patron-based, external to the App Store, so Apple IAP is never invoked. The tiers live entirely on Patreon or Ko-fi.

| Tier | Monthly | What it means |
|---|---|---|
| Supporter | $1 | Name in changelog credits |
| Voter | $3 | Vote on feature priority polls |
| Collaborator | $10 | Submit feature requests directly, early TestFlight builds, Discord channel access |

**Current state — no in-app Patreon link.** The Patreon URL is in the App Store description page and on the project website only. The reason is historical: App Store Review Guideline 3.2.1 previously prohibited linking to external purchase mechanisms from within an app.

**The legal landscape has changed.** As of 2025, developers can link to external payment destinations from within the app in specific storefronts, subject to entitlement approval and regional rules:

| Region | Status | Mechanism |
|---|---|---|
| United States | ✅ Permitted (April 2025, Epic v. Apple ruling) | `StoreKit External Purchase Link Entitlement` — commission-free as of the ruling, though a December 2025 appeals court partial reversal means Apple may eventually charge a "reasonable" fee (rate not yet set, pending district court) |
| European Union | ✅ Permitted (DMA compliance, June 2025) | `StoreKit External Purchase Link Entitlement (EU)` — triggers a 2% Initial Acquisition Fee on new users' first 6 months plus Core Technology Fee obligations |
| Other regions | ❌ Still prohibited | Standard guidelines apply outside US and EU |

**For HabitKit specifically:** Since the app is completely free and Patreon is voluntary patronage rather than a purchase of digital goods, the entitlement may not even be required — linking to a patron page is meaningfully different from selling unlockable features. However, the safer path is to apply for the entitlement rather than assume the distinction protects the app.

**If a "Support on Patreon" link is added to Settings:**
1. Apply for `StoreKit External Purchase Link Entitlement` via App Store Connect
2. Declare the destination URL statically in `Info.plist` under `SKExternalPurchaseLinkURL`
3. Use `StoreKit.ExternalPurchaseLink.open()` API which automatically presents Apple's required disclosure sheet before redirecting — this is mandatory, not optional
4. The link must be US/EU-storefront-gated using `SKPaymentQueue.canMakePayments()` and storefront checks — other regions must not see the link
5. The disclosure sheet Apple presents cannot be skipped, customised, or bypassed

```swift
import StoreKit
// Only show the Patreon link in US and EU storefronts
func showPatreonLinkIfEligible() async {
    guard let storefront = await Storefront.current else { return }
    let eligibleRegions = ["USA", "AUT", "BEL", "BGR", "HRV", "CYP", "CZE",
                           "DNK", "EST", "FIN", "FRA", "DEU", "GRC", "HUN",
                           "IRL", "ITA", "LVA", "LTU", "LUX", "MLT", "NLD",
                           "POL", "PRT", "ROU", "SVK", "SVN", "ESP", "SWE"]
    guard eligibleRegions.contains(storefront.countryCode) else { return }
    showPatreonButton = true
}
// When the user taps the button
Button("Support on Patreon") {
    Task {
        try? await ExternalPurchaseLink.open()
        // ExternalPurchaseLink.open() presents Apple's disclosure sheet first,
        // then redirects to the URL declared in Info.plist
    }
}
```

**This is a future option, not a v1 commitment.** HabitKit ships without the in-app link. The decision to add it is left to the maintainer once the US appeals court situation stabilises and the entitlement overhead is evaluated against the marginal patron conversion benefit.

### 4.2 Open Source

HabitKit is licensed under MIT. The full codebase is public on GitHub. Every PR that ships in a release credits the contributor's GitHub handle in both `CHANGELOG.md` and the App Store release notes verbatim:

```
v1.3.0
- Habit streak freeze [contributed by @username, #PR42]
- Focus Filter improvements [contributed by @username, #PR38]
```

A `CONTRIBUTING.md` defines app scope rules before inbound PRs arrive. Contributions outside scope receive a written rationale for rejection. PRs that hardcode colors, skip `HKTheme` tokens, or bypass the design system are rejected regardless of feature quality.

### 4.3 Community Theme Gallery

Community-submitted themes are stored in a public GitHub repo as a `themes.json` file, browsable and installable from within the app. Theme submissions are PR-based. A CI step validates every PR against a JSON schema — malformed or incomplete themes never reach manual review.

---

## 5. Package Architecture

The codebase is split into three Swift packages:

```
HabitKit/
├── App/                  # Main app target (iOS, iPadOS, Watch, Mac)
├── HabitKitCore/         # Models, persistence, business logic
│   ├── Sources/
│   │   ├── Models/       # SwiftData @Model types
│   │   ├── Persistence/  # ModelContainer configuration, CloudKit setup
│   │   ├── HealthKit/    # HK read/write layer
│   │   └── Analytics/    # On-device stats, no telemetry
├── HabitKitUI/           # Design system, components, themes
│   ├── Sources/
│   │   ├── Tokens/       # HKColor, HKTypography, HKSpacing
│   │   ├── Components/   # HKButton, HKCard, HKTextField, etc.
│   │   ├── Themes/
│   │   │   ├── Built-in/ # catppuccin.json (all four flavors)
│   │   │   └── Community/# themes.json (community submissions)
│   │   └── HabitKitUI.swift
└── HabitKitIntents/      # AppIntents, Focus Filters, Shortcuts
    └── Sources/
        └── Intents/      # LogHabitIntent, GetStreakIntent, etc.
```

**Rule:** Contributors import `HabitKitUI`. They cannot reference raw hex values or system colors directly. Any PR that does so fails CI.

---

## 6. Design System

### 6.1 Theme Architecture

HabitKit uses a JSON-driven theme engine. A theme is a named set of 11 semantic color roles. The `HKThemeManager` observable loads themes from bundled JSON at startup and makes the current theme available throughout the app via SwiftUI's `Environment`.

**Theme model:**

```swift
public struct HKTheme: Codable, Identifiable, Hashable {
    public let id: String           // "catppuccin-mocha"
    public let name: String         // "Mocha"
    public let author: String?      // nil for built-in, GitHub handle for community
    public let isDark: Bool
    public let colors: HKThemeColors
}

public struct HKThemeColors: Codable, Hashable {
    public let base: String         // page background
    public let surface0: String     // card background
    public let surface1: String     // elevated card
    public let surface2: String     // input fields
    public let overlay0: String     // disabled states
    public let text: String         // primary text
    public let subtext: String      // secondary text
    public let primary: String      // accent / interactive
    public let danger: String       // destructive actions
    public let success: String      // completion states
    public let warning: String      // missed / at-risk states
}
```

**Theme injection:**

```swift
// App entry point
ContentView()
    .environment(themeManager)

// Any component
@Environment(HKThemeManager.self) private var themes
Text("Today").foregroundStyle(themes.current.textPrimary)
```

### 6.2 Built-in Themes: Catppuccin

All four official Catppuccin flavors are bundled. Hex values are sourced from the official Catppuccin palette (catppuccin.com/palette, MIT license).

**Latte (light):**

| Role | Color Name | Hex |
|---|---|---|
| base | Base | `#eff1f5` |
| surface0 | Surface 0 | `#ccd0da` |
| surface1 | Surface 1 | `#bcc0cc` |
| surface2 | Surface 2 | `#acb0be` |
| overlay0 | Overlay 0 | `#9ca0b0` |
| text | Text | `#4c4f69` |
| subtext | Subtext 1 | `#5c5f77` |
| primary | Mauve | `#8839ef` |
| danger | Red | `#d20f39` |
| success | Green | `#40a02b` |
| warning | Peach | `#fe640b` |

**Frappé (dark):**

| Role | Color Name | Hex |
|---|---|---|
| base | Base | `#303446` |
| surface0 | Surface 0 | `#414559` |
| surface1 | Surface 1 | `#51576d` |
| surface2 | Surface 2 | `#626880` |
| overlay0 | Overlay 0 | `#737994` |
| text | Text | `#c6d0f5` |
| subtext | Subtext 1 | `#b5bfe2` |
| primary | Mauve | `#ca9ee6` |
| danger | Red | `#e78284` |
| success | Green | `#a6d189` |
| warning | Peach | `#ef9f76` |

**Macchiato (dark):**

| Role | Color Name | Hex |
|---|---|---|
| base | Base | `#24273a` |
| surface0 | Surface 0 | `#363a4f` |
| surface1 | Surface 1 | `#494d64` |
| surface2 | Surface 2 | `#5b6078` |
| overlay0 | Overlay 0 | `#6e738d` |
| text | Text | `#cad3f5` |
| subtext | Subtext 1 | `#b8c0e0` |
| primary | Mauve | `#c6a0f6` |
| danger | Red | `#ed8796` |
| success | Green | `#a6da95` |
| warning | Peach | `#f5a97f` |

**Mocha (dark, default):**

| Role | Color Name | Hex |
|---|---|---|
| base | Base | `#1e1e2e` |
| surface0 | Surface 0 | `#313244` |
| surface1 | Surface 1 | `#45475a` |
| surface2 | Surface 2 | `#585b70` |
| overlay0 | Overlay 0 | `#6c7086` |
| text | Text | `#cdd6f4` |
| subtext | Subtext 1 | `#bac2de` |
| primary | Mauve | `#cba6f7` |
| danger | Red | `#f38ba8` |
| success | Green | `#a6e3a1` |
| warning | Peach | `#fab387` |

**Default:** Mocha on first launch. Latte activates automatically when the user's system appearance is set to light mode, unless the user has manually selected a theme.

### 6.3 Community Theme Submission Format

Community themes are submitted as JSON entries in the public `themes.json` file. A JSON schema validates every PR via GitHub Actions (`ajv validate`). The `author` field is required for community submissions and must be a GitHub handle.

```json
{
  "themes": [
    {
      "id": "nord",
      "name": "Nord",
      "author": "exampleuser",
      "isDark": true,
      "colors": {
        "base":     "#2e3440",
        "surface0": "#3b4252",
        "surface1": "#434c5e",
        "surface2": "#4c566a",
        "overlay0": "#616e88",
        "text":     "#eceff4",
        "subtext":  "#d8dee9",
        "primary":  "#88c0d0",
        "danger":   "#bf616a",
        "success":  "#a3be8c",
        "warning":  "#ebcb8b"
      }
    }
  ]
}
```

### 6.4 Typography

```swift
public extension Font {
    static var hkLargeTitle: Font { .system(.largeTitle, design: .rounded, weight: .bold) }
    static var hkTitle: Font      { .system(.title2, design: .rounded, weight: .semibold) }
    static var hkHeadline: Font   { .system(.headline, design: .rounded, weight: .semibold) }
    static var hkBody: Font       { .system(.body, design: .default, weight: .regular) }
    static var hkCaption: Font    { .system(.caption, design: .default, weight: .regular) }
    static var hkMono: Font       { .system(.body, design: .monospaced, weight: .regular) }
}
```

All type scales respect Dynamic Type. No fixed font sizes anywhere in the codebase.

### 6.5 Component Library (HKButton as canonical example)

```swift
public struct HKButton: View {
    public enum Variant { case primary, secondary, danger, ghost }
    let label: String
    let variant: Variant
    let action: () -> Void

    public var body: some View {
        Button(action: action) {
            Text(label)
                .font(.hkBody)
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: 10))
        }
    }
}
```

Usage: `HKButton("Delete", variant: .danger) { deleteHabit() }`

All components follow this pattern. No component references raw hex or system colors.

### 6.6 Liquid Glass (iOS 26)

HabitKit adopts the iOS 26 Liquid Glass design language. The `glassEffect(_:in:isEnabled:)` modifier is used for modal surfaces, sheets, and floating panels. Recompiling with Xcode 26 applies Liquid Glass to standard SwiftUI components automatically. Custom glass surfaces use the new API explicitly.

---

## 7. Data Model

### 7.1 Persistence Layer

HabitKit uses **SwiftData** with **CloudKit** sync via `NSPersistentCloudKitContainer`. All data lives in the user's private iCloud container — no HabitKit servers ever hold user data.

CloudKit sync is opt-in. On first launch, the user is prompted. The default is local-only.

**iOS 26 note:** SwiftData in iOS 26 supports class inheritance in model graphs. HabitKit uses this for typed habit subclasses.

### 7.2 Core Models

```swift
@Model
class Habit {
    var id: UUID
    var name: String
    var icon: String          // SF Symbol name
    var colorHex: String      // accent override, falls back to theme primary
    var sortOrder: Int
    var createdAt: Date
    var isArchived: Bool
    var focusModeID: String?  // if set, only visible in this Focus mode
    @Relationship(deleteRule: .cascade)
    var completions: [HabitCompletion]
    @Relationship(deleteRule: .cascade)
    var schedule: HabitSchedule
    @Relationship(deleteRule: .cascade)
    var progressionPlan: ProgressionPlan?   // nil = fixed target, no progression
    var visionProfile: VisionProfile?       // nil in v1
}

@Model
class TimedHabit: Habit {
    var targetDurationSeconds: Int
}

@Model
class QuantityHabit: Habit {
    var targetQuantity: Double
    var unit: String          // "pages", "glasses", "km"
}

@Model
class ChecklistHabit: Habit {
    var steps: [String]
}

@Model
class NegativeHabit: Habit {
    // Track avoidance — completed means "successfully avoided today"
    var avoidTarget: String
}

@Model
class HabitCompletion {
    var id: UUID
    var completedAt: Date
    var value: Double?        // for quantity habits
    var durationSeconds: Int? // for timed habits
    var note: String?
    @Attribute(.externalStorage)
    var photo: Data?          // raw JPEG; .externalStorage keeps blobs out of the SQLite store
    @Attribute(.externalStorage)
    var paperMarkup: Data?    // PaperKit annotation — nil if no annotation
    var weatherContext: HKWeatherContext?
    var habit: Habit
}

@Model
class HabitSchedule {
    var frequency: ScheduleFrequency // daily, weekly(days:), interval(every:), xTimesPerWeek(x:)
    var reminderTimes: [Date]
    var habit: Habit
}

// MARK: - Progressive Overload

@Model
class ProgressionPlan {
    var baseTarget: Double              // original target at creation
    var currentTarget: Double           // active target used for completion evaluation
    var incrementValue: Double          // step size per scheduled increase
    var incrementIntervalDays: Int      // cadence — e.g. 28 for monthly
    var nextScheduledIncrease: Date?    // nil if no scheduled plan
    var coreMLNudgesEnabled: Bool       // opt-in per habit; default true
    var minimumTarget: Double?          // floor — CoreML will not suggest below this
    var maximumTarget: Double?          // ceiling — CoreML will not suggest above this
    @Relationship(deleteRule: .cascade)
    var history: [ProgressionEvent]
    var habit: Habit
}

@Model
class ProgressionEvent {
    var date: Date
    var previousTarget: Double
    var newTarget: Double
    var source: ProgressionSource
    var nudgeRationale: String?         // Foundation Models text if CoreML-driven; nil otherwise
}

enum ProgressionSource: String, Codable {
    case scheduled              // automatic increment from ProgressionPlan
    case userInitiated          // user manually changed target
    case coreMLAccepted         // user accepted a CoreML nudge suggestion
    case coreMLDismissed        // user dismissed at banner — model learns preference
    case coreMLLoosenConfirmed  // user confirmed loosening after two-tap flow (negative habits)
    case coreMLLoosenCancelled  // user reached confirmation screen but cancelled
}

// MARK: - Negative Habit Progression

@Model
class NegativeProgressionPlan: ProgressionPlan {
    var timeWindowMinutes: Int?
    var timeWindowStartHour: Int?
    var timeWindowStartMinute: Int?
    var timeWindowEndHour: Int?
    var timeWindowEndMinute: Int?
    var coreMLTightenConfidence: Float   // default 0.65
    var coreMLLoosenConfidence: Float    // default 0.90
    // Loosen always requires deliberate two-tap confirmation
    var requireConfirmationToLoosen: Bool { true }
}
```

### 7.3 Progressive Overload

Progressive overload is the principle that a target should evolve as the user grows. A 5km running target that was challenging in week one is trivial in month three. Without adjustment the habit becomes a maintenance checkbox rather than a growth mechanism.

HabitKit supports two progression paths that operate independently and can be combined:

**Scheduled progression** is a commitment device. At habit creation the user defines a step size and cadence — "increase my run distance by 0.5km every 28 days." The plan executes automatically. The user made a contract with their future self at a moment of high motivation and the app honours it without requiring ongoing willpower.

**CoreML-driven nudges** are adaptive observations. The clustering model (§8.36) watches completion rate, actual completion value, and time-to-completion over a rolling 14-day window. When it detects consistent overperformance — the user averages 6.2km against a 5km target — it surfaces a suggestion. When it detects consistent underperformance it suggests lowering the target. The model observes and asks. The user always decides.

The downward nudge is as important as the upward one. A target the user consistently misses generates avoidance and anxiety. A 15-minute meditation target the user consistently hits is more valuable than a 20-minute target they consistently avoid. Suggesting a decrease is reframed as calibration, not failure.

**Conflict resolution:** if a scheduled increase is due but CoreML is detecting underperformance, HabitKit surfaces the conflict explicitly: "You planned to increase your target next week, but your recent completions suggest holding at the current level. What would you like to do?" The user is never blindsided by an automatic change in either direction.

**The `ProgressionEvent` log** makes the entire history transparent and auditable. A chart of target values over two years — growing through scheduled increments and accepted nudges, dipping during illness, recovering — is a meaningful record of genuine development. It belongs in the Analytics tab as a dedicated progression timeline view.

**`coreMLDismissed` source** is stored deliberately. When a user dismisses a CoreML suggestion, the model learns that this user's threshold for accepting nudges is different from the default. Over time the model calibrates its suggestion sensitivity to the individual user's preferences — it becomes less likely to suggest changes the user has historically rejected.

#### Negative Habit Progression — Asymmetric Mechanics

Negative habits (tracking avoidance — screen time, alcohol, junk food) use progression mechanics that are structurally inverted from positive habits and deliberately asymmetric in how they handle loosening vs. tightening.

**The target is a tolerance threshold, not a goal.** For a negative habit, `currentTarget` represents the maximum allowed — the ceiling below which the day counts as a success. Progression always moves toward restriction: the ceiling lowers over time.

**Progression operates on two independent axes:**
- **X** — the quantity threshold (number of drinks, minutes of screen time, number of social media opens)
- **Y** — the time window (per day, per sitting, after a specific hour)

**Asymmetric CoreML confidence thresholds:**

| Suggestion direction | Positive habit | Negative habit |
|---|---|---|
| Tighten (restrict more) | 0.70 | 0.65 — suggest readily |
| Loosen (allow more) | 0.70 | 0.90 — require strong sustained evidence |

**The loosen confirmation flow:**

When the model reaches 0.90 confidence for a loosen suggestion, the UI does not show a banner. It presents a full sheet:

```
Title: "You've made real progress"
Body: "You've stayed under your 1-drink limit for 47 consecutive days.
Your data suggests your threshold could move to 2 drinks.
This is your choice. Many people find maintaining a tight
threshold protects progress they've worked hard to build."
Primary action:   "Keep my current limit"   ← prominent
Secondary action: "Raise to 2 drinks"        ← requires a second confirmation tap
```

`coreMLLoosenCancelled` is stored when the user reaches the second confirmation tap and backs out — this is a stronger preference signal than dismissing the initial sheet, and the model treats repeated cancellations as strong evidence not to suggest loosening again for at least 90 days.

### 7.4 Habit Templates (.habit files)

Any habit configuration can be exported as a `.habit` file — a JSON document registered as a custom UTType. Users share these via AirDrop, Files app, or the community GitHub repo. Importing a `.habit` file triggers a native share sheet prompt.

```json
{
  "version": 1,
  "name": "Morning Run",
  "icon": "figure.run",
  "type": "timed",
  "targetDurationSeconds": 1800,
  "schedule": {
    "frequency": "daily",
    "reminderTimes": ["07:00"]
  }
}
```

UTType registration in `Info.plist`:

```xml
<key>UTExportedTypeDeclarations</key>
<array>
  <dict>
    <key>UTTypeIdentifier</key>
    <string>com.habitkit.habit</string>
    <key>UTTypeTagSpecification</key>
    <dict>
      <key>public.filename-extension</key>
      <array><string>habit</string></array>
    </dict>
  </dict>
</array>
```

---

## 8. iOS System Integration

### 8.1 ActivityKit — Live Activities

Timed habits launch a Live Activity when started. The activity shows a countdown on the Lock Screen, Dynamic Island, StandBy, Apple Watch, and CarPlay (iOS 26).

```swift
struct HabitLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var habitName: String
        var isComplete: Bool
    }
    var habitID: UUID
    var habitName: String
    var targetSeconds: Int
}
```

The Dynamic Island compact view shows the habit icon, habit name, and a circular progress ring. The expanded view adds the timer and a "Complete" button backed by an `AppIntent`.

### 8.2 AlarmKit — Habit Alarms (iOS 26)

Users can set any habit as an AlarmKit alarm. This breaks through silent mode and Focus filters — reserved for habits the user explicitly marks as critical (e.g., morning medication, scheduled workout).

The alarm presents on Lock Screen, Dynamic Island, StandBy, and Apple Watch with custom "Complete Habit" and "Snooze" buttons backed by `AppIntents`. The `NSAlarmKitUsageDescription` key is set in `Info.plist`.

Authorization is requested lazily on first alarm creation, not at app launch.

### 8.3 AppIntents — Shortcuts, Siri, Spotlight, Visual Intelligence

HabitKit implements the following intents in `HabitKitIntents`:

| Intent | Surface | Return value |
|---|---|---|
| `LogHabitIntent` | Shortcuts, Siri, Control Center | Confirmation dialog + snippet |
| `SkipHabitIntent` | Shortcuts, Siri | Confirmation |
| `GetStreakIntent` | Shortcuts, Siri | `Int` (usable in multi-step shortcuts) |
| `GetTodayProgressIntent` | Spotlight, Siri | Completion percentage |
| `ListIncompleteHabitsIntent` | Shortcuts, Siri | `[HabitEntity]` |
| `StartTimerIntent` | Shortcuts, Action Button | Starts Live Activity |
| `FocusFilterIntent` | Focus setup | Filters visible habits by Focus mode |

**Interactive Snippets (iOS 26):** `LogHabitIntent` returns a SwiftUI snippet with a "Mark Complete" button. When invoked from Spotlight, the snippet appears inline — the user logs a habit without opening the app.

**Visual Intelligence (iOS 26):** HabitKit registers a `semanticContentSearch` query. Pointing the camera at running shoes, a yoga mat, or a medication bottle can surface the relevant habit via Visual Intelligence.

**App Shortcuts phrases:**

```swift
AppShortcut(
    intent: LogHabitIntent(),
    phrases: [
        "Log \(\.$habit) in \(.applicationName)",
        "Mark \(\.$habit) done in \(.applicationName)"
    ],
    shortTitle: "Log Habit",
    systemImageName: "checkmark.circle"
)
```

### 8.4 WidgetKit

HabitKit ships a **widget composer** rather than a fixed set of widgets. The user configures which habits to display, what data to show, and what layout to use. All configurations use `AppIntentConfiguration` so the picker is Siri-aware.

| Widget family | Content |
|---|---|
| `systemSmall` | Today's completion ring |
| `systemMedium` | Ring + next 3 incomplete habits |
| `systemLarge` | Full today view with all habits |
| `lockScreenCircular` | Completion ring |
| `lockScreenRectangular` | "N of M habits done" |
| `accessoryInline` | Next incomplete habit name |
| `standBySmall` | Large ring, current streak |

**Relevance widgets (watchOS 26):** `RelevanceConfiguration` surfaces the habit widget at the right time of day automatically via the Smart Stack — morning habit widget appears in the morning, workout widget when the user arrives at the gym.

**CarPlay (iOS 26):** Habit progress widget displays in CarPlay on all cars. Uses StandBy-style rendering.

**iOS 26 glass rendering:** Widgets adopt the accented rendering mode for glass and tinted home screen appearances without code changes.

### 8.5 Focus Filters

HabitKit registers a `FocusFilterIntent`. In the Focus setup screen, users configure which habits are visible in each Focus mode. During Work Focus, only work-tagged habits appear in widgets, notifications, and Live Activities. During Sleep Focus, only wind-down habits appear.

This uses `SetFocusFilterIntent` from `AppIntents`. The filter stores the selected habit IDs for each Focus mode in `UserDefaults` via app group, shared with the widget and intent extensions.

### 8.6 HealthKit

HabitKit requests read/write access to HealthKit on a per-habit basis, never at launch. The permission prompt is contextual — it appears when the user creates or configures a habit that maps to a HealthKit type.

**Write mappings (habit completion → HealthKit):**

| Habit type | HK write type |
|---|---|
| Meditation (timed) | `HKCategoryTypeIdentifierMindfulSession` |
| Workout (timed) | `HKWorkoutActivityType` + `HKWorkout` |
| Water intake (quantity) | `HKQuantityTypeIdentifierDietaryWater` |
| Sleep (checklist) | Writes notes; reads `HKCategoryTypeIdentifierSleepAnalysis` |
| Standing (quantity) | Reads `HKCategoryTypeIdentifierAppleStandHour` |

**Read mappings (HealthKit → auto-completion):**

| HK data | Auto-completes habit |
|---|---|
| Step count ≥ target | Step goal habit |
| Stand hours ≥ target | Stand habit |
| Mindful minutes ≥ target | Meditation habit |
| Workout recorded | Matching workout habit |

Auto-completion via HealthKit runs in a `BGProcessingTask` when the device is charging and idle.

HabitKit appears as a data source inside the iOS Health app for every type it writes.

### 8.7 CoreMotion

`CMMotionActivityManager` detects walking/running/cycling. When detected, the matching habit type's timer is offered as a Live Activity suggestion via a `UNNotificationAction` — not forced, offered.

`CMPedometer` provides real-time step count for step-goal habit auto-completion without requiring a full `BGTask` cycle.

### 8.8 CoreLocation — Geofencing

Users can attach a location to a habit. Arriving at that location triggers the habit reminder via `UNLocationNotificationTrigger`. No background polling — the OS wakes the app on region entry/exit via `CLMonitor`.

Examples:
- Gym arrival → "Start workout" notification
- Home arrival → "Wind-down routine" notification
- Office departure → "Commute habit" notification

### 8.9 Screen Time API

HabitKit uses `DeviceActivity`, `FamilyControls`, and `ManagedSettings` for two self-directed habits:

**"Decrease Screen Time" habit:** User selects apps via `FamilyActivityPicker`. `DeviceActivity` monitors daily usage. When the user's usage of selected apps exceeds the threshold, `DeviceActivityMonitor` marks the habit as missed.

**"Distraction Block" habit:** When a timed habit session starts, `ManagedSettings` shields the user's selected distraction apps for the duration. The shield is removed when the habit completes or the timer expires.

**Implementation notes:**
- The `FamilyControls` entitlement (`com.apple.developer.family-controls`) must be requested from Apple before TestFlight or App Store submission. Apply using `.individual` authorization scope, framed as self-directed digital wellness.
- The `DeviceActivityMonitor` extension runs in a separate process with a 6MB memory limit. All inter-process state is exchanged via a shared `UserDefaults` suite (`group.com.habitkit.app`).
- Application tokens from `FamilyControls` are not guaranteed stable across OS updates. The extension re-validates tokens on each interval start.
- Screen Time thresholds have had reliability issues in iOS 26 betas. This feature is implemented as a non-critical enhancement. The habit system functions fully without it.

### 8.10 Foundation Models (iOS 26) — Guided Generation Architecture

HabitKit uses Apple's on-device Foundation Models framework with the full guided generation pipeline. All inference runs on-device, on the Neural Engine, at zero cost per request. No data leaves the device. Features degrade gracefully on non-Apple-Intelligence devices.

#### Availability guard

Every model access is gated behind an availability check. This is not optional — calling `LanguageModelSession` on an unsupported device crashes:

```swift
guard case .available = SystemLanguageModel.default.availability else {
    showNonAIFallback()
    return
}
```

Supported devices: iPhone 15 Pro and later, any iPhone 16 or later. All other devices see the fallback UI silently — no error message, no explanation. The feature simply isn't present.

#### Prewarm — critical for perceived performance

`LanguageModelSession` has significant initialization overhead on first use. Call `prewarm()` during idle states before the user reaches any AI-powered screen — specifically when they enter the habit creation flow or open the Analytics tab:

```swift
// In HabitCreationViewModel.onAppear
Task.detached(priority: .background) {
    await LanguageModelSession.prewarm()
}
```

Without prewarming, the first inference call has a noticeable 1–3 second delay before the first token appears. With prewarming, the response feels near-instant. This is the difference between a feature that feels native and one that feels bolted on.

#### Feature 1 — Habit suggestion from goal (Guided Generation)

The user describes a vague wellness goal in natural language. The model returns a strongly-typed `HKHabitSuggestion` array — not free text that requires downstream parsing.

The `@Generable` macro enforces the schema at the compiler level. The model cannot return malformed output:

```swift
import FoundationModels
@Generable
struct HKHabitSuggestion {
    @Guide("Short habit name, 2-4 words") var name: String
    @Guide("How often to do it") var frequency: HabitFrequency
    @Guide("Best time of day") var preferredTime: HabitTimeOfDay
    @Guide("Why this habit addresses the goal") var rationale: String
}
@Generable
enum HabitFrequency: String {
    case daily, weekdays, weekends, threeTimesWeek, weekly
}
@Generable
enum HabitTimeOfDay: String {
    case morning, afternoon, evening, anytime
}
// Usage
func suggestHabits(from goal: String) async throws -> [HKHabitSuggestion] {
    let session = LanguageModelSession(
        instructions: """
        You are a habit coach. Given a user's wellness goal, suggest 2-4 specific, \
        actionable habits. Be concrete and realistic. Never suggest habits that require \
        spending money or specialized equipment unless the user mentions they have access.
        """
    )
    let response = try await session.respond(
        to: "My goal: \(goal)",
        generating: [HKHabitSuggestion].self
    )
    return response.content
}
```

#### Feature 2 — Completion note tagging (Content Tagging Adapter)

When a user adds a free-text note to a completion, the content-tagging adapter extracts structured semantic tags. These tags feed the analytics correlation engine — finding patterns like "mood: low correlates with skipped warm-up on days with 5+ calendar events."

```swift
@Generable
struct HKCompletionTags {
    @Guide("User's apparent mood, if discernible") var mood: MoodTag?
    @Guide("Parts of the habit that were skipped or modified") var skipped: [String]
    @Guide("External factors mentioned") var factors: [String]
    @Guide("Overall sentiment of the note") var sentiment: SentimentTag
}
@Generable enum MoodTag: String { case high, neutral, low, unknown }
@Generable enum SentimentTag: String { case positive, neutral, negative }
func tagCompletionNote(_ note: String) async throws -> HKCompletionTags {
    let session = LanguageModelSession(
        instructions: "Extract structured tags from a habit completion note. Be conservative — only tag what is clearly stated."
    )
    let response = try await session.respond(
        to: note,
        generating: HKCompletionTags.self
    )
    return response.content
}
```

#### Feature 3 — Weekly natural language summary

On Sunday evening, the model generates a plain-language summary of the week's habit data. Incorporates completion rates, streak changes, busy-day correlations, and mood tag patterns from completion notes. Cached in SwiftData as a `WeeklySummary` record. Never regenerated unless the user explicitly requests a refresh.

```swift
func generateWeeklySummary(data: WeeklyHabitData) async throws -> String {
    let session = LanguageModelSession(
        instructions: """
        You are a supportive habit coach writing a brief (3-4 sentence) weekly summary. \
        Be encouraging but honest. Focus on patterns, not just counts. \
        Never use generic phrases like 'great job' or 'keep it up'.
        """
    )
    let prompt = data.summaryPrompt  // structured string built from SwiftData query results
    let response = try await session.respond(to: prompt)
    return response.content
}
```

#### Refusal handling

When the user's input is outside the app's capability or triggers a content safety refusal, `LanguageModelSession` throws `LanguageModelSession.GenerationError.refusal`. Catch it explicitly and show a specific, non-technical message — never let it surface as a generic error:

```swift
do {
    let suggestions = try await suggestHabits(from: goalText)
    showSuggestions(suggestions)
} catch LanguageModelSession.GenerationError.refusal(let reason) {
    showRefusalMessage(reason ?? "Try describing your goal differently.")
} catch {
    showNonAIFallback()
}
```

The refusal path is not an error state — it is a normal operating condition. Some user inputs will be refused. The UI must handle it gracefully without alarming the user.

#### Memory pressure degradation

If the device is under memory pressure during inference, the model may return degraded output or throw a resource exhaustion error. The app never retries automatically — it shows the non-AI fallback silently. All AI-powered UI surfaces have fully functional non-AI equivalents.

### 8.11 Handoff & Continuity

`NSUserActivity` with the type `com.habitkit.review` is donated when the user opens the habit detail view. Handoff allows picking up on iPad or Mac without re-navigating.

Universal Clipboard: copying a `.habit` template on Mac allows pasting on iPhone to import.

AirDrop: `.habit` files can be dropped to any device running HabitKit. The receiving device shows a native import confirmation sheet.

### 8.12 Apple Watch

The Watch app is fully independent. Habit logging does not require the phone to be present. Data syncs to the phone via `WatchConnectivity` when in range.

- **Complications:** Available in all complication families (Modular, Infograph, corners, Siri face)
- **Double tap (Series 9+):** Logs the next incomplete habit with no screen interaction required
- **Smart Stack widget:** Uses `INRelevantShortcut` to surface at the contextually correct time of day
- **Workout integration:** Starting a workout in Apple's Workout app prompts to also start the matching HabitKit habit timer

### 8.13 Notifications

All notifications follow Apple's own patterns — one notification at the right moment, never a stream.

- **Grouping:** All HabitKit notifications thread under one group per day
- **Actions:** "Complete" and "Skip" buttons on every reminder; no app open required (`UNNotificationAction`)
- **Time-sensitive:** Only habits the user explicitly marks critical use `UNNotificationInterruptionLevel.timeSensitive`
- **Location-triggered:** Geofence habits use `UNLocationNotificationTrigger`
- **Focus-aware:** Notifications respect the active Focus mode via `FocusFilterIntent`

### 8.14 Spotlight & CoreSpotlight

Every habit and habit completion is indexed as a `CSSearchableItem`. Searching "meditation streak" in Spotlight opens HabitKit directly to the meditation habit's analytics view. Searching "log workout" surfaces the `LogHabitIntent` interactive snippet inline.

#### In-app indexing

Habits are indexed when created or updated. Completions are indexed when saved. The index is updated incrementally — no full re-index on every launch.

```swift
import CoreSpotlight

func indexHabit(_ habit: Habit) {
    let attributeSet = CSSearchableItemAttributeSet(contentType: .item)
    attributeSet.title = habit.name
    attributeSet.contentDescription = "Habit · \(habit.schedule.frequency.displayName)"
    attributeSet.thumbnailData = UIImage(systemName: habit.icon)?.pngData()

    let item = CSSearchableItem(
        uniqueIdentifier: "habit-\(habit.id.uuidString)",
        domainIdentifier: "com.habitkit.habits",
        attributeSet: attributeSet
    )
    item.expirationDate = .distantFuture

    CSSearchableIndex.default().indexSearchableItems([item]) { error in
        if let error { Logger.spotlight.error("Index failed: \(error)") }
    }
}
```

#### CSIndexExtensionProvider — background indexing

For completions that accumulate while the app is backgrounded, HabitKit ships a `CSIndexExtensionRequestHandler` in an Index Extension. The extension is declared in `Info.plist` with `NSExtensionPointIdentifier: com.apple.corespotlightd.index`:

```swift
// HabitKitIndexExtension/IndexRequestHandler.swift
import CoreSpotlight

final class HabitKitIndexExtension: CSIndexExtensionRequestHandler {
    override func searchableIndex(
        _ searchableIndex: CSSearchableIndex,
        reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void
    ) {
        // Open the shared SwiftData store and rebuild the full index
        Task {
            let container = try? ModelContainer.shared()
            let habits = try? await container?.mainContext.fetch(FetchDescriptor<Habit>())
            let items = (habits ?? []).map { makeCSSearchableItem(for: $0) }
            try? await searchableIndex.indexSearchableItems(items)
            acknowledgementHandler()
        }
    }

    override func searchableIndex(
        _ searchableIndex: CSSearchableIndex,
        reindexSearchableItemsWithIdentifiers identifiers: [String],
        acknowledgementHandler: @escaping () -> Void
    ) {
        Task {
            let container = try? ModelContainer.shared()
            let ids = identifiers.compactMap { UUID(uuidString: $0.replacingOccurrences(of: "habit-", with: "")) }
            var descriptor = FetchDescriptor<Habit>(predicate: #Predicate { ids.contains($0.id) })
            let habits = try? await container?.mainContext.fetch(descriptor)
            let items = (habits ?? []).map { makeCSSearchableItem(for: $0) }
            try? await searchableIndex.indexSearchableItems(items)
            acknowledgementHandler()
        }
    }
}
```

#### File-lock race condition

The Index Extension and the main app both open the same SwiftData `ModelContainer`. SwiftData uses SQLite WAL mode, which allows concurrent readers but only one writer. The extension opens the store read-only to avoid write conflicts with the main app:

```swift
// ModelContainerConfiguration.swift
static func makeReadOnly() throws -> ModelContainer {
    var config = ModelConfiguration(
        schema: Schema([Habit.self, HabitCompletion.self, HabitSchedule.self]),
        isStoredInMemoryOnly: false,
        allowsSave: false  // read-only — prevents WAL lock contention with main app
    )
    config.groupContainer = .identifier("group.com.habitkit.app")
    return try ModelContainer(for: Schema([Habit.self]), configurations: [config])
}
```

If the main app holds a write transaction when the extension starts, `ModelContainer` initialization may fail. Use a retry with exponential backoff:

```swift
func openContainerWithRetry(maxAttempts: Int = 3) async throws -> ModelContainer {
    var lastError: Error?
    for attempt in 0..<maxAttempts {
        do {
            return try ModelContainerConfiguration.makeReadOnly()
        } catch {
            lastError = error
            try await Task.sleep(nanoseconds: UInt64(100_000_000 * (1 << attempt))) // 100ms, 200ms, 400ms
        }
    }
    throw lastError!
}
```

#### Extension memory constraint

The Index Extension process has a **6 MB memory limit** enforced by the OS. Indexing a large habit archive (1000+ completions) must be done in batches of ≤ 100 items. Exceeding the memory limit causes a silent termination — the acknowledgement handler is never called, and CoreSpotlight retries the reindex later.

### 8.15 Files App Integration

HabitKit declares a document provider. The app's container is accessible from the Files app. Users can:
- Browse and open `.habit` template files
- Export habit history as JSON or CSV
- Back up the full archive as `.habitarchive` (a ZIP bundle containing history, metadata, and completion photos)
- Import templates from any Files-accessible location (iCloud Drive, local storage, third-party providers)

### 8.16 EventKit — Calendar & Reminders Integration

HabitKit uses EventKit for two purposes: surfacing habits as calendar events and reading the user's calendar load to power the correlation engine.

**Calendar write:** When a habit has a fixed time, the user can opt in to creating a calendar event for it. The event is created in the user's selected calendar via `EKEventStore`. HabitKit does not create a custom calendar by default — it writes to an existing user-selected calendar to avoid calendar list pollution.

```swift
import EventKit

func createCalendarEvent(for habit: Habit, on date: Date) async throws {
    let store = EKEventStore()
    try await store.requestWriteOnlyAccessToEvents()
    let event = EKEvent(eventStore: store)
    event.title = habit.name
    event.startDate = date
    event.endDate = date.addingTimeInterval(Double(habit.estimatedDurationSeconds ?? 1800))
    event.calendar = store.defaultCalendarForNewEvents
    try store.save(event, span: .thisEvent)
}
```

**Calendar read (correlation):** The analytics engine can optionally correlate habit completion rates with calendar busyness. On days with 3+ calendar events, does the user complete fewer habits? This is opt-in and uses `requestFullAccessToEvents()`. The app reads event counts only — never event titles, attendees, or notes.

**Reminders write:** A habit with no fixed time can be written as an EKReminder rather than a calendar event. The reminder appears in the Reminders app and triggers via the system reminder infrastructure.

**Privacy:** `NSCalendarsWriteOnlyAccessUsageDescription` and `NSCalendarsFullAccessUsageDescription` are both declared in `Info.plist`. Write-only access is requested first; full access is only requested if the user enables the correlation feature.

### 8.17 TipKit — Contextual Onboarding

HabitKit uses TipKit for contextual feature discovery. Tips appear inline, at the right moment, and only once. No modal onboarding flows, no tutorial screens.

```swift
import TipKit

struct HabitTemplateTip: Tip {
    var title: Text { Text("Import a template") }
    var message: Text? {
        Text("Tap + then 'From Template' to start with a pre-configured habit.")
    }
    var image: Image? { Image(systemName: "square.and.arrow.down") }

    var rules: [Rule] {
        [
            #Rule(Self.$hasCreatedHabit) { $0 == false },
            #Rule(Self.$appLaunchCount) { $0 >= 2 }
        ]
    }

    @Parameter static var hasCreatedHabit: Bool = false
    @Parameter static var appLaunchCount: Int = 0
}
```

Tips are configured at app startup:

```swift
try? Tips.configure([
    .datastoreLocation(.applicationDefault),
    .displayFrequency(.immediate)
])
```

**Tips inventory:**

| Tip | Trigger condition | Location |
|---|---|---|
| Import a template | 2+ launches, no habit created | Empty Today view |
| Add a HealthKit link | Habit created, no HK configured | Habit detail |
| Enable geofence reminder | Location permission denied previously | Habit edit screen |
| Try double tap | Series 9+ Watch detected | Watch app first launch |
| Patreon support | 30+ days of use, 60%+ completion rate | Settings footer |

### 8.18 CoreHaptics — Haptic Design

All haptic feedback in HabitKit is authored via CoreHaptics, not the coarse `UIImpactFeedbackGenerator`. This allows precise, expressive feedback tied to the visual rhythm of the UI.

```swift
import CoreHaptics

final class HKHapticEngine {
    private var engine: CHHapticEngine?

    func prepare() throws {
        engine = try CHHapticEngine()
        try engine?.start()
        engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
        engine?.stoppedHandler = { reason in
            Logger.haptics.info("Engine stopped: \(reason.rawValue)")
        }
    }

    func playHabitComplete() throws {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [sharpness, intensity], relativeTime: 0)
        let pattern = try CHHapticPattern(events: [event], parameters: [])
        let player = try engine?.makePlayer(with: pattern)
        try player?.start(atTime: CHHapticTimeImmediate)
    }
}
```

**Haptic vocabulary:**

| Action | Pattern | Rationale |
|---|---|---|
| Habit complete | Single sharp transient | Decisive, satisfying |
| Habit skipped | Soft rumble, 200ms | Acknowledgement without negativity |
| Streak milestone | Three-tap ascending | Celebratory without being annoying |
| Timer tick (every 10s) | Faint continuous | Ambient awareness during Live mode |
| Delete (swipe confirm) | Sharp + soft decay | Warns before the action completes |

Haptics respect the system haptics switch. `CHHapticEngine.capabilitiesForHardware().supportsHaptics` is always checked before playback.

### 8.19 BGContinuedProcessingTask (iOS 26)

iOS 26 introduces `BGContinuedProcessingTask` — a new background task type that allows longer-running on-device work when the device is connected to power and the user is not actively using it. This replaces the need for `BGProcessingTask` + heuristic scheduling for HealthKit auto-completion.

```swift
import BackgroundTasks

// Registration
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.habitkit.healthkit-sync",
    using: nil
) { task in
    guard let continuedTask = task as? BGContinuedProcessingTask else { return }
    Task {
        await HealthKitAutoCompletionEngine.shared.runFullSync()
        continuedTask.setTaskCompleted(success: true)
    }
}

// Scheduling — call from sceneDidEnterBackground
func scheduleContinuedProcessingTask() {
    let request = BGContinuedProcessingTaskRequest(identifier: "com.habitkit.healthkit-sync")
    request.requiresNetworkConnectivity = false
    request.requiresExternalPower = true
    try? BGTaskScheduler.shared.submit(request)
}
```

`BGContinuedProcessingTask` is declared in `Info.plist` under `BGTaskSchedulerPermittedIdentifiers`. The OS schedules it opportunistically — typically overnight when charging. HabitKit uses it for:
1. HealthKit auto-completion batch processing
2. Spotlight index rebuild if the incremental index has drifted
3. Foundation Models weekly summary pre-generation (cached so it appears instantly Sunday morning)

### 8.20 Translation (iOS 17+)

HabitKit uses the `Translation` framework for on-device translation of completion notes and habit names shared via `.habit` files from non-native speakers.

```swift
import Translation

func translateNote(_ note: String, to targetLanguage: Locale.Language) async throws -> String {
    let config = TranslationSession.Configuration(target: targetLanguage)
    let session = try TranslationSession(configuration: config)
    let response = try await session.translate(note)
    return response.targetText
}
```

Translation runs fully on-device using downloaded language packs. No text is sent to Apple's servers for translation. The framework downloads the required language model lazily on first use — this may take a few seconds on first invocation. Subsequent calls are near-instant.

**Use cases:**
- Translating a received `.habit` file's name and description to the device language
- Offering to translate a completion note when the system detects it is in a different language than the device locale

### 8.21 CKShare — CloudKit Sharing

Users can share individual habits or habit packs with specific people via CloudKit sharing. The share recipient does not need HabitKit installed — they receive a universal link that deep-links into the App Store then into the habit import flow.

```swift
import CloudKit

func shareHabit(_ habit: Habit, container: CKContainer) async throws -> CKShare {
    let record = try await fetchCKRecord(for: habit, in: container)
    let share = CKShare(rootRecord: record)
    share[CKShare.SystemFieldKey.title] = "HabitKit: \(habit.name)" as CKRecordValue
    share[CKShare.SystemFieldKey.shareType] = "com.habitkit.habit" as CKRecordValue
    share.publicPermission = .none  // private share — recipient must be explicitly added
    let (savedRecord, savedShare, _) = try await container.privateCloudDatabase.modifyRecords(
        saving: [record, share],
        deleting: []
    )
    return savedShare as? CKShare ?? share
}
```

The share is presented via `UICloudSharingController` (UIKit) or the SwiftUI equivalent. The recipient accepts via a `CKAcceptSharesOperation`. HabitKit handles the `userDidAcceptCloudKitShareWith` scene delegate callback.

**Scope:** Individual habit sharing, not full library sync. Library sync is handled by SwiftData + CloudKit private database, which is per-user only.

### 8.22 ShazamKit — Audio Recognition for Workout Habits

HabitKit integrates ShazamKit as an opt-in feature for workout habits. When a user starts a workout habit session, they can enable "match workout music" — the app recognises the track playing via the microphone and logs it as metadata on the completion record.

```swift
import ShazamKit

final class HabitShazamMatcher: NSObject, SHSessionDelegate {
    private let session = SHSession()

    func startMatching() throws {
        session.delegate = self
        let audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 8192, format: format) { [weak self] buffer, _ in
            self?.session.matchStreamingBuffer(buffer, at: nil)
        }
        try audioEngine.start()
    }

    func session(_ session: SHSession, didFind match: SHMatch) {
        guard let item = match.mediaItems.first else { return }
        NotificationCenter.default.post(
            name: .habitShazamDidMatch,
            object: HabitShazamResult(title: item.title, artist: item.artist, artworkURL: item.artworkURL)
        )
    }
}
```

**Privacy:** `NSMicrophoneUsageDescription` is already declared for AlarmKit. ShazamKit uses microphone access only during an active habit session when explicitly enabled by the user. Matched data is stored locally only — it is not sent to the Shazam catalog servers beyond the matching request itself.

### 8.23 CryptoKit — Export Encryption

When the user exports a `.habitarchive` file, they can optionally encrypt it with a passphrase. HabitKit uses CryptoKit for this — no third-party crypto library required.

```swift
import CryptoKit

func encryptArchive(data: Data, passphrase: String) throws -> Data {
    let passphraseData = Data(passphrase.utf8)
    let salt = SymmetricKey(size: .bits256)  // stored in archive header
    // Derive key using HKDF
    let key = HKDF<SHA256>.deriveKey(
        inputKeyMaterial: SymmetricKey(data: passphraseData),
        salt: salt.withUnsafeBytes { Data($0) },
        outputByteCount: 32
    )
    let sealedBox = try AES.GCM.seal(data, using: key)
    return sealedBox.combined ?? Data()
}

func decryptArchive(encryptedData: Data, passphrase: String, salt: Data) throws -> Data {
    let passphraseData = Data(passphrase.utf8)
    let key = HKDF<SHA256>.deriveKey(
        inputKeyMaterial: SymmetricKey(data: passphraseData),
        salt: salt,
        outputByteCount: 32
    )
    let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
    return try AES.GCM.open(sealedBox, using: key)
}
```

The passphrase never leaves the device. The archive format includes a version header, the salt (unencrypted), and the AES-GCM sealed box. Import prompts for the passphrase and decrypts locally.

### 8.24 Vision — Deferred (Not v1)

Vision framework integration (for photo-based habit completion verification — e.g., recognising a made bed from a photo) is explicitly deferred from v1. The API exists and works, but the UX implications of "AI that judges whether your bed is made" are not well understood. This is a research item, not a shipping commitment.

When revisited, the implementation would use `VNClassifyImageRequest` with a custom Core ML model fine-tuned on habit-relevant scene categories. The model would run entirely on-device via the Neural Engine.

### 8.25 JournalingSuggestions — Completion Prompts

On devices running iOS 17.2+, HabitKit requests access to the Journaling Suggestions API. When a habit is completed, the app checks if there are relevant suggestions (workout data, location, photos from that time period) and surfaces them as optional context for the completion note.

```swift
import JournalingSuggestions

func fetchSuggestions(for completion: HabitCompletion) async -> [JournalingSuggestion] {
    let picker = JournalingSuggestionsPicker()
    // The picker is presented as a sheet — user selects which suggestions to attach
    // We do not access suggestions without explicit user selection
    return []  // Placeholder — suggestions flow through the picker UI, not direct API
}
```

The Journaling Suggestions API does not allow background access — all suggestion data is accessed through the system-provided `JournalingSuggestionsPicker` UI component. HabitKit surfaces this picker as an optional "Add context" button in the completion note screen.

### 8.26 HealthKit Medication Logging

HabitKit supports medication habits that write to HealthKit's medication log (iOS 16+). When a checklist habit is tagged as "medication", completions write an `HKMedicationDoseEvent` sample.

```swift
let medicationIdentifier = HKQuantityTypeIdentifier(rawValue: HKCategoryTypeIdentifier.medicationDose.rawValue)
// Note: exact API surface TBD — medication logging API details were in beta as of design writing
// The habit type is modelled; the HK write is feature-flagged behind an iOS version check
```

This is an additive feature. The habit functions as a standard checklist habit on devices where the HealthKit medication API is unavailable or the entitlement is not granted.

### 8.27 MetricKit — Crash and Performance Reporting

HabitKit uses `MXMetricManager` to receive aggregated performance and crash reports. This is the privacy-preserving alternative to third-party crash SDKs.

```swift
import MetricKit

final class HKMetricSubscriber: NSObject, MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            // Log CPU time, memory, hang rate, launch time to local analytics store
            let report = HKPerformanceReport(
                cpuTime: payload.cpuMetrics?.cumulativeCPUTime.converted(to: .seconds).value,
                memoryPeakBytes: payload.memoryMetrics?.peakMemoryUsage.converted(to: .bytes).value,
                launchTime: payload.applicationLaunchMetrics?.histogrammedTimeToFirstDraw.bucketEnumerator.nextObject()
            )
            PerformanceStore.shared.save(report)
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            // Crash logs, hang diagnostics — logged locally, surfaced in debug Settings
            if let crashDiagnostics = payload.crashDiagnostics {
                CrashStore.shared.save(crashDiagnostics)
            }
        }
    }
}
```

MetricKit payloads arrive at most once per day, aggregated across multiple users. No individual user data is identifiable. Reports are stored in SwiftData and viewable in a debug-only Settings pane.

Register the subscriber at app startup:

```swift
MXMetricManager.shared.add(metricSubscriber)
```

### 8.28 BackgroundAssets — Theme Pack Downloads

When new community themes are available, HabitKit uses the BackgroundAssets framework to download `themes.json` updates in the background, before the user opens the app.

```swift
import BackgroundAssets

// BADownloaderExtension target
final class HabitKitAssetDownloader: BADownloaderExtension {
    func applicationDidInstall(_ manifestURL: URL) {
        scheduleThemeUpdate()
    }

    private func scheduleThemeUpdate() {
        let download = BAURLDownload(
            identifier: "com.habitkit.themes-update",
            request: URLRequest(url: URL(string: "https://raw.githubusercontent.com/habitkit/themes/main/themes.json")!),
            applicationGroupIdentifier: "group.com.habitkit.app"
        )
        BADownloadManager.shared.schedule(download)
    }

    func download(_ download: BADownload, didReceive fileURL: URL) {
        // themes.json is now in the app group container — main app picks it up on next launch
        let dest = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.habitkit.app")!
            .appendingPathComponent("themes.json")
        try? FileManager.default.replaceItem(at: dest, withItemAt: fileURL, backupItemName: nil, options: [], resultingItemURL: nil)
    }
}
```

BackgroundAssets requires the `com.apple.developer.background-assets` entitlement and a `BAInitialDownloadRestrictions` configuration in `Info.plist`. The downloaded file size must be declared.

### 8.29 NSFilePresenter — Live Template Sync

When the user has a `.habit` file open in Files app and another device modifies it via iCloud, HabitKit's `NSFilePresenter` implementation receives the change notification and offers to update the local habit.

```swift
import Foundation

final class HabitFilePresenter: NSObject, NSFilePresenter {
    let presentedItemURL: URL?
    let presentedItemOperationQueue: OperationQueue = .main

    init(fileURL: URL) {
        self.presentedItemURL = fileURL
        super.init()
        NSFileCoordinator.addFilePresenter(self)
    }

    func presentedItemDidChange() {
        // File was modified externally — reload and offer import
        NotificationCenter.default.post(name: .habitFileDidChange, object: presentedItemURL)
    }

    deinit {
        NSFileCoordinator.removeFilePresenter(self)
    }
}
```

All file reads and writes go through `NSFileCoordinator` to prevent conflicts with iCloud Drive sync and the Index Extension.

### 8.30 MultipeerConnectivity — Local Habit Sharing

Users on the same local network or in Bluetooth range can share habits directly without iCloud. HabitKit uses MultipeerConnectivity for peer-to-peer `.habit` file transfer.

```swift
import MultipeerConnectivity

final class HabitPeerSession: NSObject {
    let peerID = MCPeerID(displayName: UIDevice.current.name)
    let serviceType = "habitkit-share"

    lazy var session: MCSession = MCSession(
        peer: peerID,
        securityIdentity: nil,
        encryptionPreference: .required
    )
    lazy var advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
    lazy var browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
}
```

The share flow: sender taps "Share via AirDrop-style" → browser discovers nearby peers → recipient accepts → `.habit` file transfers → recipient's app shows import confirmation sheet.

MultipeerConnectivity is used only for this explicit share action — it does not run in the background and does not poll for nearby devices passively.

### 8.31 SensitiveContentAnalysis — Completion Photos

When a user attaches a photo to a habit completion, HabitKit runs it through `SensitiveContentAnalysis` before storing it. This is a safety check for apps that handle user-generated photos.

```swift
import SensitiveContentAnalysis

func analyzeCompletionPhoto(_ image: UIImage) async throws -> Bool {
    let analyzer = SCSensitivityAnalyzer()
    guard analyzer.analysisPolicy != .disabled else { return true }  // feature off — allow
    let response = try await analyzer.analyzeImage(image.cgImage!)
    return !response.isSensitive  // true = safe to store
}
```

If the analysis returns sensitive, the photo is not stored and the user is shown a non-alarming message. The analysis runs on-device. No image data leaves the device.

### 8.32 SharedWithYou — Habit Pack Links

When someone shares a HabitKit universal link (pointing to a `.habit` or habit pack) via Messages, the link appears in a `SharedWithYouShelf` in the app's Discover tab. The user can tap it to import the shared habit without leaving HabitKit.

```swift
import SharedWithYou

struct SharedHabitsShelf: View {
    @State private var highlights: [SWHighlight] = []

    var body: some View {
        if !highlights.isEmpty {
            SWHighlightCenter.shared // exposes highlights via async stream
            // Render each highlight as a habit pack preview card
        }
    }
}
```

`NSSupportsCollaborationMetadata` is declared in `Info.plist`. HabitKit registers its universal link domain for SharedWithYou attribution.

### 8.33 IdentityLookup — Spam Notification Filtering

HabitKit ships an `ILMessageFilterExtension` that prevents habit reminder notifications from being silenced by iOS spam filtering heuristics. Without this extension, iOS's on-device message classification may incorrectly suppress time-sensitive habit reminders.

The extension declares itself as a trusted notification sender for HabitKit's bundle identifier. No message content is read by the extension — it only handles the allow/filter decision for HabitKit's own notification category identifiers.

### 8.34 CoreNFC / PassKit — Habit Tap Triggers

Advanced users can configure an NFC tag or an Apple Wallet pass as a habit trigger. Tapping the tag or scanning the pass logs the habit completion without opening the app.

**NFC:** Uses `NFCNDEFReaderSession`. The tag contains a HabitKit deep link URL (`habitkit://log?habitID=UUID`). When tapped, iOS routes the URL to HabitKit's `onOpenURL` handler and `LogHabitIntent` fires.

**PassKit:** A Wallet pass with a companion app button. The button invokes `LogHabitIntent` via an `AppIntent` declared in the pass's JSON. The pass updates its "last logged" date field via `PKPassLibrary` after each completion.

Both mechanisms require the app to be installed. Neither requires the app to be open or the screen to be unlocked (NFC triggers work from the Lock Screen if the habit intent is marked as requiring no authentication for read-only data).

### 8.35 LocalAuthentication + SecureEnclave — Archive Encryption Key Storage

When the user enables passphrase-free encrypted exports (using Face ID/Touch ID instead of a typed passphrase), the AES-GCM encryption key is stored in the Secure Enclave via `LocalAuthentication` and `SecKey`.

```swift
import LocalAuthentication
import Security

func storeEncryptionKey(_ key: SymmetricKey) throws {
    let context = LAContext()
    let accessControl = SecAccessControlCreateWithFlags(
        nil,
        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        [.privateKeyUsage, .biometryCurrentSet],
        nil
    )!
    let query: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrApplicationTag as String: "com.habitkit.archivekey",
        kSecAttrAccessControl as String: accessControl,
        kSecValueData as String: key.withUnsafeBytes { Data($0) },
        kSecUseAuthenticationContext as String: context
    ]
    SecItemDelete(query as CFDictionary)  // remove old key if present
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else { throw HKKeychainError.storeFailed(status) }
}
```

`.biometryCurrentSet` means the key is invalidated if the user adds or removes a biometric enrollment — a deliberate security choice. The user is prompted to re-encrypt their archive after a biometry change.

### 8.36 CoreML — On-Device Habit Clustering

HabitKit ships a lightweight CoreML model (`HabitCluster.mlmodel`, ~2MB) that clusters the user's habits into behavioral groups based on completion time, duration, and co-completion patterns. The clustering informs the Analytics view's "Your habit groups" section.

```swift
import CoreML

func clusterHabits(completions: [HabitCompletionVector]) throws -> [HabitCluster] {
    let model = try HabitClusterModel(configuration: MLModelConfiguration())
    let input = HabitClusterModelInput(vectors: completions.asCoreMLArray())
    let output = try model.prediction(input: input)
    return output.clusters.toHabitClusters()
}
```

The model is trained offline on synthetic data. No user data is used for training. The model ships in the app bundle and is updated with app updates — no model download at runtime.

### 8.37 WeatherKit — Weather-Habit Correlation

With user permission, HabitKit correlates outdoor habit completion rates with weather conditions. The Analytics view can show "You complete your run 40% less often on rainy days."

```swift
import WeatherKit
import CoreLocation

func fetchWeatherForCorrelation(location: CLLocation, date: Date) async throws -> HKWeatherSnapshot {
    let service = WeatherService()
    let weather = try await service.weather(for: location, including: .daily)
    guard let dayWeather = weather.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else {
        throw WeatherError.noDataForDate
    }
    return HKWeatherSnapshot(
        condition: dayWeather.condition,
        highTemperature: dayWeather.highTemperature,
        precipitationChance: dayWeather.precipitationChance
    )
}
```

WeatherKit requires the `com.apple.developer.weatherkit` entitlement and an active Apple Developer Program membership. The entitlement is a standard capability — no special approval needed.

**Privacy:** WeatherKit requires location. HabitKit uses "When In Use" location authorization already declared for geofencing. Weather data is fetched for dates in the past (for correlation) using a saved approximate location — the precise GPS coordinate is not stored, only the city-level locality.

### 8.38 CoreMIDI — Habit Sound Cues (Power User Feature)

Expert users with MIDI instruments (or MIDI-capable apps via virtual MIDI ports) can configure a habit to trigger a MIDI note when completed. This is an extreme niche feature for musicians tracking practice habits — completing a "practice piano" habit sends a celebratory chord to the connected instrument.

```swift
import CoreMIDI

func sendHabitCompleteChord(client: MIDIClientRef, port: MIDIPortRef, destination: MIDIEndpointRef) {
    let notes: [UInt8] = [60, 64, 67]  // C major chord
    for note in notes {
        var packet = MIDIPacket()
        packet.timeStamp = 0
        packet.length = 3
        packet.data.0 = 0x90  // Note On, channel 1
        packet.data.1 = note
        packet.data.2 = 100   // velocity
        var packetList = MIDIPacketList(numPackets: 1, packet: packet)
        MIDISend(port, destination, &packetList)
    }
}
```

CoreMIDI integration is a Settings toggle, off by default, shown only if a MIDI destination is detected. It does not appear in the standard Settings UI.

### 8.39 CMHeadphoneMotionManager — Head Nod Gestures

On AirPods Pro (2nd gen+) and AirPods Max, HabitKit can optionally detect head nod gestures to log a habit completion. A double nod confirms the habit; a single left-right shake dismisses the reminder notification.

```swift
import CoreMotion

final class HKHeadphoneGestureDetector {
    private let manager = CMHeadphoneMotionManager()

    func startDetecting() {
        guard CMHeadphoneMotionManager.isDeviceMotionAvailable else { return }
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion else { return }
            self?.processMotion(motion)
        }
    }

    private func processMotion(_ motion: CMDeviceMotion) {
        // Detect nod: rotationRate.x > threshold for ~200ms
        if abs(motion.rotationRate.x) > 2.0 {
            NotificationCenter.default.post(name: .headphoneNodDetected, object: nil)
        }
    }
}
```

This feature is off by default and opt-in. It is surfaced only when AirPods with head gesture support are connected. The motion data is processed in-memory and never stored.

### 8.40 EnergyKit (iOS 26) — Power-Aware Scheduling

iOS 26's EnergyKit allows apps to schedule work during low-carbon, low-cost energy windows. HabitKit uses this for CloudKit sync and Spotlight index rebuilds — work that can be deferred without impacting the user experience.

```swift
import EnergyKit

func scheduleCloudKitSync() async {
    let schedule = EKSchedule(
        workIdentifier: "com.habitkit.cloudkit-sync",
        estimatedDuration: .seconds(30),
        flexibility: .flexible(within: .hours(4))
    )
    try? await EKScheduler.shared.schedule(schedule) {
        await CloudKitSyncEngine.shared.performSync()
    }
}
```

EnergyKit integration is transparent to the user — the sync happens when the OS determines it is environmentally optimal, within the flexibility window. If the window expires, the sync runs anyway.

### 8.41 LinkPresentation — Rich Habit Pack Previews

When a `.habit` or `.habitarchive` file is shared via Messages, Mail, or any share sheet, HabitKit provides a rich preview using `LinkPresentation`.

```swift
import LinkPresentation

final class HabitLinkMetadataProvider: LPMetadataProvider {
    func metadata(for habit: Habit) -> LPLinkMetadata {
        let metadata = LPLinkMetadata()
        metadata.title = habit.name
        metadata.imageProvider = NSItemProvider(object: UIImage(systemName: habit.icon) ?? UIImage())
        metadata.url = URL(string: "https://habitkit.app/habits/\(habit.id)")
        return metadata
    }
}
```

In share sheets, this produces a card with the habit name, icon, and a HabitKit branding element rather than a raw file attachment icon. The URL resolves to a universal link that opens the import flow.

### 8.42 PencilKit — Handwritten Completion Notes

On iPad and iPhone 16+ (Pencil Pro support), habit completion notes can be entered as handwritten ink using PencilKit. The ink is stored as `PKDrawing` data alongside the text transcription (produced by the on-device handwriting recognition engine).

```swift
import PencilKit

struct HandwrittenNoteView: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.tool = PKInkingTool(.pen, color: .label, width: 2)
        canvas.drawingPolicy = .pencilOnly
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if canvas.drawing != drawing { canvas.drawing = drawing }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: HandwrittenNoteView
        init(_ parent: HandwrittenNoteView) { self.parent = parent }
        func canvasViewDrawingDidChange(_ canvas: PKCanvasView) {
            parent.drawing = canvas.drawing
        }
    }
}
```

The `PKDrawing` is serialized and stored in the `HabitCompletion.note` field alongside the transcribed text. The handwriting recognition uses `VNRecognizeTextRequest` on the rendered drawing image. Both the ink and the transcription are stored — the ink for fidelity, the transcription for Spotlight indexing.

### 8.43 CarPlay — Commute Context Dashboard

The morning commute is one of the densest windows for consecutive daily habits. CarPlay surfaces HabitKit in the vehicle's head unit display. HabitKit uses only the path that does not require special Apple approval in v1.

#### The entitlement reality

A full CarPlay template app (`CPTemplateApplicationSceneDelegate`) requires a category-specific entitlement. The approved categories are Audio, Communication, EV Charging, Navigation, Parking, and Quick Food Ordering. A habit tracker fits none of these. The template app path is documented here for a future entitlement application, but is not the v1 implementation.

#### Tier 1 — WidgetKit (no entitlement required, ships in v1)

HabitKit's WidgetKit widgets render in CarPlay's Dashboard natively as of iOS 16+. No additional code is required beyond what is already implemented for the home screen and Lock Screen widgets. The CarPlay widget surface is glanceable — display-only, no tap targets.

#### Tier 2 — Live Activities (no entitlement required, ships in v1)

An active `TimedHabit` Live Activity renders on the CarPlay dashboard during the commute. This is already implemented as part of §8.1 ActivityKit. Nothing additional is needed for CarPlay Live Activity support.

#### Tier 3 — Full template app (entitlement required, post-v1)

If Apple grants a CarPlay entitlement — strongest case: framing HabitKit as a wellness/productivity utility — the template app enables one-tap habit completion directly on the head unit display.

```swift
import CarPlay
final class HKCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        interfaceController.setRootTemplate(buildRootTemplate(), animated: false, completion: nil)
    }
    private func buildRootTemplate() -> CPTemplate {
        let items = TodayHabitService.shared.todaysHabits.map { habit in
            CPListItem(
                text: habit.name,
                detailText: habit.isCompletedToday ? "✓ Done" : "\(habit.streak) day streak",
                image: habit.isCompletedToday
                    ? UIImage(systemName: "checkmark.circle.fill")
                    : UIImage(systemName: "circle")
            )
        }
        let section = CPListSection(items: items)
        return CPListTemplate(title: "Today's Habits", sections: [section])
    }
}
```

#### Template constraints — no exceptions

The permitted templates for a general/productivity entitlement are: `CPListTemplate`, `CPInformationTemplate`, `CPAlertTemplate`, `CPTabBarTemplate`. No custom SwiftUI, no lists longer than 12 items, no auto-dismissing alerts, no text input of any kind.

#### Driver safety constraints

Any CarPlay UI that requires more than a single tap to complete an interaction will be rejected by App Review. The completion flow is: tap habit name → system confirms → done. Nothing more.

#### Entitlement application strategy

Apply via `developer.apple.com/carplay`. Category: **General**. Safety argument: all interactions are single-tap, no text input, glanceable display only. Apply early — the review process can take 4–8 weeks.

---

## 9. Settings Architecture

### 9.1 Settings.bundle (iOS Settings app)

HabitKit has a `Settings.bundle` entry in the iOS Settings app. Per the Apple Human Interface Guidelines, only infrequently accessed preferences live here. Frequently used settings (themes, per-habit configuration) are in-app only.

**Settings.bundle contents:**

| Control | Type | Key |
|---|---|---|
| App version | Read-only title | `hk_version` (auto-set via build phase) |
| Build number | Read-only title | `hk_build` (auto-set via build phase) |
| iCloud Sync | Toggle | `hk_icloud_sync` |
| Notifications | Link → openSettingsURLString | — |
| Reset All Data | Toggle (action) | `hk_reset_flag` |
| Privacy Policy | Child pane | — |
| Open Source Licenses | Child pane | — |

**Debug-only (stripped in release via build phase script):**

| Control | Type |
|---|---|
| Override theme | Multi-value |
| Simulate HealthKit failure | Toggle |
| Clear UserDefaults | Toggle |
| CloudKit environment | Multi-value (dev/prod) |

### 9.2 Preferences Data Flow

```
Settings.app ←→ UserDefaults.standard ←→ @AppStorage / @CloudStorage
                                                    ↓
                                       NSUbiquitousKeyValueStore
                                                    ↓
                                         Other devices' UserDefaults
```

`Settings.bundle` keys and in-app `@AppStorage` keys are **identical strings**. One key, two surfaces, one `UserDefaults` store. No duplicated keys.

Default values are registered at app launch before any reads:

```swift
UserDefaults.standard.register(defaults: [
    "hk_icloud_sync": true,
    "hk_haptics_enabled": true,
    "hk_selected_theme": "catppuccin-mocha",
    "hk_notification_sound": "default"
])
```

### 9.3 Cross-Device Sync for Preferences

Preferences (not habit data) sync via `NSUbiquitousKeyValueStore` using the `@CloudStorage` property wrapper (open source, Tom Lokhorst). Habit data syncs via CloudKit/SwiftData. These are separate mechanisms.

| Preference | Sync mechanism |
|---|---|
| Selected theme | `@CloudStorage` |
| Haptics on/off | `@CloudStorage` |
| Notification preferences | `@CloudStorage` |
| iCloud sync toggle | `@CloudStorage` |
| Per-habit settings | SwiftData + CloudKit |

`NSUbiquitousKeyValueStore.default.synchronize()` is called in `sceneDidBecomeActive` to pull any changes made on other devices while this device was backgrounded.

---

## 10. Privacy

HabitKit is private by design, not by policy.

- **No account required.** The app functions fully without iCloud. Sync is opt-in.
- **No analytics SDK.** No Firebase, no Mixpanel, no Amplitude. Zero third-party data collection.
- **No crash SDK.** Crash reporting uses `MetricKit` (`MXMetricManager`). Reports are on-device and privacy-preserving. No data leaves the device via a third-party SDK.
- **HealthKit data never leaves the device.** All HealthKit reads and writes are local. No HealthKit data is synced to HabitKit servers (there are none).
- **Foundation Models run on-device.** No inference data is sent to external servers.
- **Screen Time data never leaves the device.** `DeviceActivityReport` renders on-device. No usage data is accessible to HabitKit's app code — only the derived pass/fail of the habit threshold.
- **Privacy Nutrition Label:** Accurate. The app collects nothing from users for tracking or analytics purposes.

**Privacy Manifest (`PrivacyInfo.xcprivacy`)** is included and accurate. Required reason APIs are declared. This is mandatory for App Store submission as of 2024.

---

## 11. Analytics (On-Device Only)

All analytics are computed locally from SwiftData. No data leaves the device for analytics purposes.

Features:
- Streak tracking (current and longest)
- Heatmap calendar (GitHub-style contribution graph per habit)
- Completion rate over time (7-day, 30-day, 90-day)
- Best time of day (when the user historically completes each habit)
- Correlation view (does completing habit A correlate with completing habit B?)
- Goal linkage (attach habits to a named goal; analytics show habit → goal progress)
- Streak archaeology (the exact date a streak broke, with an optional note field)
- Weekly natural language summary (Foundation Models, on-device)

---

## 12. Completion Types

| Type | Description | HealthKit write |
|---|---|---|
| Yes/No | Simple binary completion | Varies by habit |
| Timed | Duration-based; starts Live Activity | `HKWorkout` or `HKMindfulSession` |
| Quantity | Numeric value ("8 glasses", "30 pages") | `HKQuantitySample` |
| Checklist | Sub-steps, all must be checked | None |
| Photo | Completion requires attaching a photo | None |
| Location check-in | Completion triggered by arriving at saved location | None |
| Negative | Tracks avoidance; missed = did the thing | None |
| Auto (HealthKit) | Completes automatically when HK threshold met | Read-only |
| Auto (Pedometer) | Completes when step goal met via CMPedometer | Read-only |
| Screen Time | Completes when below daily app usage limit | Read-only |

---

## 13. Information Architecture

```
Tab Bar
├── Today           — all habits due today, sorted by schedule
├── Habits          — all habits, manage/archive/reorder
├── Analytics       — stats, heatmaps, correlation, goal tracker
├── Live            — active timed habit session (fullscreen)
└── Settings        — themes, notifications, HealthKit, Files, iCloud
```

**Today view states:**
- Empty state (no habits): onboarding prompt with template gallery link
- All complete: celebration state with Catppuccin accent animation
- Partial: incomplete habits at top, completed below with muted styling
- Missed: negative habit markers in warning color, not danger (no guilt framing)

**Live mode:** A fullscreen active-session view showing the in-progress habit's name, elapsed/remaining time, a large circular progress ring, a notes field, and a prominent "Complete" button. Designed to stay on screen like a workout app. The Live Activity mirrors this state to the Lock Screen and Dynamic Island simultaneously.

---

## 14. Entitlements Required

| Entitlement | Purpose | Requires Apple approval |
|---|---|---|
| `com.apple.developer.family-controls` | Screen Time / DeviceActivity | Yes — apply at developer.apple.com |
| `com.apple.developer.healthkit` | HealthKit read/write | No — standard entitlement |
| `com.apple.developer.usernotifications.time-sensitive` | AlarmKit + critical habit alerts | No — standard entitlement |
| iCloud (CloudKit) | SwiftData sync | No — standard capability |
| App Groups | Shared UserDefaults with extensions | No — standard capability |
| Background Modes (fetch, processing, remote-notification) | HealthKit auto-completion, CloudKit sync | No — standard capability |

---

## 15. Open Source & Contribution Rules

Defined in `CONTRIBUTING.md` before the first public PR is accepted.

**In scope for contributions:**
- New habit completion types
- HealthKit mappings for additional data types
- Shortcuts / AppIntents depth
- Analytics views
- Community theme submissions
- Watch complication layouts
- Bug fixes

**Out of scope (will be rejected with written rationale):**
- Social features, sharing to third-party platforms
- Gamification (points, levels, badges)
- Onboarding coach / tutorial screens
- Any feature requiring a server or account
- Third-party SDK integrations
- Android / React Native ports

**Code review requirements for all PRs:**
- All UI must use `HKTheme` tokens. No hardcoded colors.
- All type must use `hk*` font extensions. No hardcoded `Font.body`.
- No third-party dependencies added without maintainer approval.
- SwiftLint passes with project configuration.
- Swift 6 strict concurrency: no `@unchecked Sendable` without justification.

---

## 16. Accessibility

HabitKit targets WCAG 2.1 AA as a floor, with AA+ outcomes wherever SwiftUI enables them at no additional cost. Accessibility is not a post-ship polish pass — it is a PR acceptance criterion.

### 16.1 VoiceOver

Every interactive element has a meaningful accessibility label. The label is never the SF Symbol name — it is the semantic meaning of the element.

```swift
// Wrong
Image(systemName: "checkmark.circle.fill")

// Correct
Image(systemName: "checkmark.circle.fill")
    .accessibilityLabel("Mark \(habit.name) complete")
    .accessibilityHint("Double-tap to log today's completion")
    .accessibilityAddTraits(.isButton)
```

**Habits list:** Each row announces the habit name, today's completion state, and current streak. Example: "Morning Run, not completed, 14-day streak."

**Completion ring widget:** The ring announces as "Today's progress: 5 of 8 habits complete, 62 percent."

**Heatmap calendar:** Each cell announces the date and completion count. The heatmap is also available as a list view (accessibility alternate rendering) for users who cannot interpret a visual grid.

**Live Activity / Dynamic Island:** VoiceOver on the Lock Screen reads the remaining time and habit name. The "Complete" button in the expanded island is fully accessible.

### 16.2 Dynamic Type

All type in HabitKit scales with Dynamic Type, including Accessibility sizes (up to AX5). No layout clips or truncates at any size.

- Labels use `lineLimit(nil)` or explicit multi-line support where content may wrap
- Icons scale proportionally using `.font(.title)` rather than fixed `.frame(width: 44)` for icon-only buttons
- Cards reflow to vertical stacks at Accessibility Large sizes using `@ScaledMetric` for spacing

```swift
@ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 16
```

### 16.3 Contrast

All text/background combinations meet WCAG AA (4.5:1 for normal text, 3:1 for large text). The Catppuccin palette was chosen in part for its deliberate contrast ratios. Community themes submitted to the gallery are validated against WCAG AA by a CI step before merge.

```bash
# CI theme contrast check (simplified)
node scripts/check-contrast.js themes/community/theme.json --min-ratio 4.5
```

### 16.4 Reduce Motion

All animations respect `@Environment(\.accessibilityReduceMotion)`. Animations are either disabled or replaced with cross-fades when Reduce Motion is enabled.

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

var completionAnimation: Animation {
    reduceMotion ? .linear(duration: 0.1) : .spring(response: 0.5, dampingFraction: 0.7)
}
```

The celebration state on "all habits complete" uses a confetti animation by default. With Reduce Motion, it shows a static "All done" message with the accent color.

### 16.5 Switch Control & Full Keyboard Access

All interactive elements are reachable via Switch Control. Custom swipe actions on habit rows (skip, delete) are exposed as accessibility actions:

```swift
.accessibilityAction(named: "Skip") { skipHabit(habit) }
.accessibilityAction(named: "Delete") { deleteHabit(habit) }
```

iPad and Mac (Catalyst) targets support full keyboard navigation. Focus order follows reading order. Custom keyboard shortcuts use `keyboardShortcut(_:modifiers:)` without conflicting with system shortcuts.

### 16.6 Siri & Voice Control

All app actions are reachable via Siri through the AppIntents defined in §8.3. Voice Control users can tap any visible label by name. Interactive elements have `accessibilityIdentifier` values set in tests but not shipped to production (they are stripped by the release build phase).

### 16.7 Colour Independence

No information is conveyed by colour alone. Every state that uses colour (completed = green, missed = orange, archived = dimmed) also uses a secondary cue — a checkmark icon, a strikethrough, an opacity change. The app is fully usable in greyscale mode.

---

## 17. Revision History

| Version | Date | Notes |
|---|---|---|
| 1.0 | May 2026 | Initial design document |
| 1.1 | May 2026 | §3 Rolling Minimum OS Policy; §7.3 Progressive Overload (scheduled + CoreML nudges, negative habit asymmetric mechanics); §7.2 updated Core Models (ProgressionPlan, ProgressionEvent, VisionProfile placeholder, HabitCompletion paperMarkup); §8.3 GetHabitsIntent expanded; §8.16–8.42 (EventKit, TipKit, CoreHaptics, BGContinuedProcessingTask, Translation, CKShare, ShazamKit, CryptoKit, Vision/deferred, JournalingSuggestions, HealthKit Medication, MetricKit, BackgroundAssets, NSFilePresenter, MultipeerConnectivity, SensitiveContentAnalysis, SharedWithYou, IdentityLookup, CoreNFC, LocalAuthentication+SecureEnclave, CoreML clustering, WeatherKit, CoreMIDI, CMHeadphoneMotionManager, EnergyKit, LinkPresentation, PaperKit); §8.43 CarPlay; §16 Accessibility; §18 Bundled Shortcuts (Archive Inspector, Accountability Check-In); monetization updated for Epic v. Apple ruling |
| 1.2 | May 2026 | PR #1 implementation: SwiftData schema fixes, HabitKitIntents package, test suite, CI coverage fix, ProgressionPlan/ProgressionEvent/NegativeProgressionPlan/VisionProfile models, GetDailyHabitSummaryIntent, InspectArchiveIntent, expanded GetHabitsIntent |

---

## 18. Bundled Shortcuts

HabitKit ships two pre-built Shortcuts users can add with a single tap from the app's Shortcuts page. Both are powered by AppIntents, run entirely on-device, and use existing OS channels — no HabitKit infrastructure required. Neither is forced on the user; both are opt-in.

### 18.1 Archive Inspector Shortcut

**Purpose:** Unzip a `.habitarchive` file and display a human-readable summary of its contents. Lets users verify their data export is complete and intact without writing code or using a command line.

**Why this matters:** HabitKit's privacy commitment is "you own your data." That claim is only meaningful if users can actually inspect what their data contains. A one-tap shortcut that opens an archive and shows exactly what's inside makes data ownership tangible and verifiable.

```
Shortcut: Inspect HabitKit Archive
Steps:
1. Get File (filter: .habitarchive)
2. InspectArchiveIntent (file: above)
3. Show Result:
   "Archive: [date range]
    [habitCount] habits
    [completionCount] completions
    [photoCount] photos
    [annotationCount] PaperKit annotations
    Schema version: [schemaVersion]
    Encrypted: [yes/no]"
4. Choose from menu:
   — Browse completion JSON for a specific habit
   — Export completions as CSV (passes to Numbers/Excel)
   — View attached photos (Quick Look gallery)
   — Done
```

The CSV export path is particularly useful for users who want to analyse their habit data in a spreadsheet. Numbers and Excel can receive the file directly from the Shortcut without HabitKit needing to implement a native export UI.

### 18.2 Accountability Check-In Shortcut

**Purpose:** Send a daily message to an accountability buddy listing which habits were and weren't completed, on a schedule the user sets.

**Why this approach is right:**

The Shortcut uses infrastructure that already exists — Messages for delivery, Shortcuts for scheduling, HabitKit's AppIntents for data — rather than building a social layer inside the app. The buddy doesn't need to install HabitKit. They don't need an account. They don't need to understand the app. They receive a text message in an existing conversation. The accountability relationship stays between two people, not mediated by a platform.

The schedule removes the willpower requirement. The hardest part of manual accountability reporting is sending the message on the days you failed. An automated Shortcut removes that obstacle — the message goes at 9pm regardless of how the day went.

Private Messages accountability is honest rather than performative. A private message to one specific chosen person is a fundamentally different social contract from a leaderboard or shared streak. It's not about looking good publicly; it's about not wanting to let down someone who knows you.

**The bundled Shortcut:**

```
Shortcut: Evening Habit Check-In
Trigger: Daily automation at [user-configured time, default 9:00pm]
Steps:
1. Get Daily Habit Summary
   — Visibility: Non-sensitive habits only
   — Include streaks: On
   — Include environmental context: On
2. If [missed habits count] > 0:
   Format message:
   "Habit check-in [day, date]:
    ✓ [completedCount] of [totalCount] done

    Still working on:
    [for each missed habit:]
    • [name] ([streak]-day streak)[if environmental: — [reason]]"

   Send Message to [buddy contact]
3. If [missed habits count] = 0:
   Send Message:
   "Clean sweep ✓ All [totalCount] habits done today."
```

**Visibility configuration is the critical privacy control.** The default is `nonSensitive` — habits marked sensitive in HabitKit settings never appear in accountability messages unless the user explicitly changes the visibility to `all` or configures a custom list. A user tracking medication compliance, sobriety, therapy homework, or mental health check-ins shares those habits with nobody by default.

**Environmental context removes the shame dimension.** "Still working on: Morning Run — thunderstorm" is a report of circumstance. "Still working on: Morning Run" on a clear day is a different kind of accountability. The buddy gets context that makes the message a genuine communication rather than a bare failure notification.

**The bidirectional setup.** Two users can each install the Shortcut configured to send to each other. No server, no shared account, no platform. Two people exchanging scheduled Messages. The accountability relationship is entirely between them — HabitKit provides the data, Messages provides the channel, Shortcuts provides the schedule.

**What HabitKit never knows.** The buddy's contact information never enters HabitKit. The app provides a `HabitSummaryResult` to the Shortcut. What the Shortcut does with that data — who it sends it to, when, in what format — is entirely outside the app's scope. HabitKit is a data source. The user's Shortcuts automation is the delivery mechanism. The two are deliberately decoupled.
