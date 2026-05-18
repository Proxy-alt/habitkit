# HabitKit — Design Document
**Version 1.0 · May 2026**

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

---

## 4. Monetization & Community Model

### 4.1 Revenue

HabitKit is free with no paywalled features. Revenue is patron-based, external to the App Store, so Apple IAP is never invoked. The tiers live entirely on Patreon or Ko-fi.

| Tier | Monthly | What it means |
|---|---|---|
| Supporter | $1 | Name in changelog credits |
| Voter | $3 | Vote on feature priority polls |
| Collaborator | $10 | Submit feature requests directly, early TestFlight builds, Discord channel access |

**No Patreon links appear inside the iOS app.** App Store Review Guideline 3.2.1 prohibits linking to external purchase mechanisms from within an app. The Patreon URL is in the App Store description page and on the project website only.

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
    var photoBookmark: Data?  // security-scoped bookmark to Files-stored photo
    var habit: Habit
}

@Model
class HabitSchedule {
    var frequency: ScheduleFrequency // daily, weekly(days:), interval(every:), xTimesPerWeek(x:)
    var reminderTimes: [Date]
    var habit: Habit
}
```

### 7.3 Habit Templates (.habit files)

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

### 8.10 Foundation Models (iOS 26)

HabitKit uses Apple's on-device Foundation Models framework for three specific features. The model is accessed only on Apple Intelligence-enabled devices. Availability is checked before any call; the UI degrades gracefully on unsupported devices.

All inference runs on-device. No data leaves the device. No cost per request.

**Feature 1 — Habit suggestion from goal:**
The user describes a goal in natural language ("I want to run a 5K by December"). The model returns a structured `HKHabitSuggestion` via guided generation — a typed Swift struct, not free text.

**Feature 2 — Completion note tagging:**
When a user adds a note to a completion ("felt sluggish, skipped warm-up"), the content-tagging adapter extracts structured tags (`mood: low`, `missed: warm-up`). These feed into the analytics correlation engine.

**Feature 3 — Weekly summary:**
On Sunday, the model generates a natural language summary of the week's habit data. Private, on-device, cached in SwiftData. No server call.

```swift
// Availability check — required before any model access
guard case .available = SystemLanguageModel.default.availability else {
    // Show non-AI fallback UI
    return
}
let session = LanguageModelSession()
```

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

### 8.15 Files App Integration

HabitKit declares a document provider. The app's container is accessible from the Files app. Users can:
- Browse and open `.habit` template files
- Export habit history as JSON or CSV
- Back up the full archive as `.habitarchive` (a ZIP bundle containing history, metadata, and completion photos)
- Import templates from any Files-accessible location (iCloud Drive, local storage, third-party providers)

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

## 16. Revision History

| Version | Date | Notes |
|---|---|---|
| 1.0 | May 2026 | Initial design document |
