# DECISIONS.md — Nook Suite Decision Record

**Date:** July 2026. Settled by the project owner following the July 2026 design-doc audit (32 findings). These rulings are binding; docs patched accordingly (ARCHITECTURE.md 2.0, habitkit 1.8, AcademicNook/LegalNook/CareNook/NutriNook 1.1). Re-litigating any item requires a new entry here.

## Identity & scope

| # | Decision | Ruling |
|---|---|---|
| 1 | Org identity | **Open Nook Foundation** — nonprofit; revenue funds developers and server costs. "Nookly Labs" retired everywhere. |
| 2 | App roster | **24 apps**, canonical table in ARCHITECTURE.md §1.1. FinanceNook, ApptNook, ProjectNook, MailNook, WatchNook carry **Incubating** status — architecture notes exist, no phase until a design doc does. |
| 3 | Android | **Out for v1–v2.** ARCHITECTURE §15.5/§19 and habitkit §22 retained as deferred reference only. |
| 4 | Mac | **SwiftUI multiplatform.** Catalyst rejected. Non-health apps get full Mac targets; health apps MenuBarExtra only (no HealthKit on macOS). |
| 5 | habitkit §8 triage | **Add order is the priority signal** (list was frontloaded with core frameworks). Encoded as habitkit §8.0: v1 = §8.1–§8.18 + §8.21; promoted §8.23/§8.27/§8.35/§8.36; all else post-v1. Marketing may not depict post-v1 integrations (narrative NFC scene cut accordingly). |

## Architecture

| # | Decision | Ruling |
|---|---|---|
| 6 | App Group ID | **`group.app.nook.suite`** — everywhere, including entitlements. |
| 7 | App Group schema | **Hybrid.** Codable context blobs canonical (ARCHITECTURE §14.21 is the sole `NookAppGroup`); closed flat-key set for extension consumers only (ARCHITECTURE §4.3). |
| 8 | Design tokens | **`Nook*` scheme** (NookFont, NookSpacing, NookColour, NookAnimation, NookRadius). `HK*` was HabitNook-era and collides with HealthKit. |
| 9 | Source of truth | **ARCHITECTURE.md is canonical.** habitkit former §20.1–§20.5 replaced with a pointer; remaining §20.x are per-app notes pending standalone docs. |
| 12 | Sensitive namespaces | **Per-namespace adjacency allowlist, CI-enforced** via per-namespace read/write accessor modules and dependency-graph validation. **AcademicNook is write-only** to the App Group. |
| 13 | Cross-app HealthKit writes | **Every writer requests its own authorization** (accept extra prompts). Primary/secondary writer table in ARCHITECTURE §5.2; provenance via `HKSource`. |

## Features

| # | Decision | Ruling |
|---|---|---|
| 10 | CareNook fall detection | **Requires Apple Watch.** CMFallDetectionManager receives Watch events; Watch owns detection/confirmation/SOS; CareNook is the relay. |
| 11 | CareNook device restriction | **FamilyControls `.individual`** on the recipient's own device, configured in person; caregiver remotely toggles a pre-consented profile only. Advanced path: supervision via Apple Configurator / self-hosted MDM. No parental authority over adult Apple IDs exists. |
| 14 | LegalNook entitlements | **Staged hybrid:** v1 manual entry + curated per-jurisdiction link-out directory; v2 trust-tiered community rules content with last-verified dates; **Foundation Models is a document→topic classifier only, never a content generator.** |
| 15 | NutriNook phase 2 | **Build starts without the recipe engine.** Completeness claim qualified until recipes ship. |
| 16 | Google scopes | **Keep Gmail (optional) and Drive.** Both are restricted scopes; restricted verification accepted. Incremental authorization mandatory. Mitigations: on-device exemption, domain-trust fleet path. |
| 18 | Shared Live Activity | **Update on app wake** — CloudKit-push-triggered, minutes-stale, zero servers. No push relay. Narrative rewritten to match. |
| 20 | SIS credentials | **No on-device scraping — refused entirely.** Foundation publishes an open-source StudentVue→OneRoster/LTI **bridge server**, district- or self-hosted, never foundation-operated. App speaks OneRoster/LTI only. Threat model lives in the bridge repo. |

## Policy

| # | Decision | Ruling |
|---|---|---|
| 17 | OS support | **Tiered:** Rolling (default, iOS minus one) / Elderly-3 (MedNook, RecoveryNook, ApptNook) / Org-5 (AcademicNook, CareNook). Tier per app in ARCHITECTURE §1.1. |
| 19 | NookInsights surfacing gate | **Adopted as specified**, [ENFORCED], ARCHITECTURE §6.0: 45 days/dimension, 20 paired observations, ≤0.30 imputed share, ≥5 events for event dimensions; BH-FDR α=0.05 per training run, \|r\|≥0.3, quality-weighted support ≥0.60; 2 persistence windows, confidence ≥0.70; 1 new finding/week, 3 active max, 90-day dismissal cooldown. RecoveryMode suppresses findings, including retroactive ones. |

## Standing rules established by this record

- Suite-architecture content lives only in ARCHITECTURE.md; other docs link.
- A docs-lint CI step must validate heading numbering and the App Group flat-key list (habitkit's numbering rot is why).
- Server carve-out, amended: config/auth servers acceptable; data servers never; **credential-holding servers are never foundation-operated.**
- Findings-language rules (§20/no-diagnosis) govern *what* a finding may say; the §6.0 gate governs *when* it may be said. Both are [ENFORCED].
