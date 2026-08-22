# LegalNook Design Document

**Version:** 1.1  
**Date:** July 2026  
**Status:** Pre-build. Architecture decisions recorded. Full UI and flow design required before build begins at phase 17.

---

## Table of Contents

1. [North Star](#1-north-star)
2. [The Problem](#2-the-problem)
3. [Data Categories](#3-data-categories)
4. [Document Ingestion Pipeline](#4-document-ingestion-pipeline)
5. [Foundation Models Extraction](#5-foundation-models-extraction)
6. [Security Model](#6-security-model)
7. [Bridge Out](#7-bridge-out)
8. [Files App Integration](#8-files-app-integration)
9. [Printing and PDF Export](#9-printing-and-pdf-export)
10. [Spotlight Integration](#10-spotlight-integration)
11. [UTType Declarations](#11-uttype-declarations)
12. [CareNook Dependency](#12-carenook-dependency)
13. [NookInsights Dimensions](#13-nookinsights-dimensions)
14. [API Surface](#14-api-surface)
15. [Design Gaps](#15-design-gaps)
16. [Revision History](#16-revision-history)

---

## 1. North Star

> LegalNook applies the AcademicNook pattern to a person's legal and administrative life -- a domain where no universal data store equivalent to HealthKit exists, fragmentation causes concrete harm, and the individual is the one experiencing all of it simultaneously while every institution treats it as a separate silo.

A person's legal and administrative life is scattered across courts, government agencies, landlords, employers, insurers, banks, and utilities. The lease agreement is a PDF in Downloads. The court date is in a text message. The insurance renewal is an email the person may have archived. The warranty on the refrigerator is probably lost. The passport expires in four months and the person has not noticed.

LegalNook brings all of this into one place. Not to replace institutional systems -- courts will always have their own dockets, insurers their own portals -- but to give the person a unified view of their obligations, deadlines, and entitlements that no institution currently provides.

**What LegalNook explicitly is not:**

- Not a legal advice service -- LegalNook organises information, it does not interpret law
- Not a law firm client portal -- LegalNook is personal organisation, not institutional representation
- Not a financial app -- financial obligations are in scope as deadlines and records, not as a budgeting tool
- Not a document storage cloud -- documents are stored in the user's iCloud container, never on Open Nook Foundation servers

---

## 2. The Problem

The fragmentation is structural. Every institution that creates a legal obligation maintains only their own record of it. The court knows the court date. The landlord knows the lease expiry. The insurer knows the renewal date. The user knows none of them coherently unless they actively maintain a personal system -- which almost nobody does.

The consequences of fragmentation are not merely inconvenient:

A missed court date produces a bench warrant. A missed lease renewal notice means the landlord can convert to month-to-month at a higher rate. A lapsed professional licence results in a fine and a period of illegal practice. A missed insurance renewal leaves the person uninsured. An expired passport discovered at the airport means a missed trip.

The health correlation layer makes LegalNook more than an organiser. Legal stress is one of the strongest documented correlates with anxiety, sleep disruption, and physical symptom burden. LegalNook gives NookInsights the administrative context to explain health pattern clusters that currently appear unexplained -- the anxiety spike that corresponds to a court date two weeks away, the sleep disruption that corresponds to the period between a landlord dispute escalation and its resolution.

---

## 3. Data Categories

### 3.1 Documents

Time-bounded records with associated deadlines, obligations, or parties. Every document ingested by LegalNook produces a canonical `LegalDocument` record.

Examples: lease agreements, employment contracts, insurance policies, vehicle warranties, professional licences, government correspondence, court orders, demand letters, settlement agreements, power of attorney documents, identification documents (passport, driving licence).

Key extracted fields per document:
- Parties named (landlord/tenant, employer/employee, insurer/insured)
- Effective date and expiry or termination date
- Renewal terms and notice period
- Core obligations created by the document
- Governing law / jurisdiction

### 3.2 Obligations

Time-sensitive items created by documents or standalone. Each obligation has a due date, a consequence for missing it, and a status (pending/complete/overdue).

Examples: court appearances, filing deadlines, licence renewal dates, insurance premium due dates, lease notice windows, contractor milestone payments, statutory response deadlines in disputes.

Obligations are written to EventKit with appropriate lead-time reminders. A court date gets a 2-week reminder and a 2-day reminder. A lease renewal notice window (typically 30-60 days before expiry) gets a reminder at the start of the window, not on the expiry date.

### 3.3 Records

Ongoing logs of interactions that create a paper trail. These matter most in disputes where the timeline of events determines the outcome.

Examples: maintenance request logs (date submitted, landlord response, outcome), insurance claim timelines (filed date, adjuster contact, decision, appeal), workplace accommodation request history, formal complaint submissions and responses, correspondence logs with specific parties.

Records are the category most likely to be needed urgently and unexpectedly. A tenant who has logged every maintenance request with date and landlord response has strong evidence in a security deposit dispute. A worker who has logged every accommodation request and employer response has documentation for an HR escalation.

### 3.4 Entitlements

Rights, benefits, and protections the user holds that they may not know to exercise.

Examples: consumer warranty rights (statutory warranties independent of manufacturer), tenant rights under local landlord-tenant law, employee rights under local employment law, disability accommodations the user is entitled to request, government benefits the user qualifies for, statutory sick pay or leave entitlements.

Entitlements are the category LegalNook is least able to populate automatically -- they require knowing the user's jurisdiction and circumstances. The design for entitlements is deferred (see §15 Design Gaps). The data model is defined here.

---

## 4. Document Ingestion Pipeline

### 4.1 Input sources

LegalNook accepts documents from multiple entry points:

- **Camera scan** -- VNDocumentCameraViewController for multi-page capture, or live DataScannerViewController for single pages
- **Files app share sheet** -- any PDF shared to LegalNook from Files or another app
- **Photos library** -- photographed document pages
- **Email attachment** -- via the share sheet from Mail or any email client
- **iCloud Drive** -- direct import from the user's own iCloud Drive
- **FileProvider** -- documents placed in the LegalNook folder in Files by any app (see §8)

### 4.2 PDF text extraction strategy

```swift
// Attempt PDFKit text layer first
// Fall back to VNRecognizeTextRequest if text layer yields < 50 chars/page on average

func extractText(from pdfDoc: PDFDocument) async throws -> DocumentText {
    var pageTexts: [String] = []

    for i in 0..<pdfDoc.pageCount {
        guard let page = pdfDoc.page(at: i) else { continue }
        pageTexts.append(page.string ?? "")
    }

    let avgChars = Double(pageTexts.joined().count) / Double(max(pdfDoc.pageCount, 1))

    if avgChars < 50 {
        // Scanned PDF -- rasterise and OCR
        return try await extractViaOCR(pdfDoc)
    }

    return DocumentText(pages: pageTexts, confidence: 0.95, wasOCR: false)
}

func extractViaOCR(_ pdfDoc: PDFDocument) async throws -> DocumentText {
    var pageTexts: [String] = []

    for i in 0..<pdfDoc.pageCount {
        guard let page = pdfDoc.page(at: i) else { continue }

        // Rasterise at 2x for OCR accuracy
        let scale: CGFloat = 2.0
        let rect = page.bounds(for: .mediaBox)
        let size = CGSize(width: rect.width * scale, height: rect.height * scale)

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            ctx.cgContext.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.revision = VNRecognizeTextRequestRevision3

        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        try handler.perform([request])

        let observations = (request.results ?? []) as [VNRecognizedTextObservation]
        let sorted = observations.sorted { $0.boundingBox.midY > $1.boundingBox.midY }
        pageTexts.append(sorted.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n"))
    }

    return DocumentText(pages: pageTexts, confidence: 0.80, wasOCR: true)
}
```

---

## 5. Foundation Models Extraction

### 5.1 LegalDocument extraction schema

```swift
@Generable
struct LegalDocumentExtraction {

    @Guide("All parties named in the document with their roles")
    var parties: [DocumentParty]

    @Guide("Document type classification")
    var documentType: LegalDocumentType

    @Guide("Effective date of the document")
    var effectiveDate: String?

    @Guide("Expiry, termination, or end date")
    var expiryDate: String?

    @Guide("Renewal terms -- automatic vs manual, notice period required")
    var renewalTerms: String?

    @Guide("All obligations created by this document for each party")
    var obligations: [DocumentObligation]

    @Guide("Governing jurisdiction or law if stated")
    var jurisdiction: String?

    @Guide("Monetary amounts mentioned with their context")
    var monetaryAmounts: [MonetaryAmount]

    @Guide("Confidence in extraction accuracy from 0.0 to 1.0")
    var extractionConfidence: Double

    @Guide("Sections that were unclear or could not be extracted reliably")
    var uncertainSections: [String]
}

@Generable
struct DocumentParty {
    var name: String
    var role: String          // "landlord", "tenant", "employer", "employee", "insurer"
    var contactInfo: String?
}

@Generable
struct DocumentObligation {
    var description: String
    var obligatedParty: String
    var dueDate: String?      // as written in document
    var isRecurring: Bool
    var recurringFrequency: String?  // "monthly", "annually"
    var consequence: String?  // consequence of non-compliance
}

@Generable
struct MonetaryAmount {
    var amount: Double
    var currency: String      // "USD", "GBP"
    var context: String       // "monthly rent", "security deposit", "deductible"
    var dueDate: String?
}

public enum LegalDocumentType: String, Codable, Sendable {
    case residentialLease
    case employmentContract
    case insurancePolicy
    case warranty
    case courtOrder
    case governmentLetter
    case professionalLicence
    case identificationDocument
    case powerOfAttorney
    case settlementAgreement
    case demandLetter
    case serviceContract
    case other
}
```

### 5.2 Long document handling

Legal documents -- leases, insurance policies, employment contracts -- regularly exceed Foundation Models context window limits. Chunking strategy:

- First chunk always covers pages 1-3 (parties, effective date, core terms appear here in most legal documents)
- Subsequent chunks overlap by 500 characters to preserve context across page breaks
- Monetary amounts and dates are extracted in every chunk and deduplicated by proximity
- Obligations are merged across chunks -- if the same obligation appears in multiple chunks, it is deduplicated by description similarity

### 5.3 Extraction confidence and verification

Documents with extraction confidence below 0.75 surface specific uncertain fields for user review before being saved. The user sees exactly which fields were uncertain and can edit them:

```
Extracted from Residential Lease Agreement.pdf

Low confidence warning:
  Move-out date: "12 months from signing"
  LegalNook could not determine the exact date.
  Please enter it manually: [date picker]

  Security deposit amount: unclear
  Please enter: [text field]

All other fields extracted with high confidence.
[ Confirm and save ]
```

---

## 6. Security Model

### 6.1 Document vault with biometric guard

LegalNook stores documents containing the most sensitive personal information the suite handles -- litigation records, court orders, government identity documents. Vault content never renders until the user has authenticated in the current session; authentication is triggered by the explicit unlock action on the vault screen (never from SwiftUI body or list rendering contexts), and the session unlock expires when the app is backgrounded.

The enrollment-change baseline is persisted to the **Keychain** (`NookKeychain`, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`). v1.0 held it in actor memory, which reset on every process launch — exactly the window in which an attacker-enrolled biometric would be used — making the check a no-op across launches. The domain state is read only after a successful `canEvaluatePolicy` call (it is not populated before), via `domainState` on current iOS (`evaluatedPolicyDomainState` is deprecated).

```swift
actor LegalNookSecurityGate {
    private var isEvaluating = false
    private static let baselineKey = "legalnook.biometry.domainState"

    func requireBiometricAuth() async throws {
        guard !isEvaluating else { return }
        isEvaluating = true
        defer { isEvaluating = false }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: &error
        ) else { throw LegalNookSecurityError.biometryUnavailable(error) }

        // domainState is valid only after canEvaluatePolicy succeeds.
        // Baseline persists in the Keychain across launches -- an in-memory
        // baseline cannot detect enrollment changes between sessions.
        let current = context.domainState?.data
        let known: Data? = try? NookKeychain.load(Data.self, key: Self.baselineKey)
        if let known, let current, current != known {
            await lockVaultDueToEnrollmentChange()
            throw LegalNookSecurityError.enrollmentChanged
        }

        try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Access your legal documents"
        )
        if let current {
            try? NookKeychain.save(current, key: Self.baselineKey,
                accessibility: kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
        }
    }
}
```

The actor serialises authentication -- no concurrent biometric challenges.

### 6.2 New biometric enrollment handling

When `.biometryCurrentSet` has changed since last authentication, the vault locks and the user is prompted to re-authenticate. The user sees:

```
Security alert

A new Face ID or Touch ID has been enrolled
on this device since you last accessed your
legal documents.

Please re-authenticate to verify it's you.

[ Re-authenticate ]
```

This protects against a scenario where an unauthorised person adds their biometrics to an unlocked device to gain access to LegalNook.

---

## 7. Bridge Out

### 7.1 Personal legal timeline

A chronological PDF export of all documents, obligations, and records within a date range or for a specific topic. Generated by PDFKit.

Use cases:
- Sharing context with a lawyer before a consultation
- Submitting documentation to a housing advocacy service
- Creating a personal record of an employment dispute

The timeline PDF is generated on-device and shared via the share sheet. It never leaves the device via any Open Nook Foundation infrastructure.

### 7.2 Dispute documentation package

For specific dispute types (security deposit, insurance claim, workplace complaint), a structured export containing:

- Chronological record of all relevant events
- All supporting documents in a single PDF
- Summary page with key dates, parties, and claimed amounts
- Statement of facts in plain language generated by Foundation Models

Formatted for small claims court or an ombudsman submission. The user reviews and edits before export.

### 7.3 EventKit deadlines

Every obligation with a due date is written to EventKit as a calendar event. LegalNook uses a dedicated calendar ("LegalNook Obligations") rather than writing to the default calendar, so the user can distinguish legal deadlines from personal events.

Lead-time reminders per obligation type:
- Court dates: 14 days and 2 days
- Lease notice windows: at window start and 7 days before deadline
- Insurance renewals: 30 days and 7 days
- Licence renewals: 60 days and 14 days
- Document expiry: 90 days and 30 days (passport, driving licence)

### 7.4 SALI Alliance taxonomy

LegalNook aligns its canonical `LegalMatter` model with the SALI (Standards Advancement for the Legal Industry) Alliance legal matter taxonomy. SALI is the emerging standard for structured legal data and provides interoperability with legal practice management software.

OFX (Open Financial Exchange) is used as a bridge standard for financial obligation data where applicable -- payment schedules, recurring charges, settlement amounts.

---

## 8. Files App Integration

`NSFileProviderReplicatedExtension` maps LegalNook's document store as a first-class folder in the iOS Files sidebar. Users and their lawyers can edit documents in external apps and have changes reflected in LegalNook immediately.

The FileProvider extension is declared in `Packages/NookCore/Sources/FileProvider/` and shared with the suite (see ARCHITECTURE.md §12.4). The specific caveat for LegalNook: a nightly backup routine running simultaneously with a FileProvider write from an external editor risks producing broken or duplicate files. Both the `NookFileCoordinator` actor (intra-process serial queue) and `NSFileCoordinator` (inter-process lock) are required -- neither alone is sufficient.

---

## 9. Printing and PDF Export

Two distinct concerns handled by two distinct APIs:

**PDFKit** (`Packages/LegalNookCore/Sources/PDF/`) -- all PDF generation and reading:
- Reading incoming documents via `PDFDocument` feeding the VNRecognizeTextRequest pipeline
- Generating legal timeline exports as `PDFDocument` with `PDFPage` and `PDFAnnotation`
- Generating dispute documentation packages
- Obligation summary PDFs for sharing with legal representatives

**UIPrintPageRenderer / AirPrint** (`Packages/LegalNookCore/Sources/Printing/`) -- direct-to-printer path:
- Attorneys requiring physical hardcopy evidence logs
- Court filings that require printed copies
- Personal record keeping where digital-only is insufficient

UIPrintPageRenderer requires explicit page break management and bounding box calculations. SwiftUI views cannot be passed directly to the renderer -- CoreText layout strings are used for all print layouts. Print operations run on a background queue to avoid blocking the main rendering loop.

---

## 10. Spotlight Integration

A Spotlight index extension (`CSIndexExtensionRequestHandler` subclass) at `Apps/LegalNook/Extensions/Indexer/` allows LegalNook to re-index Spotlight content even when the app is terminated. Legal deadlines, document titles, and party names become searchable from iOS Spotlight.

The extension is invoked at the system's discretion and must never access SwiftData directly -- the system may invoke it while the main app is mid-transaction. All data is read from the App Group key-value store:

```swift
final class LegalNookIndexExtension: CSIndexExtensionRequestHandler {
    override func searchableIndex(
        _ searchableIndex: CSSearchableIndex,
        reindexAllSearchableItemsWithAcknowledgementHandler handler: @escaping () -> Void
    ) {
        // Read from App Group -- never from SwiftData. This key is one of the
        // closed flat extension keys (ARCHITECTURE.md §4.3): a Codable blob
        // decoded via the typed accessor, cheap enough for extension memory limits.
        let deadlines = NookAppGroup.read([DeadlineSummary].self,
                                          key: "nook.legalnook.upcomingDeadlines") ?? []
        let items = deadlines.map { deadline -> CSSearchableItem in
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = deadline.title
            attributes.contentDescription = "Due \(deadline.formattedDate)"
            attributes.keywords = [deadline.category, "deadline", "legal"]
            return CSSearchableItem(uniqueIdentifier: deadline.id, domainIdentifier: "app.legalnook.deadlines", attributeSet: attributes)
        }
        searchableIndex.indexSearchableItems(items) { _ in handler() }
    }
}
```

Indexed content: obligation titles and due dates, document titles and party names, record summaries. Document content is not indexed -- it is sensitive and Spotlight results are visible without authentication.

---

## 11. UTType Declarations

LegalNook declares strict UTType conformances for document ingestion. Without explicit type declarations, the system file presenter refuses to ingest assets with non-standard extensions.

Declared in Info.plist as **document types** (`CFBundleDocumentTypes`) — these are Apple-owned system types, which an app can open but must never declare as exported (exported means the app owns the type):
- `UTType.pdf` -- primary legal document format
- `UTType.pkpass` -- court-issued digital credentials where applicable
- `public.text` -- plain text legal documents

Declared as **exported** type identifiers (LegalNook owns these):
- `app.legalnook.timeline` -- legal timeline export package
- `app.legalnook.dispute` -- dispute documentation package

---

## 12. CareNook Dependency

LegalNook and CareNook have a specific cross-app dependency: healthcare proxy documents.

When a care recipient grants a caregiver decision-making authority, the legal mechanism is a healthcare proxy or power of attorney document. This document lives in LegalNook (it is a legal document with an expiry date and parties). CareNook references it to confirm that a caregiver's authority over a care recipient's medical decisions is legally documented.

The cross-reference is uni-directional: CareNook reads from LegalNook's App Group shared data to confirm a healthcare proxy document exists and is current. LegalNook does not read from CareNook.

The specific App Group key: `nook.legalnook.healthcareProxies` (closed flat extension-key set, ARCHITECTURE.md §4.3) -- an array of proxy document summaries (party names, effective date, expiry) that CareNook displays when a caregiver is setting up care coordination.

---

## 13. NookInsights Dimensions

```swift
// Legal and administrative context
var legalDeadlineDaysToNearest: Float?    // days to nearest obligation deadline
var activeDisputeCount: Float?             // number of unresolved disputes
var housingStabilityScore: Float?          // 0-1, based on lease status, notices received
var financialObligationDensity: Float?     // bills and payments clustering in current month
var documentExpiryDaysToNearest: Float?   // passport, licence, insurance
```

### 13.1 Cross-suite correlations

Legal stress is among the strongest documented predictors of adverse health outcomes. LegalNook enables NookInsights to find these correlations at the individual level:

- Court date proximity correlating with GAD-7 anxiety scores in MindNook
- Dispute periods (between escalation and resolution) correlating with PHQ-9 depression scores
- Housing instability events (eviction notices, emergency maintenance) correlating with HRV decline in SleepNook
- High financial obligation density correlating with fatigue ratings in SymptomNook

These are population-level findings in public health research. LegalNook makes them findable at the individual level.

---

## 14. API Surface

```
Packages/LegalNookCore/Sources/
  Documents/               VNRecognizeTextRequest, PDFKit, Foundation Models
  Security/                LocalAuthentication/LAContext, .biometryCurrentSet
  Extraction/              @Generable LegalDocumentExtraction schema
  PDF/                     PDFKit -- PDF generation and reading
  Printing/                UIPrintPageRenderer, AirPrint
  Bridge/
    Timeline/              Legal timeline PDF generation
    Dispute/               Dispute documentation package
    EventKit/              Obligation deadline writing
  FileProvider/            NSFileProviderReplicatedExtension (shared, NookCore)

Apps/LegalNook/
  Extensions/
    Indexer/               CSIndexExtensionRequestHandler
  Info.plist               UTType declarations

Primary frameworks:
  Vision/VNRecognizeTextRequest (document scanning and OCR)
  PDFKit (PDF reading and generation)
  LocalAuthentication/LAContext (.deviceOwnerAuthenticationWithBiometrics)
  Foundation Models (@Generable extraction schemas)
  EventKit (obligation deadline calendar events)
  CoreSpotlight (Spotlight index extension via CSIndexExtensionRequestHandler)
  UniformTypeIdentifiers/UTType (document type filtering)
  NSFileProviderReplicatedExtension (Files app integration)
  AppIntents, WidgetKit, UserNotifications, BGProcessingTask, MetricKit

Entitlements required before App Store submission:
  None beyond standard (LocalAuthentication and NSFileProviderReplicatedExtension
  are standard entitlements, no Apple review required)
```

---

## 15. Design Gaps

The following areas require design work before phase 17 build begins. This section is intentionally explicit -- these are not forgotten details, they are acknowledged gaps.

**Entitlements category — DECIDED (staged hybrid, see DECISIONS.md).** The data model is defined (§3.4). Population strategy:
- **v1:** manual entry, plus a curated per-jurisdiction **link-out directory** pointing at official and legal-aid sources (state AG tenant-rights guides, government benefits pages). Near-zero liability; real discovery value; each link carries a last-verified date.
- **v2:** high-traffic jurisdictions graduate to in-app rules content via the community-contribution pipeline — trust tiers (Official / Community / Contributed), CI validation, and mandatory staleness dates, reusing the nook-integrations model. Content is strictly factual and cited to primary sources ("California Civil Code §1950.5, verified 2026-03") — information, never advice, consistent with §1.
- **Foundation Models participates only as a classifier** at every stage: mapping the user's documents to which curated topics apply ("California residential lease → show CA tenant-rights entries"). It never generates entitlement content — hallucinated legal rights are unacceptable, and generation would contradict this document's "organises, does not interpret" north star.

**Government portal adapters** -- The AcademicNook adapter pattern applies in principle. Which government portals have APIs that could be adapted, and which require PDF scraping or manual entry, requires per-jurisdiction research. USCIS (US immigration) and IRS (tax transcripts) have documented APIs. Most court portals, utility portals, and local government systems do not.

**Specific legal matter type flows** -- The SALI taxonomy defines categories but the UI flow for each type (creating a landlord dispute vs tracking a court case vs managing an insurance claim) is not designed. Each type likely needs a tailored entry flow.

**Dispute documentation flow** -- The dispute documentation package is defined as a bridge output (§7.2) but the step-by-step flow for assembling one -- which documents to include, how to generate the narrative, what format is appropriate for which dispute type -- is not designed.

**Entitlements discovery** -- How LegalNook discovers what rights the user has (tenant rights, consumer rights, employee rights) based on their jurisdiction and circumstances is not designed. This requires legal content curation by jurisdiction, which has maintenance and accuracy obligations.

**Legal representation integration** -- Whether and how LegalNook could integrate with legal aid organisations, pro bono referral services, or attorney-client communication (without storing attorney-client privileged communications on a device) is not designed.

---

## 16. Revision History

| Version | Date | Changes |
|---|---|---|
| 1.1 | July 2026 | Decision-record patch (DECISIONS.md). §6.1 vault fixed: enrollment-change baseline persisted to Keychain (in-memory baseline was a no-op across launches), domain state read only after successful canEvaluatePolicy, deprecated evaluatedPolicyDomainState replaced with domainState, session-scoped unlock reconciled with explicit user-initiated authentication. §10 Spotlight class name corrected to CSIndexExtensionRequestHandler; App Group read uses the typed Codable flat-key accessor with namespaced key. §11 Apple-owned types moved from exported declarations to document types. §12 App Group key namespaced. §14 stray CloudKit timeline-export entry removed (timeline is on-device via share sheet, §7.1). §15 entitlements category resolved to the staged hybrid: v1 manual entry + curated link-out directory, v2 trust-tiered community rules content, Foundation Models as document→topic classifier only. Org name unified to Open Nook Foundation. |
| 1.0 | May 2026 | Initial design document. Four data categories, document ingestion pipeline (PDFKit + VNRecognizeTextRequest), Foundation Models extraction schema, LAContext biometric vault, bridge out (timeline, dispute package, EventKit), Files app integration, PDFKit vs AirPrint split, Spotlight, UTType declarations, CareNook healthcare proxy dependency, NookInsights dimensions, API surface, design gaps |
