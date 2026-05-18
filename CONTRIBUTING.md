# Contributing to HabitKit

HabitKit is MIT-licensed and open to community contributions. Read this document before opening a PR.

## What belongs in HabitKit

**In scope:**
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
- Onboarding coach or tutorial screens
- Any feature requiring a server or account
- Third-party SDK integrations
- Android / React Native ports

## Code requirements

All PRs must satisfy these checks before review:

1. **No hardcoded colors.** All UI uses `HKTheme` tokens via `@Environment(HKThemeManager.self)`. Raw hex values and system colors (`Color.blue`, `Color.red`) are banned in Swift files. CI enforces this with a grep check.

2. **No hardcoded fonts.** Use `Font.hkBody`, `Font.hkHeadline`, etc. No `.font(.body)` or explicit `Font.system(size:)` calls with fixed sizes.

3. **No third-party dependencies** without maintainer approval in an issue first.

4. **SwiftLint passes** with the project configuration (`.swiftlint.yml` at the root).

5. **Swift 6 strict concurrency.** No `@unchecked Sendable` without a written justification in a code comment. No `nonisolated(unsafe)` without justification.

6. **No accounts, no servers, no analytics SDKs.** Any PR that phones home in any way is rejected.

## Submitting a community theme

Themes are submitted as entries in `HabitKitUI/Sources/Themes/Community/themes.json`. CI validates every PR against the JSON schema in `.github/theme-schema.json`. Malformed or incomplete submissions are rejected automatically before manual review.

Required fields: `id`, `name`, `author` (your GitHub handle), `isDark`, and all 11 color roles.

The `id` must be globally unique (check existing themes first) and use kebab-case.

## Credits

Every merged PR is credited in `CHANGELOG.md` and in the App Store release notes:

```
v1.3.0
- Habit streak freeze [contributed by @username, #PR42]
```

Your GitHub handle is used exactly as-is.

## Design document

Read `DESIGN.md` before contributing. The north star question is:

> "What would Apple ship if they built a Habits app?"

If your feature wouldn't survive Craig Federighi's v1 cut, reconsider the scope.
