# CareNook Design Document

**Version:** 1.1  
**Date:** July 2026  
**Status:** Pre-build. Core architecture decisions recorded. Care team communication, appointment booking, insurance prior auth tracking, and benefit management require design work before phase 18 build begins.

---

## Table of Contents

1. [North Star](#1-north-star)
2. [Three Use Cases](#2-three-use-cases)
3. [Assistive Access Integration](#3-assistive-access-integration)
4. [Care Recipient Interface](#4-care-recipient-interface)
5. [Caregiver Coordinator Interface](#5-caregiver-coordinator-interface)
6. [Sharing Model](#6-sharing-model)
7. [Medication Adherence](#7-medication-adherence)
8. [FHIR CarePlan Bridge](#8-fhir-careplan-bridge)
9. [CMFallDetectionManager](#9-cmfalldetectionmanager)
10. [ManagedSettings Screen Time](#10-managedsettings-screen-time)
11. [MDM Fleet Deployment](#11-mdm-fleet-deployment)
12. [LegalNook Dependency](#12-legalnook-dependency)
13. [NookInsights Dimensions](#13-nookinsights-dimensions)
14. [API Surface](#14-api-surface)
15. [Design Gaps](#15-design-gaps)
16. [Revision History](#16-revision-history)

---

## 1. North Star

> CareNook exists because care coordination is the one task where fragmentation causes the most harm to the most vulnerable people and where a unified, privacy-respecting tool has the most to offer.

An elderly person with multiple chronic conditions may have a primary care physician, four specialists, a pharmacy, a Medicare supplement insurer, a home care agency, an adult day programme, and family members in multiple cities all trying to coordinate -- without a shared view of the complete picture. The family caregiver who manages this coordination has no tool that gives them that shared view without routing everything through a third-party server.

A parent of a child with a disability navigates IEPs, 504 plans, therapy authorisations, insurance prior authorisations, school accommodation letters, and specialist referrals from different institutions that do not communicate with each other.

A person managing their own chronic condition handles specialist referrals, insurance prior authorisations, care plan adherence across multiple providers, and the administrative overhead that comes with complex health management.

CareNook is the coordination layer for all three. No servers. No accounts. Data owned by the person being coordinated for.

**The dignity principle** (applies to every design decision):

CareNook never labels a care recipient's condition, age, or cognitive capacity. Assistive Access indicates that the device is configured for a person who benefits from a simplified experience. The app adapts to serve that person. The reason is theirs, not the app's to name or display.

---

## 2. Three Use Cases

### 2.1 Parents coordinating a child's care

The parent manages school, healthcare, therapy, extracurricular programmes, and government benefits for a child. AcademicNook (via the parent role) covers the school dimension. CareNook extends to:

- Healthcare appointment tracking across multiple providers
- Therapy authorisation management (insurance prior auth cycles)
- Government benefit programme tracking (IDEA, Medicaid, state programmes)
- IEP and 504 plan document storage (cross-reference to LegalNook)

Data ownership: the parent holds access until the child reaches the age of majority. At that point, CareNook initiates a graceful ownership transfer -- the now-adult child receives full ownership of their data and the parent's access is revoked. The historical record transfers intact.

**Minor child health data**: HIPAA gives parents access to their minor children's medical records in most circumstances, with specific exceptions (reproductive health, mental health, substance use in many US states). CareNook handles this conservatively -- each data type requires explicit parent configuration of what to track, and jurisdiction-specific restrictions are documented in the app for types with variable access rules.

### 2.2 Adult children coordinating elderly parent care

The most acute fragmentation case. The caregiver may be geographically distant. The care recipient may have variable capacity depending on time of day or health status. Multiple family members may be involved with different levels of access.

Key coordination tasks:
- Appointment tracking and transportation arrangement
- Medication management (MedNook is system of record; CareNook writes adherence confirmations under its own authorization — §7)
- Insurance claim and prior authorisation tracking
- Home care agency schedule management
- Care team communication log
- Financial management for care costs (cross-reference to LegalNook)

Caregiver burnout is a documented health risk. NookInsights tracks the caregiver's own health through the rest of the Nook suite and surfaces patterns when coordination burden correlates with the caregiver's health decline.

### 2.3 Self-coordinated chronic care

A person managing their own complex health condition coordinates their own care plan across multiple providers. The distinction from the health apps (SymptomNook, MedNook, RecoveryNook) is administrative rather than clinical -- CareNook handles the coordination overhead, the other apps handle the clinical tracking.

Key tasks:
- Prior authorisation request and appeal tracking
- Specialist referral coordination
- Care plan consolidation across providers
- FHIR CarePlan generation for sharing with care team

---

## 3. Assistive Access Integration

### 3.1 Detection

Two verified detection mechanisms — both from the WWDC 2025 Assistive Access API surface. (An earlier revision of this section cited `UIAccessibility.isAssistiveTechnologyRunning(.assistiveAccess)`, which is not a shipping API and has been removed.)

```swift
// SwiftUI environment value -- use in view hierarchy (iOS 26)
@Environment(\.accessibilityAssistiveAccessEnabled) var isAssistiveAccess

// Scene role -- the authoritative signal. The Assistive Access scene is a
// separate scene declaration; the system routes to it when the device is in
// Assistive Access mode (see §3.3).
let isAssistiveAccessScene =
    scene.session.role == .windowAssistiveAccessApplication
```

Mode changes while the app is running are handled by the scene lifecycle — the system tears down and re-routes scenes on mode transition, so the app observes scene connection/disconnection rather than a notification. Any Assistive Access API named in this document must be verified against current Apple documentation before the phase 18 build is scheduled.

### 3.2 Role determination from signal

Assistive Access is a **UI-selection heuristic, never an authorization signal**. It selects which interface renders; it grants nothing. What data a device can see is determined entirely by CKShare grants (§6) regardless of which interface is showing. A caregiver may themselves use Assistive Access; an explicit role override in Settings (behind biometric confirmation on the caregiver interface) is always available.

```swift
@Observable final class CareNookSession {
    enum CareNookRole { case careRecipient, caregiver }

    // Derived, not cached at init -- follows the active scene's role and the
    // environment value, plus any explicit user override.
    var activeRole: CareNookRole {
        if let override = storedRoleOverride { return override }
        return isAssistiveAccessActive ? .careRecipient : .caregiver
    }
}
```

### 3.3 WWDC 2025 Assistive Access Scene API

The WWDC 2025 Assistive Access Scene API (`UISceneSession.role == .windowAssistiveAccessApplication`) provides a cleaner implementation path than the environment value branch -- a completely separate scene declaration rather than conditional branching within the same view tree. This is the intended long-term implementation mechanism pending full documentation review.

The two-scene declaration:

```swift
// In the app's scene configuration
// Scene 1: standard caregiver interface
// Scene 2: Assistive Access care recipient interface
// The system routes to the correct scene based on Assistive Access mode
```

### 3.4 Caregiver notification on detection

When Assistive Access is detected for the first time, or re-enabled after a period of standard use, the connected caregiver receives a single notification:

```
[Care recipient name]'s device is in Assistive Access mode.

CareNook has switched to their simplified interface.
Their daily check-in and appointment reminders are active.

You can see their check-ins and manage their
care plan from your coordinator dashboard.
```

This notification fires once per mode transition, not on every app launch.

---

## 4. Care Recipient Interface

### 4.1 Design constraints

- Maximum 3-5 large tap targets visible at once
- No navigation hierarchy
- No settings accessible (settings managed by caregiver on their own device)
- No text entry required from care recipient
- High contrast, large text, SF Symbols not emoji

### 4.2 The three primary actions

```swift
struct CareRecipientHomeView: View {
    var body: some View {
        VStack(spacing: NookSpacing.xxl.value) {

            // How are you feeling?
            WellbeingCheckInView()

            // What is happening today?
            NextAppointmentCard()

            // Contact family
            ContactFamilyButton()
        }
        .padding(NookSpacing.xl.value)
        .animation(.none)  // No animations in Assistive Access mode
    }
}
```

`.animation(.none)` is mandatory. Spring animations during layout structural changes cause rendering hitches under the simplified Assistive Access system daemon profile.

### 4.3 Wellbeing check-in

Three tap targets using SF Symbols (not emoji). Single tap selects and immediately submits -- no confirmation step:

```swift
struct WellbeingCheckInView: View {
    var body: some View {
        VStack(spacing: NookSpacing.lg.value) {
            Text("How are you feeling?")
                .font(NookFont.title.swiftUIFont)

            HStack(spacing: NookSpacing.xl.value) {
                MoodButton(
                    symbol: "face.smiling",     // SF Symbol
                    label: "Good",
                    value: .pleasant
                )
                MoodButton(
                    symbol: "minus.circle",
                    label: "Okay",
                    value: .neutral
                )
                MoodButton(
                    symbol: "cloud.rain",
                    label: "Not great",
                    value: .unpleasant
                )
            }
        }
    }
}
```

The tap writes to HealthKit `stateOfMind` using **CareNook's own HealthKit write authorization** — CareNook is the declared secondary writer for `stateOfMind` (ARCHITECTURE.md §5.2), with its own `com.apple.developer.healthkit` entitlement and usage strings; entitlements and authorization never cross bundle boundaries via a shared framework. Samples carry CareNook as `HKSource`. The write authorization is requested once during on-device setup (performed with the caregiver present), so the care recipient never sees a permission dialog during daily use. The caregiver sees the check-in on their coordinator dashboard via the CKShare scope.

### 4.4 Three-day declining trend

When the care recipient has tapped "Not great" for three or more consecutive days, the caregiver's dashboard surfaces a contextual prompt:

```
Wellbeing check-ins this week

Mon  Good
Tue  Okay
Wed  Not great
Thu  Not great
Fri  Not great  -- today

Three-day declining trend.
Last appointment: Dr. Chen, 2 weeks ago.

[ Message Dr. Chen's office ]  [ Call [care recipient name] ]
```

The prompt is contextual, not an alert. It does not interrupt the caregiver -- it appears in the dashboard when they open CareNook.

### 4.5 Next appointment card

Shows only the single next upcoming appointment. No list, no calendar grid:

```
Next appointment

Dr. Sarah Chen
Neurology
Tuesday 3 June at 2:00 PM
General Hospital, Building B

[ Get directions ]
```

The "Get directions" button opens Maps with the appointment address. No other navigation is required of the care recipient.

---

## 5. Caregiver Coordinator Interface

The full coordinator dashboard is the primary interface for caregivers on standard iOS devices (Assistive Access not detected).

### 5.1 Dashboard overview

- Wellbeing trend for connected care recipients (if shared)
- Upcoming appointments across all care recipients
- Outstanding care coordination tasks
- Medication adherence signals (if shared)
- Insurance and authorisation status items

### 5.2 Multi-care-recipient support

A caregiver may coordinate care for more than one person -- both an elderly parent and a child with a disability, for example. CareNook supports multiple care recipient connections with a recipient selector at the top of the coordinator view.

Each care recipient's data is isolated. A caregiver cannot accidentally view one recipient's data while managing another's.

---

## 6. Sharing Model

### 6.1 Care recipient grants access -- always

No role can see a care recipient's data without an explicit grant from the care recipient or their legal guardian. Caregivers cannot search for care recipients by name or location. The connection is always initiated by the care recipient side.

For care recipients using Assistive Access who cannot initiate shares themselves, the initial setup is performed by the caregiver on the care recipient's device during onboarding. The care recipient's consent -- even if expressed through a guardian -- is documented during setup.

### 6.2 Configurable share scopes

```swift
public struct CareShareScope: Codable, Sendable {
    var appointmentSchedule: Bool
    var medicationAdherenceSignal: Bool   // not full medication details
    var wellbeingCheckInTrend: Bool
    var careCoordinationTasks: Bool
    var fallDetectionAlerts: Bool

    // Never shareable regardless of configuration
    // Health app HealthKit data, NookInsights correlation findings,
    // SymptomNook data, MindNook clinical scores
    static let healthDataShared: Bool = false
}
```

The caregiver never sees raw HealthKit data. They see care coordination signals derived from it -- "wellbeing trend declining" not "PHQ-9 score 14."

### 6.3 CloudKit CKShare infrastructure

Sharing uses CloudKit CKShare -- the same infrastructure as HabitNook's accountability buddy feature and AcademicNook's counsellor sharing. No Open Nook Foundation servers involved. Data lives in the care recipient's iCloud container. The caregiver receives read access to a scoped subset.

### 6.4 Minor child ownership transfer

When a child reaches the age of majority:

1. CareNook notifies both the parent and the now-adult child that a data ownership transfer is available
2. The now-adult child initiates the transfer from their own device
3. The historical record transfers to the child's own CareNook (or relevant health apps if they choose)
4. The parent's access is revoked
5. The child can optionally re-grant the parent access at any scope they choose

The transition is never automatic -- it is always child-initiated after notification.

---

## 7. Medication Adherence

CareNook handles medication adherence as a care coordination signal, not as a full medication management system. Full medication management is MedNook's scope.

For care recipients who can interact with the care recipient interface, a single large tap target confirms medication taken:

```
Morning medication
8:00 AM

[ I took it ]
```

If the tap does not occur by a configurable time (set by the caregiver during setup, default 10:00 AM for morning medication), the caregiver receives a gentle notification:

```
Morning medication check-in for [name]

They have not confirmed their morning
medication today. You may want to check in.

[ Call them ]  [ Dismiss ]
```

The notification is framed as an information signal, not an alarm. The caregiver decides what action to take.

The adherence signal writes to HealthKit as a medication dose event using CareNook's own HealthKit authorization — CareNook is the declared secondary writer for dose-event adherence confirmations (ARCHITECTURE.md §5.2). MedNook remains the primary writer and the system of record for medication management; CareNook writes only the adherence confirmation. The samples feed FHIR export and NookInsights correlation with CareNook as `HKSource`.

---

## 8. FHIR CarePlan Bridge

### 8.1 CarePlan resource

FHIR's `CarePlan` resource represents coordinated care across multiple providers. CareNook generates CarePlan exports for:

- Primary care coordination across multiple providers (for sharing with a new specialist)
- Post-acute care planning (RecoveryNook mobility data integration)
- Medicare Advantage care plan requirements (CMS-mandated FHIR API)

### 8.2 CMS Medicare Advantage

CMS mandates FHIR API support for Medicare Advantage plans. For elderly care recipients with Medicare Advantage coverage, CareNook can query the insurer's FHIR endpoint directly to pull:

- Current care plan items
- Prior authorisation status
- Covered services and remaining benefits

This is the one institutional data source in CareNook's scope that has a mandated, documented, public API. It is the highest-priority Tier 1 integration for the elderly parent care use case.

### 8.3 FHIR export quality tier

CareNook FHIR exports use the `FHIRExportQualityTier` enum from NookCore (shared with SymptomNook, RecoveryNook, CycleNook, VisionNook, PainNook):

- **standard** as default: LOINC codes, SNOMED CT severity, correct timestamps
- **comprehensive** when the receiving EHR is known to be FHIR-capable: full provenance, linked observations

---

## 9. CMFallDetectionManager

**Correction (v1.1, reversing v1.0's "correction")**: fall detection is performed by **Apple Watch**. `CMFallDetectionManager` is the CoreMotion API through which an iOS app *receives* fall detection events from the paired Watch — the iPhone does not detect falls with its own sensors, and v1.0's claim to the contrary was wrong. Consequence: **a paired Apple Watch worn by the care recipient is a hard requirement for this feature.** CareNook surfaces this requirement during caregiver setup; if no Watch is paired, the fall detection card explains what is needed rather than silently doing nothing.

### 9.1 Entitlement

`CMFallDetectionManager` requires the `com.apple.developer.coremotion.fall-detection` entitlement, granted by Apple review with justification. CareNook's justification: relaying Watch-detected fall events for care recipients into care coordination notifications to caregivers.

Apply for this entitlement well before phase 18 build begins -- Apple's review timeline is unpredictable.

### 9.2 Mandatory completion block pattern

The delegate fires a mandatory synchronous completion block. The OS watchdog terminates the process if the completion block is not called immediately:

```swift
actor FallDetectionHandler: CMFallDetectionDelegate {

    func fallDetectionManager(
        _ manager: CMFallDetectionManager,
        didDetect event: CMFallDetectionEvent,
        completionHandler handler: @escaping () -> Void
    ) {
        // Write lightweight signal to App Group -- fast, no SwiftData
        NookAppGroup.set(
            key: "carenook.fallDetected",
            value: event.date.timeIntervalSince1970
        )

        // Call handler immediately -- heavy processing deferred
        handler()

        // SwiftData and caregiver notification happen after handler() returns
        Task { await processFallEventAsync(event) }
    }
}
```

The App Group write is synchronous and fast. SwiftData operations and caregiver notifications are deferred via `Task` after the handler fires. This pattern is mandatory -- any deviation risks watchdog termination.

### 9.3 Caregiver notification

When the Watch reports a fall event and the care recipient did not respond to the Watch's own confirmation prompt, CareNook relays the event to the caregiver:

```
Fall detected for [name]

Apple Watch detected a fall at 2:34 PM.
They did not respond to the Watch's prompt.

If Emergency SOS after a fall is enabled on
their Watch, emergency services may already
have been contacted. CareNook has not called
emergency services.

[ Call them now ]  [ Call emergency services ]
```

CareNook does not independently call emergency services and does not run its own confirmation window — the Watch owns detection, confirmation, and any Emergency SOS escalation. CareNook is the relay into the care coordination layer.

---

## 10. ManagedSettings Screen Time

**Correction (v1.1, reversing v1.0)**: Apple's platform does not permit parental or guardian authority over an **adult** Apple ID under any circumstances — FamilyControls authorization is either `.individual` (the device owner authorizes restrictions on their own device) or parent/guardian over a *child account*. v1.0's remote caregiver-controlled restriction of an adult care recipient's device was structurally impossible and has been redesigned. The feature is correspondingly smaller and is presented as such.

### 10.1 Use case and mechanism — `.individual` authorization

The restriction profile lives on the **care recipient's own device**, authorized `.individual` during in-person setup (the caregiver configures it on the recipient's device with the recipient present, alongside the CKShare grant). What the caregiver can do remotely is limited to *toggling a pre-consented profile*: the caregiver's dashboard writes a flag to the shared CloudKit zone; CareNook on the recipient's device, on next wake, applies or lifts the locally authorized restriction set. The recipient's device is always the authorizing party and can always revoke.

This is caregiver-suggested, never automatic, and the coordinator dashboard surfaces the option only when the wellbeing trend has been declining for multiple days.

### 10.2 Advanced path — facility MDM

For deployments needing genuinely managed restrictions (memory-care facilities, or families willing to run device management), the correct mechanism is **supervision**: enrol the care recipient's device via Apple Configurator or a self-hosted/lightweight MDM, and manage app availability through MDM restrictions rather than FamilyControls. CareNook documents this as the advanced path and reads facility configuration via Managed App Configuration (§11); it does not implement MDM itself. Setup docs must state both prerequisites plainly: `.individual` requires in-person setup on the recipient's device; MDM requires supervision enrolment.

### 10.3 Memory constraint

Shield extensions enforced by ManagedSettings have a strict 6MB memory cap. Never instantiate SwiftData containers or heavy model schemas inside the restriction extension. All evaluation uses primitive App Group key-value integers:

```swift
func applyFocusRestrictions() {
    let store = ManagedSettingsStore()
    // Restriction decision from App Group lightweight key -- not SwiftData
    let restrictedApps = NookAppGroup.read(key: "carenook.restrictedBundleIDs") ?? []
    store.application.blockedApplications = Set(restrictedApps.map { Application(bundleIdentifier: $0) })
    // Total extension memory usage must stay under 6MB
}
```

---

## 11. MDM Fleet Deployment

For care facilities (assisted living, memory care, skilled nursing) deploying CareNook fleet-wide, MDM Managed App Configuration pushes facility-specific settings:

```swift
struct ManagedCareConfiguration {
    static var facilityName: String? {
        UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed")?["facilityName"] as? String
    }
    static var careContactList: [[String: String]]? {
        UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed")?["careContactList"] as? [[String: String]]
    }
    static var defaultCaregiverShareCode: String? {
        UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed")?["defaultCaregiverShareCode"] as? String
    }
}
```

The facility pre-configures the contact list (family member names and phone numbers) so that the care recipient's "Contact family" button is populated without requiring the care recipient to configure anything. The facility IT administrator pushes this configuration via MDM before distributing devices.

**iCloud prerequisite [deployment-critical]:** the sharing model (§6) and data-ownership model both require each care recipient's device to be signed into that person's own iCloud account — CKShare has no server-side substitute in this architecture. Facility deployments must provision per-resident Apple IDs (Managed Apple IDs do not currently support the required iCloud/CKShare features for this design and must be evaluated per iOS release). A device with no iCloud account gets local-only mode: check-ins and reminders work on-device; nothing is shared to a caregiver. The deployment guide states this before hardware is purchased, not after.

---

## 12. LegalNook Dependency

CareNook has a specific dependency on LegalNook for healthcare proxy documents.

When a caregiver coordinates care for an elderly parent or another adult who may have reduced capacity, the legal authority for that coordination is documented in a healthcare proxy or power of attorney instrument. This document lives in LegalNook.

CareNook reads from the LegalNook App Group key `legalnook.healthcareProxies` to confirm that a healthcare proxy document exists, identifies the authorised agent (the caregiver), and is currently valid (not expired).

This cross-reference is displayed during caregiver setup:

```
Legal authority confirmed

A healthcare proxy document names you as
the authorised agent for [care recipient name].

Document: Healthcare Proxy Agreement
Effective: March 2025
Valid until: Not specified

[ View document ]  [ Continue ]
```

If no healthcare proxy document exists in LegalNook, CareNook prompts the caregiver to create one -- surfacing LegalNook if not already installed.

---

## 13. NookInsights Dimensions

### 13.1 Care coordination burden (caregiver dimensions)

```swift
// Added to the caregiver's NookInsights feature vector
var careCoordinationTasksOpen: Float?        // outstanding care tasks
var careAppointmentDensityThisWeek: Float?   // appointments to arrange
var careRecipientHealthStatusChange: Float?  // 0/1 -- significant status change
var caregiverBurdenIndex: Float?             // composite coordination complexity
```

### 13.2 Care recipient wellbeing (if shared to caregiver's device)

```swift
var careRecipientWellbeingTrend: Float?      // rolling 7-day valence
var careRecipientMedicationAdherence: Float? // rolling 30-day adherence rate
```

### 13.3 Caregiver burnout correlation

Research consistently documents that informal caregivers have significantly elevated rates of depression, anxiety, and physical health decline correlating with coordination burden. NookInsights finds this at the individual level:

- `caregiverBurdenIndex` correlated with MindNook PHQ-9 trend
- `careAppointmentDensityThisWeek` correlated with SleepNook HRV
- `careCoordinationTasksOpen` correlated with SymptomNook fatigue ratings

When NookInsights finds a sustained pattern of caregiver health decline correlated with care coordination burden, it surfaces:

```
Your data shows a pattern

Over the past 6 weeks, your sleep quality
and energy levels have been lower on weeks
when your care coordination load is highest.

Your health matters too. Consider whether
any coordination tasks could be shared
with other family members or care providers.

[ Explore caregiver support resources ]
```

---

## 14. API Surface

```
Packages/CareNookCore/Sources/
  Scenes/
    CareRecipient/           Care recipient interface (Assistive Access)
    Caregiver/               Full coordinator dashboard
  AssistiveAccess/           UIAccessibility detection, WWDC 2025 Scene API
  WellbeingCheckin/          stateOfMind writes (own authorization; secondary writer, ARCHITECTURE.md §5.2)
  Trauma/                    CMFallDetectionManager (Apple Watch fall events; entitlement required)
  MedicationAdherence/       Dose-event adherence writes (own authorization; secondary writer)
  FHIR/                      CarePlan generation, Medicare Advantage query
  Sharing/                   CloudKit CKShare, care recipient scoped access

Apps/CareNook/
  Extensions/                ManagedSettings Shield Extension (FamilyControls)
  Info.plist                 CMFallDetectionManager entitlement placeholder

Primary frameworks:
  SwiftUI \.accessibilityAssistiveAccessEnabled
  Assistive Access scene role (UISceneSession.role == .windowAssistiveAccessApplication)
  CMFallDetectionManager (receives Apple Watch fall events -- Watch required;
    com.apple.developer.coremotion.fall-detection entitlement, apply early)
  ManagedSettings/ManagedSettingsStore + FamilyControls (.individual on the
    care recipient's own device; remote toggle of pre-consented profile only)
  HealthKit (stateOfMind + dose-event adherence writes with CareNook's own
    entitlement and authorization -- declared secondary writer, ARCHITECTURE.md §5.2;
    HKClinicalRecord FHIR CarePlan)
  Foundation Models
  CoreML
  UserNotifications
  CloudKit/CKShare (care recipient sharing)
  AppIntents, WidgetKit, MetricKit, BGProcessingTask
  EventKit (appointment calendar)
  UserDefaults com.apple.configuration.managed (facility fleet deployment)

Entitlements required before App Store submission:
  com.apple.developer.coremotion.fall-detection (Apple review required -- apply early)
  FamilyControls (Screen Time API -- Apple review required; .individual authorization)
  com.apple.developer.healthkit (stateOfMind + dose-event secondary writes)
```

---

## 15. Design Gaps

The following require design work before phase 18 build begins.

**Care team communication flow** -- How caregivers communicate with the care team (physicians, therapists, home care agency coordinators) from within CareNook. Whether this is a direct messaging feature, a structured note-sharing feature, or a task-assignment feature is not designed. Each option has different privacy and liability implications.

**Appointment booking** -- Whether CareNook integrates with scheduling systems (Zocdoc, health system portals, direct phone call facilitation) or is purely a tracking tool that records externally booked appointments. The booking integration option requires adapter-pattern work similar to AcademicNook's LMS adapters.

**Insurance prior authorisation tracking** -- Prior auth cycles are complex: submission, acknowledgement, additional information requests, approval or denial, appeal. The full workflow for tracking a prior auth from submission through resolution is not designed.

**Benefit management** -- Government benefits (Medicaid waiver programmes, state-specific disability benefits, veteran benefits) have their own application, renewal, and reporting requirements. Which of these CareNook tracks and how is not designed.

**Care facility adapter** -- Whether CareNook has an adapter protocol for care facility management systems (PointClickCare, MatrixCare, Alis) similar to AcademicNook's LMS adapters. These systems have institutional APIs that could provide structured care data -- the adapter pattern would apply. Not designed.

**Respite care coordination** -- Whether CareNook helps caregivers find, schedule, and coordinate respite care services is not designed.

---

## 16. Revision History

| Version | Date | Changes |
|---|---|---|
| 1.1 | July 2026 | Decision-record patch (DECISIONS.md). §3 detection rewritten against verified APIs — invented `UIAccessibility.isAssistiveTechnologyRunning(.assistiveAccess)` removed; role determination declared a UI heuristic (never authorization), derived not init-cached, with explicit override. §4.3/§7 HealthKit writes use CareNook's own entitlement and authorization as declared secondary writer (ARCHITECTURE.md §5.2). §9 reversed v1.0's incorrect "correction": CMFallDetectionManager receives Apple Watch fall events; paired Watch is a hard requirement; CareNook is a relay, the Watch owns detection/confirmation/SOS. §10 redesigned around FamilyControls `.individual` on the recipient's own device (no parental authority over adult Apple IDs exists) with remote toggle of a pre-consented profile; facility MDM/Apple Configurator supervision documented as the advanced path. §11 per-resident iCloud account prerequisite documented for CKShare. §14 API surface and entitlements updated. Design tokens renamed to Nook* scheme. |
| 1.0 | May 2026 | Initial design document. Three use cases, Assistive Access integration (UIAccessibility + WWDC 2025 Scene API), dignity principle, care recipient interface (3 tap targets, SF Symbols, .animation(.none)), caregiver coordinator interface, sharing model with CKShare, minor child ownership transfer, medication adherence signal, FHIR CarePlan bridge, CMFallDetectionManager (iPhone sensors -- corrected), ManagedSettings FamilyControls (caregiver-initiated -- corrected), MDM fleet deployment, LegalNook healthcare proxy dependency, NookInsights dimensions, caregiver burnout correlation, design gaps |
