# AcademicNook Design Document

**Version:** 1.0  
**Date:** May 2026  
**Status:** Pre-build. Design complete. Build begins after SyncNook (phase 5) through CycleNook (phase 8) ship.

---

## Table of Contents

1. [North Star](#1-north-star)
2. [The Problem](#2-the-problem)
3. [Three Roles](#3-three-roles)
4. [Student Role](#4-student-role)
5. [Counsellor Role](#5-counsellor-role)
6. [Teacher Role](#6-teacher-role)
7. [LMS Adapter Architecture](#7-lms-adapter-architecture)
8. [SIS and Grade Integration](#8-sis-and-grade-integration)
9. [Food Service Integration](#9-food-service-integration)
10. [Supplemental Tools](#10-supplemental-tools)
11. [Grade Calculation Engine](#11-grade-calculation-engine)
12. [What-If Grades](#12-what-if-grades)
13. [Syllabus Parsing](#13-syllabus-parsing)
14. [Rubric Discovery](#14-rubric-discovery)
15. [Google Workspace Integration](#15-google-workspace-integration)
16. [OneRoster Bridge API](#16-onerroster-bridge-api)
17. [Proxy and Identity Verification](#17-proxy-and-identity-verification)
18. [Configuration Distribution](#18-configuration-distribution)
19. [Community Configuration Repository](#19-community-configuration-repository)
20. [Partner Program](#20-partner-program)
21. [Integration Quality Tiers](#21-integration-quality-tiers)
22. [Platform Capability Validation](#22-platform-capability-validation)
23. [NookInsights Academic Dimensions](#23-nookinsights-academic-dimensions)
24. [ClassKit](#24-classkit)
25. [API Surface](#25-api-surface)
26. [Privacy and FERPA](#26-privacy-and-ferpa)
27. [Revision History](#27-revision-history)

---

## 1. North Star

> AcademicNook is the student's unified interface to an academic ecosystem designed for institutions, built by vendors who never spoke to each other, and left the student to navigate five separate apps that each know only their corner of a life the student experiences as one thing.

The student's academic life is scattered across Canvas for assignments, PowerSchool for grades, Naviance for college planning, x2VOL for volunteer hours, Nutrislice for lunch menus, and a dozen supplemental tools like NoRedInk and SmartMusic. None of these platforms know each other exist. None of them have access to the student's health data. None of them can find the connection between a student's sleep quality and their assignment completion rate, or between their school lunch sodium intake and their afternoon performance.

AcademicNook aggregates all of it. The student logs in once. Everything is in one place. The health correlation layer -- shared with the rest of the Nook suite -- finds patterns no single platform could discover.

**What AcademicNook explicitly is not:**

- Not a replacement for Canvas, Schoology, or any institutional platform -- those systems remain the official record. AcademicNook is the student-facing layer.
- Not a server that holds student data -- all data lives in the student's iCloud container.
- Not a gamified academic tracker -- no streaks, no badges, no leaderboards.
- Not a tutoring tool -- AcademicNook surfaces patterns and priorities, it does not teach content.

---

## 2. The Problem

The student's academic ecosystem has no HealthKit equivalent. HealthKit is a neutral, universal, encrypted store that every health app writes to. The academic ecosystem has no such layer. Every LMS, every SIS, every supplemental tool maintains its own silo. The student is the only stakeholder who experiences all of these systems simultaneously -- and the only one with no purchasing power to demand integration.

The fragmentation causes concrete harm:

A student who loses track of a Naviance college application deadline because they checked it three weeks ago and forgot to go back. A student whose Canvas grade shows 92% because Canvas ignores their three missing assignments. A student who does not know they need an 87% on the final exam to keep their B because calculating weighted grades manually requires a spreadsheet. A student who wrote their volunteer hour reflection weeks after the service event and cannot remember what they did. A student whose school lunch sodium intake correlates with afternoon fatigue but no one -- including the student -- has ever had the data to find this.

AcademicNook fixes these individually and collectively.

---

## 3. Three Roles

AcademicNook presents three distinct interfaces from a single app. Role is selected at first launch and changeable in Settings > Account.

```swift
public enum AcademicNookRole: String, Codable, Sendable {
    case student
    case counsellor
    case teacher
}
```

The underlying data model is shared. A teacher's grade entries are a student's grade view. A counsellor's meeting notes appear in the student's counselling record. One app, three lenses on the same data.

Role switching requires biometric authentication to prevent accidental role change and to ensure the role was intentionally selected.

---

## 4. Student Role

### 4.1 Today view

The student's primary interface. Single scrollable view showing:

- Assignments due today and tomorrow, sorted by urgency (time remaining, not alphabetical)
- Current grade standing per course -- using AcademicNook's corrected calculation, not Canvas's inflated version
- NookInsights academic nudge if relevant (exam in 3 days, sleep has been low this week)
- School lunch menu for today with tap-to-confirm logging to NutriNook
- Volunteer hours status relative to any active deadline

No tabs. No navigation hierarchy on the today view. The student opens AcademicNook and sees what matters right now.

### 4.2 Assignments

Full assignment list with filtering by course, status (not started / in progress / submitted / graded), and due date. Long press on any assignment reveals:

- Rubric if discovered (see §14)
- Study priority analysis if rubric is available
- Grade impact calculation: what score on this assignment changes my course grade by how much
- Teacher's previous feedback on similar assignments

### 4.3 Grades

Per-course grade view showing:

- Current grade using corrected calculation (unsubmitted = zero, not excluded)
- Category breakdown with visual contribution bars
- Grade trajectory (improving/stable/declining over last 4 weeks)
- What-if grade simulator (see §12)

### 4.4 College Planning

Owned natively in AcademicNook. The student maintains their college list here. When institutional submission to Naviance is required, AcademicNook opens Naviance at the correct screen to file the data -- the student does not maintain data in two places.

- College list with application status, deadlines, and notes
- Scholarship tracker with deadlines and requirements
- Counsellor appointment schedule
- Teacher recommendation request tracker with per-school deadlines

### 4.5 Volunteer Hours

Native tracking with institutional submission.

The student logs service entries in AcademicNook immediately after the service event. The reflection is written then, not weeks later. GPS optional check-in at service start and end provides independent verification.

Submission to x2VOL, Helper Helper, or other institutional platforms happens via guided web flow when the student or advisor requires it. AcademicNook stores the reflection so the student can copy it into the required field.

---

## 5. Counsellor Role

### 5.1 Student roster

The counsellor sees only students who have explicitly shared with them. Data access is student-initiated, scoped, and revocable. No counsellor can search for students by school or district -- they receive only shares that students initiate.

Roster view flags students requiring attention:

```swift
public enum CounsellorFlag: String, Sendable {
    case collegeListIncomplete
    case scholarshipDeadlineSoon
    case gradesDeclining          // only if student shared grade data
    case volunteerHoursShortfall
    case juniorMeetingNotScheduled
    case seniorMeetingNotScheduled
    case recommendationRequestPending
}
```

### 5.2 Student detail view

When a counsellor taps a student, they see only what the student shared. A student who shared college list and appointments but not grades shows college list and appointments. A student who shared everything shows everything. Health data is never part of any counsellor share scope.

### 5.3 Counsellor minimal QR

The counsellor generates a student invite QR code from within AcademicNook's counsellor role. Students at their school scan it to connect. The QR code contains only the counsellor's ID, school name, display name, and a share code. It configures no LMS settings.

```
Share with your students

[QR CODE]

Students scan this to connect
with you in AcademicNook

[ Share as link instead ]
```

### 5.4 Schoolwork and Managed Apple IDs

Schoolwork requires a Managed Apple ID through Apple School Manager. Students on personal Apple IDs -- the majority of secondary students -- cannot use Schoolwork. The counsellor sharing model via CloudKit CKShare is the primary teacher/counsellor visibility mechanism for non-managed devices. Managed Apple ID students additionally get ClassKit data in Schoolwork (see §24).

---

## 6. Teacher Role

### 6.1 Assignment density view

The teacher's most valuable view. Shows aggregate assignment density across their connected students' full course load -- not just this teacher's assignments, but everything the student has due.

The teacher does not see which specific assignments come from which teachers. They see "your students have an average of 4.2 major assignments due this week across all courses." This is enough to make a scheduling decision (defer the essay deadline by three days) without exposing other teachers' gradebook content.

Students opt in to this visibility by accepting the teacher's share.

### 6.2 Recommendation letter tracker

A student initiates a recommendation request in AcademicNook, the teacher accepts. AcademicNook tracks per-school deadlines for letters owed to multiple students. The teacher sees a list of outstanding letters sorted by nearest deadline with EventKit reminders.

### 6.3 ClassKit progress

For students with Managed Apple IDs on managed devices, ClassKit progress data (study session duration, completion rate) is visible through Schoolwork, not AcademicNook's teacher role. AcademicNook's teacher role is for the non-managed population.

---

## 7. LMS Adapter Architecture

### 7.1 Protocol

```swift
// NookCore -- platform-agnostic adapter protocol
public protocol LMSAdapter: Sendable {
    static var id: String { get }
    static var displayName: String { get }
    static var status: LMSAdapterStatus { get }
    static var requiresInstitutionURL: Bool { get }
    static var defaultEndpoints: LMSEndpoints? { get }

    func validateEndpoints(_ endpoints: LMSEndpoints) async throws
    func authenticate(credential: LMSCredential, endpoints: LMSEndpoints) async throws -> LMSSession
    func fetchCourses(session: LMSSession, endpoints: LMSEndpoints) async throws -> [LMSCourse]
    func fetchAssignments(course: LMSCourse, session: LMSSession, endpoints: LMSEndpoints) async throws -> [LMSAssignment]
    func fetchGrades(session: LMSSession, endpoints: LMSEndpoints) async throws -> [SISGrade]
    func fetchCollegeList(session: LMSSession, endpoints: LMSEndpoints) async throws -> [CollegeApplication]
    func writeCollegeList(_ applications: [CollegeApplication], session: LMSSession, endpoints: LMSEndpoints) async throws
    func fetchVolunteerHours(session: LMSSession, endpoints: LMSEndpoints) async throws -> [ServiceEntry]
    func writeVolunteerHours(_ entry: ServiceEntry, session: LMSSession, endpoints: LMSEndpoints) async throws
}

public enum LMSAdapterStatus: Sendable {
    case official(partnerSince: Date)
    case sanctioned(documentedSince: Date)
    case community(reverse: Bool)
    case unofficial(warning: String)
}

public struct LMSEndpoints: Codable, Sendable {
    public var baseURL: URL
    public var authorizationURL: URL
    public var tokenURL: URL
    public var apiBaseURL: URL
}
```

Adapters live in `Packages/LMSAdapters/Official/` or `Packages/LMSAdapters/Unofficial/`. No dynamic library loading. All adapters are compiled into the binary. Unofficial adapters surface a one-sentence disclosure in the setup UI -- honest, not apologetic.

### 7.2 Tier 1 integrations

| Platform | Auth | Endpoints | Status | Notes |
|---|---|---|---|---|
| Google Classroom | PKCE, public client | Fixed (cloud) | Official | Day 1. See §15 for Google Workspace integration. |
| Canvas | Per-institution client secret in Keychain; manual token fallback | Per-institution URL | Official | District admin issues credentials or student generates personal token |
| Schoology | OAuth 1.0a, HMAC-SHA1 on-device | Per-institution URL | Official | No server needed for signing |
| Clever | PKCE, public client | Fixed (SSO layer) | Official | Broad district coverage |
| PowerSchool SIS | OAuth 2.0 public client | Per-institution URL | Official | Grade and attendance data |
| StudentVue/Synergy | Via foundation-published bridge server (OneRoster/LTI); app never holds SIS credentials | District- or self-hosted bridge URL | Bridge | See §8.2. Direct on-device credential scraping is refused. |

### 7.3 Write access policy

Write access where the student owns the data:
- College list (add, update status, mark deadlines)
- Volunteer hours submission
- Scholarship tracker
- Counsellor appointment requests
- Reflection text submission to x2VOL

Read-only where the institution owns the data:
- Grades
- Attendance records
- Counsellor notes
- Teacher gradebook entries

### 7.4 Credential handling

All credentials in Keychain. Foreground-only credentials (Canvas personal tokens entered manually) use `kSecAttrAccessibleWhenUnlocked` with `kSecAttrAccessControl` `.userPresence` (Face ID/Touch ID to access). OAuth tokens used by background refresh use `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` and never `.userPresence` — background reads fail on locked devices otherwise (ARCHITECTURE.md §14.18). SIS passwords (StudentVue/Synergy) are never held on device in any form — see §8.2.

All OAuth flows via `ASWebAuthenticationSession` exclusively. Never `WKWebView`.

---

## 8. SIS and Grade Integration

### 8.1 The unsubmitted assignment trap

Canvas treats unsubmitted assignments as absent from the grade calculation, artificially inflating the displayed grade. A student with three missing 100-point assignments sees a higher Canvas grade than their teacher will calculate for the final grade.

AcademicNook counts unsubmitted assignments as zero by default and tells the student why:

```
Your current grade in Chemistry: 87%

Note: Canvas shows 92% because it excludes
your 2 missing assignments. AcademicNook
counts missing work as zero, which is how
your teacher will calculate your final grade.

[ Use Canvas's calculation ]   [ Keep realistic view ]
```

### 8.2 StudentVue access — bridge server, no on-device credentials **[DECIDED]**

StudentVue has no official public API. v1.0 designed on-device SOAP scraping with student-entered credentials; that design is withdrawn — student SIS credentials were the riskiest security surface in the suite, and the app **refuses direct-scrape mode entirely** (no unsupported fallback; a credential-capture surface removed at the front door does not re-enter through the back).

The replacement: the Open Nook Foundation publishes an **open-source bridge server** (StudentVue/Synergy SOAP → OneRoster/LTI translation) that districts or families **self-host**. The trust boundary, stated precisely:

- SIS credentials live only on the bridge — a server operated by the district or the self-hoster, **never by the foundation**. The suite's server carve-out is amended accordingly: config/auth servers acceptable, data servers never, and credential-holding servers are never foundation-operated.
- The app speaks only OneRoster/LTI to the bridge, slotting into the existing OneRoster bridge design (§16) — same adapter, same quality tier, no StudentVue-specific code path in the app.
- The threat model moves with the credentials: credential storage at rest, token lifetime, and audit logging are specified in the bridge repository and its deployment guide for district IT, not in this document.

The in-app connection flow asks for a bridge URL (or discovers a district-configured one via Managed App Configuration), then runs standard OneRoster auth:

```
Connect your school (StudentVue districts)

Your district runs a small connector that
AcademicNook talks to. Your school password
is never entered into this app.

[Bridge URL — usually preconfigured by your school]

[ Connect ]

Self-hosting for families: docs & one-command
deploy at github.com/opennookfoundation/nook-sis-bridge
```

---

## 9. Food Service Integration

### 9.1 Adapter protocol

```swift
public protocol FoodServiceAdapter: Sendable {
    static var id: String { get }
    static var displayName: String { get }
    static var requiresInstitutionConfig: Bool { get }
    static var defaultEndpoints: FoodServiceEndpoints? { get }

    func fetchTodayMenu(config: FoodServiceConfiguration) async throws -> [SchoolMenuItem]
    func fetchWeekMenu(weekOf date: Date, config: FoodServiceConfiguration) async throws -> [Date: [SchoolMenuItem]]
    func fetchNutrition(itemID: String, config: FoodServiceConfiguration) async throws -> NutritionData?
}
```

### 9.2 Three-tier fallback

**Tier 1 -- Vendor API**: Nutrislice (documented public API), LINQ (community-documented endpoints). Returns structured menu with nutritional data.

**Tier 2 -- Community scraper**: District-specific HTML menu scrapers contributed to the `nook-integrations` repository. Returns menu items, nutritional data varies.

**Tier 3 -- USDA standard meal profile**: NSLP-compliant meals fall within documented nutritional ranges. Returns an estimate. Quality score 0.35 vs 0.75 for Tier 1.

### 9.3 NutriNook integration

The student taps which items they ate; AcademicNook writes `HKQuantitySample` entries for all available dietary types (calories, sodium, protein, etc.) **under its own `com.apple.developer.healthkit` entitlement and its own user-granted dietary-write authorization** — AcademicNook is the declared secondary writer for dietary types, scoped to confirmed school-lunch items (ARCHITECTURE.md §5.2). NookCore shares the sample-construction code; it cannot and does not share permission — entitlements and HealthKit authorization are per bundle ID. Samples carry AcademicNook as `HKSource`. The student never opens NutriNook to log school lunch. Note the App Group direction (§23): this HealthKit write is the only health-adjacent output AcademicNook produces; it reads no health data anywhere.

### 9.4 JSON configuration

Food service configuration is part of the institution's JSON config:

```json
{
  "foodService": {
    "adapterID": "linq",
    "districtID": "lcps-va-001",
    "schoolMappings": {
      "Stone Bridge High School": "4438"
    }
  }
}
```

---

## 10. Supplemental Tools

### 10.1 Category

Supplemental curriculum tools (NoRedInk, Gizmos, SmartMusic, Khan Academy, IXL, Desmos) are not LMSes. They do one thing well and integrate with the LMS via LTI grade passback. AcademicNook already sees their grades through the LMS adapter. The gap is the rich progress data that lives only in the supplemental tool.

### 10.2 Data tiers

| Tier | Mechanism | Tools | Quality |
|---|---|---|---|
| A | LTI grade passback through LMS | All LTI-connected tools | Already covered |
| B | PDF progress report import | NoRedInk, Gizmos, IXL | `periodicExport`, student-initiated |
| C | Official API | SmartMusic, Khan Academy | `liveAPI`, full adapter |
| D | No data path | Completion boolean only | LMS shows completion, nothing more |

### 10.3 SmartMusic full adapter

SmartMusic has a documented API. Practice session timestamps, duration, exercise completion, and performance scores are longitudinal behavioural data that correlates with SleepNook, MindNook, and HabitNook. A student with a "practice instrument" habit in HabitNook gets automatic completion verification when SmartMusic confirms a session.

### 10.4 PDF import flow

```
NoRedInk Progress Import

1. Open NoRedInk in Safari
2. Go to Profile > Progress Report
3. Tap Share > Save to Files
4. Return here and tap Import

[ Open NoRedInk ]   [ Import from Files ]

Last imported: 3 days ago
```

The "Open NoRedInk" button is a pre-configured URL opening the correct page. The FileProvider extension monitors for new PDFs matching known report formats and offers to import automatically.

---

## 11. Grade Calculation Engine

### 11.1 Full scheme taxonomy

AcademicNook handles all real-world grading schemes:

1. **Pure points-based** -- total earned / total possible
2. **Weighted categories** -- category average × category weight, where within-category averages are points-weighted (not percentage-averaged)
3. **Weighted categories with drop rules** -- lowest N scores dropped per category before averaging
4. **Fixed-value final exam** -- coursework fills a fixed percentage, final exam fills the remainder exactly
5. **Replacement final** -- final replaces lowest exam score if better
6. **Mandatory minimum** -- must score above threshold on final exam to pass regardless of other grades
7. **Hybrid** -- weighted categories plus fixed final
8. **Extra credit** -- adds to earned points without adding to possible
9. **Pass/fail** -- threshold-based
10. **Standards-based** -- mastery levels, no numerical average

### 11.2 The critical within-category calculation

Within a weighted category, individual assignments are weighted by point value, not equally. Averaging the percentages is wrong:

```
Two assignments in Tests category (40% of grade):
  10-point quiz:    10/10 = 100%
  100-point exam:   60/100 = 60%

Wrong (average percentages): (100 + 60) / 2 = 80%
Correct (points-weighted):   70/110 = 63.6%
```

The 100-point exam dominates as it should. AcademicNook always uses points-weighted averages within categories.

### 11.3 Fixed-percentage final calculation

The most common miscalculation in grade calculators. Correctly:

```
Syllabus: Coursework 80%, Final Exam 20%
Coursework categories: Homework 10%, Tests 40%, Projects 30%

Step 1: Normalise coursework weights to their 80% bucket
  Homework:  10/80 = 12.5% of coursework bucket
  Tests:     40/80 = 50.0% of coursework bucket
  Projects:  30/80 = 37.5% of coursework bucket

Step 2: Calculate coursework grade within the bucket
  Homework avg 92%, Tests avg 78%, Projects avg 88%
  Coursework grade = (92×12.5 + 78×50 + 88×37.5) / 100
                   = 83.5% (within the coursework bucket)

Step 3: Coursework contribution to final grade
  83.5% × 0.80 = 66.8% of total grade earned so far

Step 4: Maximum achievable
  66.8% + 100% × 0.20 = 86.8% (if perfect on final)

Step 5: Needed on final for target grade
  To get 90%: (90% - 66.8%) / 20% = 116% -- not achievable
  To keep 85%: (85% - 66.8%) / 20% = 91% on final
```

### 11.4 Syllabus vs LMS conflict detection

When the syllabus extraction produces a different grading scheme than the LMS API returns, the student is notified and asked to choose:

```
Grade scheme conflict detected in Chemistry

Your Canvas gradebook is set to total points,
but your syllabus says:
  Tests:        40%
  Homework:     30%
  Final Exam:   20%
  Participation: 10%

[ Use syllabus weights ]   [ Use Canvas points ]   [ Ask my teacher ]
```

"Ask my teacher" generates a pre-written email draft.

---

## 12. What-If Grades

### 12.1 Scenarios

The student enters hypothetical scores for upcoming assignments and sees the resulting course grade in real time. Three default scenarios are pre-populated -- best case, likely, worst case -- shown side by side:

```
Chemistry              Best    Likely  Worst
                       94%     83.5%   72%

Final Exam (20%)       [──────────────────]
Tests avg              [──────────────────]
Projects avg           [──────────────────]

To get an A (90%):     Need 116% -- not achievable
To keep a B (83%):     Need 81% on final
Currently on track:    B (83.5% if 83% on final)
```

### 12.2 Needed score calculation

Binary search over the score space to find the exact score needed on a specific assignment to achieve a target grade:

```swift
func neededScore(target: Double, on assignment: AssignmentGrade, in model: CourseGradeModel) -> NeededScoreResult {
    var low = 0.0
    var high = assignment.pointsPossible
    for _ in 0..<50 {
        let mid = (low + high) / 2.0
        let result = calculateGrade(for: model, scenarios: [WhatIfScenario(assignmentID: assignment.id, hypotheticalPoints: mid)])
        result.currentPercentage < target ? (low = mid) : (high = mid)
    }
    let needed = (low + high) / 2.0
    return NeededScoreResult(pointsNeeded: needed, percentNeeded: needed / assignment.pointsPossible, isAchievable: needed <= assignment.pointsPossible)
}
```

### 12.3 NookInsights integration

When the what-if engine determines the student needs a high score on an upcoming exam, NookInsights combines this with sleep data:

```
Your Chemistry final is in 8 days.
You need 94% to keep your A.

Your sleep quality this week is below your
personal baseline. Your data shows your exam
performance is typically 12% lower when your
sleep efficiency is under 68% the night before
a major assessment.

Prioritising sleep this week may matter more
than additional study hours.
```

### 12.4 Anxiety-aware presentation

When MindNook GAD-7 trend is elevated, the presentation shifts from deficit-focused to action-focused. "You need 94%" becomes "You're on track -- here's what to focus on." The underlying calculation is identical; the framing changes to avoid amplifying anxiety.

---

## 13. Syllabus Parsing

### 13.1 Input formats

The pipeline handles all real-world syllabus formats:

- **PDF with text layer** -- PDFKit `page.string` extraction, confidence 0.95
- **Scanned PDF** -- rasterise pages at 2x scale, `VNRecognizeTextRequest` with `.accurate` level, confidence 0.80
- **Google Doc** -- Drive API text/plain export, confidence 1.0
- **HTML** -- NSAttributedString HTML import, confidence 0.90
- **Camera capture** -- `DataScannerViewController` multi-page capture, confidence 0.78
- **DOCX** -- mammoth.js or equivalent extraction

Scanned PDF detection: if PDFKit yields fewer than 50 characters per page on average, the PDF has no text layer and VNRecognizeTextRequest is used instead.

### 13.2 Extraction schema

```swift
@Generable struct SyllabusExtraction {
    var gradingCategories: [SyllabusGradeCategory]
    var finalExamPolicy: SyllabusFinalExamPolicy?
    var dropPolicies: [SyllabusDropPolicy]
    var minimumRequirements: [SyllabusMinimumRequirement]
    var lateWorkPolicy: SyllabusLateWorkPolicy?
    var importantDates: [SyllabusDate]
    var examSchedule: [SyllabusExam]
    var courseName: String?
    var teacherName: String?
    var requiredMaterials: [String]
    var attendancePolicy: SyllabusAttendancePolicy?
    var extractionConfidence: Double
    var uncertainSections: [String]
    var isSyllabus: Bool
}
```

### 13.3 Validation

- Grading weights must sum to 100% (within 2% tolerance)
- If weights do not sum to 100%, flag in `uncertainSections` and surface to student
- OCR numeric values flagged for manual review when confidence < 0.75
- Final exam weight > 50% surfaces a confirmation prompt

### 13.4 Student confirmation UI

```
Syllabus imported from Chemistry H5 Syllabus.pdf

Grade breakdown                        Edit all
  Tests & Quizzes     40%              OK
  Lab Reports         25%              OK
  Homework            15%              OK
  Final Exam          20% (fixed)      OK
  ─────────────────────────────────
  Total              100%              OK

Policies
  Late work: 10% per day, max 50%      OK
  Drop: lowest quiz grade dropped      OK
  Final minimum: must score 60%        OK

Important dates               Add to Calendar
  Nov 14  Midterm Exam                 +
  Dec 19  Final Exam                   +

Low confidence warning:
  "Tests & Quizzes: 40%" may be
  "Tests 30%, Quizzes 10%" separately.
  Please verify.

[ Apply to Chemistry ]   [ Edit manually ]
```

### 13.5 Automatic discovery

AcademicNook searches for syllabuses automatically after a course is connected:

1. LMS course materials -- files with "syllabus" in the title
2. LMS course description -- if it contains grade policy keywords and percentage patterns
3. Google Drive -- search for "[course name] syllabus" in the student's Drive
4. Prompt student to provide if not found

### 13.6 Ongoing reconciliation

When the LMS gradebook configuration diverges from the parsed syllabus by more than 5 percentage points on any category, the student is notified. Syllabuses sometimes change mid-semester. The reconciliation prompt appears at the start of each week if a divergence is detected.

---

## 14. Rubric Discovery

### 14.1 Seven-layer fallback pipeline

```swift
actor RubricDiscoveryEngine {
    func discoverRubric(for assignment: LMSAssignment, course: LMSCourse, session: LMSSession) async -> RubricDiscoveryResult {
        // 1. Native LMS rubric (Canvas rubric builder, Schoology rubric) -- confidence 1.0
        // 2. Google Classroom native rubric (added 2023) -- confidence 0.95
        // 3. Linked Google Docs in assignment materials -- confidence 0.6-0.9
        // 4. Attached PDFs -- confidence 0.7
        // 5. Embedded HTML table in assignment description -- confidence 0.75
        // 6. Course-level rubric documents (shared across assignments) -- confidence 0.6-0.8
        // 7. Foundation Models inference from assignment description -- confidence 0.4-0.6
    }
}
```

### 14.2 Google Doc detection

Links in the assignment description are scored for rubric likelihood using three signals: link text contains rubric keywords ("rubric", "scoring guide", "grading criteria"), surrounding context contains the same keywords, and the linked document is a Google Doc (not a slide deck or spreadsheet).

Candidate Google Docs are fetched via Drive API text/plain export using the student's existing OAuth token. The 403 case -- document not shared with student -- surfaces a message: "Your teacher linked a rubric document but it is not shared with you. You may want to ask them to check the sharing settings."

### 14.3 Extraction schema

```swift
@Generable struct ExtractedRubric {
    var assignmentContext: String?
    var totalPoints: Double?
    var criteria: [RubricCriterion]
    var extractionConfidence: Double
    var generalNotes: String?
}

@Generable struct RubricCriterion {
    var name: String
    var pointsPossible: Double?
    var levels: [PerformanceLevel]
    var weightPercent: Double?
}

@Generable struct PerformanceLevel {
    var label: String
    var points: Double?
    var description: String
}
```

### 14.4 Teacher pattern learning

After parsing rubrics from the same teacher across multiple assignments, AcademicNook learns their patterns -- typical source (Google Doc vs embedded), typical point scale, typical criteria count, shared course-level rubric document IDs. On subsequent assignments, the engine prioritises the source that worked before.

### 14.5 Study priority analysis

When a rubric is available, Foundation Models analyses it relative to the assignment description and the student's personal criterion performance history:

```swift
@Generable struct RubricStudyAnalysis {
    var priorityCriteria: [CriterionPriority]  // highest impact based on points × difficulty
    var commonPitfalls: [String]
    var estimatedHours: ClosedRange<Double>
}
```

The analysis is personalised: a student who consistently scores below their average on "evidence analysis" criteria is specifically directed to that criterion when it appears on a high-weight assignment.

---

## 15. Google Workspace Integration

### 15.1 Identity foundation

Google Workspace for Education is the student's primary school identity for a substantial portion of US K-12 students. When a student authenticates with their school Google account, the `hd` (hosted domain) claim in the ID token confirms their district. This single authentication unlocks:

- Verified student identity for the proxy (§17)
- Automatic institution config lookup via `.well-known/academicnook-config.json`
- Domain-confirmed student for the counsellor share model
- Confirmed teacher identity for the teacher role

### 15.2 Incremental authorization **[replaces v1.0's single all-scopes flow]**

v1.0 requested every scope on one consent screen; that violates Google's incremental-authorization policy and asks students for access the app may never use. Scopes are now requested when the feature that needs them is first touched:

```swift
// First sign-in: identity + core Classroom + Calendar only
static let baseScopes: [String] = [
    "openid", "email", "profile",
    "https://www.googleapis.com/auth/classroom.courses.readonly",
    "https://www.googleapis.com/auth/classroom.coursework.me.readonly",
    "https://www.googleapis.com/auth/classroom.student-submissions.me.readonly",
    "https://www.googleapis.com/auth/classroom.announcements.readonly",
    "https://www.googleapis.com/auth/calendar.readonly",
    "https://www.googleapis.com/auth/tasks.readonly",
]

// Requested on first assignment-document fetch (§15.4)
static let driveScopes: [String] = [
    "https://www.googleapis.com/auth/drive.readonly",
]

// Requested only on explicit opt-in (§15.5)
static let gmailScopes: [String] = [
    "https://www.googleapis.com/auth/gmail.readonly",
]
```

**Restricted-scope verification (accepted cost, DECISIONS.md):** both `drive.readonly` and `gmail.readonly` are Google **restricted** scopes (all full-Drive scopes were reclassified restricted in 2019 — Gmail is not the only trigger). Keeping both is the ruling; Drive alone already commits the app to restricted verification, so Gmail adds little marginal burden. Mitigations pursued explicitly: (1) the **on-device exemption** — Google's verification policy carves out apps that keep restricted-scope data on the user's device and never transmit it, which is precisely this architecture; (2) the **domain-trust fleet path** (§15.6) — an admin marking the app Trusted exempts it from verification for that Workspace domain, making it the primary district deployment route. Verification cost and timeline apply to the individual-consumer path only.

### 15.3 Calendar integration

Google Calendar holds school events not in Classroom: holidays, exam dates, sports events, school play rehearsals. AcademicNook fetches from all subscribed school calendars (filtered by domain) and writes school holidays and exam periods to EventKit. EventKit events are visible to NookInsights as context.

### 15.4 Drive integration

Assignment instructions often live in a Google Doc attached to the assignment. Drive API fetches the document content, which Foundation Models uses to estimate completion time, extract rubric if embedded, and enrich the assignment record.

Teacher feedback on returned work (comments in a Google Doc) is surfaced as a notification: "Your English essay was returned with feedback."

### 15.5 Gmail integration (optional)

With `gmail.readonly` scope, AcademicNook reads only emails from school domain addresses. Foundation Models extracts structured academic information: deadline mentions in teacher emails, grade report notifications, administrative notices. The student explicitly opts in with a clear disclosure that only school domain emails are read.

### 15.6 Domain admin pre-approval

A Google Workspace admin who marks AcademicNook as "Trusted" in the Admin console pre-approves it for all students in the domain. Subsequent student authentications skip the per-user consent screen. This is the fleet deployment path for Google Workspace districts.

---

## 16. OneRoster Bridge API

AcademicNook is a 1EdTech OneRoster Aggregator -- it consumes from LMS/SIS systems and provides to consuming systems.

### 16.1 Three bridge shapes

**Shape 1 -- Local device** (`NWListener` on localhost): same device only. Best for Schoolwork on the same iPad without Managed Apple ID.

**Shape 2 -- Structured export** (OneRoster CSV or JSON-LD): one-time snapshot via share sheet. Best for Google Classroom import, district reporting.

**Shape 3 -- Live personal endpoint** (Cloudflare Worker stateless passthrough): cross-network, student-controlled UUID token, revocable.

### 16.2 Shape 3 endpoint structure

```
https://bridge.academicnook.app/{token}/ims/oneroster/rostering/v1p2/classes
https://bridge.academicnook.app/{token}/ims/oneroster/gradebook/v1p2/lineItems
https://bridge.academicnook.app/{token}/ims/oneroster/gradebook/v1p2/results
https://bridge.academicnook.app/{token}/academicnook/v1/volunteerHours
https://bridge.academicnook.app/{token}/academicnook/v1/collegeList
```

The token is a UUID stored in Keychain, generated by AcademicNook, revocable from settings. The Cloudflare Worker is stateless -- it passes through to the student's device via WebSocket, stores nothing, logs nothing.

### 16.3 Permanent health data exclusion

```swift
public static let permanentlyExcluded: Set<String> = [
    "healthData", "symptomData", "nookInsights",
    "sleepData", "nutritionData", "moodData", "mentalHealthData"
]
```

No external system can request health data through the bridge regardless of what they ask for. The bridge enforces this at the Cloudflare Worker layer before the request reaches the student's device.

---

## 17. Proxy and Identity Verification

Some institutional APIs are server-to-server only -- they cannot be called directly from a student's phone. The Cloudflare Worker proxy handles these.

### 17.1 Student identity verification

```swift
enum InstitutionAuthMethod {
    case googleWorkspace(domain: String)    // verify hd claim matches domain
    case microsoftEntra(tenantID: String)   // verify token against tenant
    case enrollmentCode                     // one-time code from administrator
}
```

After verification, the proxy issues a short-lived signed JWT:
- Self-verifying (no database lookup needed)
- Stateless (proxy remembers nothing between requests)
- Student ID from verified token only -- never from request parameters
- 1-hour expiry with refresh

### 17.2 Data isolation guarantee

The proxy enforces that a verified student can only receive their own data. The student ID used in downstream API calls comes from the verified JWT, not from any parameter the student supplies. A student who tries to request another student's data by changing a parameter receives their own data regardless.

### 17.3 Open source

The proxy code is public and auditable. Any parent, district IT administrator, security researcher, or community member can verify:
- No student data is logged
- No student data is stored
- Data is transmitted only to configured institution endpoints
- Student ID enforcement prevents cross-student data access
- JWT expiry limits the window of compromised token exposure

---

## 18. Configuration Distribution

### 18.1 The .well-known endpoint

Districts publish their AcademicNook configuration at a known URL on their own domain:

```
https://lcps.org/.well-known/academicnook-config.json
```

When a student enters their school email address during setup, AcademicNook performs an automatic lookup at `https://{emailDomain}/.well-known/academicnook-config.json`. If found, the configuration is applied without the student needing to search for their school.

### 18.2 Configuration JSON structure

```json
{
  "schemaVersion": "1.0",
  "institution": {
    "id": "lcps-va",
    "name": "Loudoun County Public Schools",
    "logoURL": "https://...",
    "supportContact": "helpdesk@lcps.org"
  },
  "lms": [
    { "adapterID": "canvas", "baseURL": "https://lcps.instructure.com", "clientID": "..." },
    { "adapterID": "clever" }
  ],
  "sis": [
    { "adapterID": "powerschool", "baseURL": "https://ps.lcps.org" }
  ],
  "foodService": {
    "adapterID": "linq",
    "districtID": "lcps-va-001",
    "schoolMappings": { "Stone Bridge High School": "4438" }
  },
  "volunteerHours": { "platform": "x2vol", "districtCode": "lcps" },
  "supplementalTools": [
    { "platform": "noredink", "pdfReportURL": "https://www.noredink.com/reports/progress" },
    { "platform": "smartmusic", "apiEnabled": true, "schoolID": "lcps-4438" }
  ],
  "googleWorkspace": {
    "domainAdminApproved": true,
    "hostedDomain": "lcps.org"
  }
}
```

### 18.3 QR code distribution

Districts generate a signed QR code from `configure.academicnook.app`. The QR encodes a deep link:

```
academicnook://configure?payload=BASE64_SIGNED_PAYLOAD
```

The payload is signed with the district's own private key. AcademicNook verifies the signature before applying any configuration. The confirmation screen shows exactly what the QR code will configure before the student taps Apply.

Security guarantee: the QR code contains no student credentials. It contains only URLs and identifiers. OAuth flows happen after configuration is applied, not as part of the configuration payload.

### 18.4 NFC alternative

The same configuration payload can be written to an NFC tag on a student ID card. A student taps their phone to their student ID card and the configuration applies. Core NFC reads the NDEF payload containing the same deep link URL.

---

## 19. Community Configuration Repository

### 19.1 Repository structure

```
nook-integrations/integrations/academicnook/
  configurations/
    schools/
      us/
        va/
          lcps/
            config.json
            metadata.json
      uk/ ...
  food/
    lcps-linq.json
    lausd-nutrislice.json
  tools/
    validate-config.py
    generate-qr.py
  CONTRIBUTING_CONFIGS.md
  TRUST_MODEL.md
```

### 19.2 Three trust tiers

**Official**: institution IT contact verified by the Open Nook Foundation. Signed with institution domain key. Displayed with institution logo.

**Community**: independently verified by 3+ trusted community members using different accounts, at least one Trusted Contributor. "Community verified" badge with verification count.

**Contributed**: single community member submission, unverified. Explicit warning in setup UI inviting the student to sanity-check URLs before applying.

### 19.3 Trust progression

```
New contributor
  → 3 merged contributions verified as accurate
  → Verified Contributor (can co-verify other contributions)

Verified Contributor
  → 10 merged contributions, no accuracy disputes
  → Trusted Contributor (can independently advance a config to Community tier)
```

### 19.4 CI validation

Every configuration PR runs automated checks:

- Schema validation
- All URLs must be HTTPS
- OAuth redirect must share origin with base URL (prevents credential redirect attacks)
- No credential fields in configuration (client secrets belong in Keychain, never in config)
- Domain name plausibility check

Configs that fail CI cannot be merged regardless of human review.

### 19.5 Staleness model

Configurations not re-verified within 12 months are demoted one tier. Staleness is surfaced to students:

```
[ Community Verified ]
Last verified 11 months ago -- may be outdated
```

Students who have applied a configuration can tap "This looks correct" to extend the staleness clock without GitHub. Five in-app verifications within 30 days from active users resets the clock.

### 19.6 Web contribution form

Non-technical contributors (counsellors, students) can submit configurations via a web form at `contribute.academicnook.app`. The form accepts configuration fields, runs validation, and submits a PR via GitHub API. No git command line required.

---

## 20. Partner Program

### 20.1 Two independent axes

Every integration displays two independent badges:

**Partner tier** (who built it and commitment level):
- Founding Partner -- co-designed SDK, advance access, public credit
- Premier Partner -- advance SDK access, advisory input, Open Collective contribution
- Verified Partner -- certified adapter, DPA signed, dedicated issue channel
- Community -- PR to monorepo, same security checklist, no financial requirement
- Unofficial -- reverse-engineered, honest disclosure

**Quality tier** (what it does -- see §21):
- Essential / Core / Comprehensive / Complete

Neither axis masks the other. A Founding Partner with a minimal integration shows both facts. A community contributor with a comprehensive adapter shows both facts.

### 20.2 Partner SDK

Partners build against the published `AcademicNookSDK` Swift package at `github.com/nookly/academic-nook-sdk`. They maintain their adapter in their own repository. AcademicNook's build system references the certified release tag. the Open Nook Foundation never controls partner adapter repositories.

### 20.3 Data Processing Agreement

All Verified, Premier, and Founding Partners sign a DPA covering FERPA, COPPA, and applicable state student privacy laws. Community adapters and unofficial adapters do not have a DPA -- the student is told this in the setup UI.

### 20.4 Certification process

Certification requires:
1. Passing contract test report (`AdapterContractTestSuite`) -- zero undeclared endpoint access
2. Security checklist review (credentials in Keychain, OAuth via ASWebAuthenticationSession, no analytics)
3. Privacy declaration review -- what the adapter reads vs what it discards
4. DPA signed by both parties

### 20.5 Partner visibility

Website and README show partner logos by tier. Financial contributions are disclosed on Open Collective. Contribution amount does not affect partner tier -- partner tier reflects technical and legal commitment, not payment.

---

## 21. Integration Quality Tiers

### 21.1 Weighted capability score

Each platform has a documented capability set with weights:

| Weight | Capabilities |
|---|---|
| 3.0 (critical) | Assignment list, current grades, background sync, auth refresh |
| 2.0 (high) | Submission status, assignment details, grade breakdown, error explanation |
| 1.0 (standard) | Assignment submission, calendar events, announcements, push notifications |
| 0.5 (extended) | Course files, discussion read/write, graded rubric, peer review status |

### 21.2 Tier thresholds

| Tier | Weighted score | Critical capabilities |
|---|---|---|
| Essential | 25-40% | Not all critical capabilities present |
| Core | 50-70% | All critical capabilities present |
| Comprehensive | 75-90% | All critical + most high and standard |
| Complete | 90%+ | Full platform parity |

Missing any critical capability caps the tier at Essential regardless of score.

### 21.3 Institution-specific quality

The student's quality tier may differ from the adapter's theoretical quality if their institution's platform configuration restricts certain API endpoints. The capability probe at setup time detects institution-specific restrictions and displays a personalised quality tier.

```
Your Canvas integration at LCPS:

  OK  Assignments
  OK  Grades
  --  Discussions (not enabled at LCPS)

Quality at your institution: Core

These features are unavailable because LCPS has
not enabled third-party API access to discussions.
Contact your IT administrator if you need access.
```

---

## 22. Platform Capability Validation

### 22.1 Machine-readable capability documents

```yaml
# academic-integrations/integrations/academicnook/specs/canvas/capabilities.yml
platform: canvas
specVersion: "3.2"
capabilities:
  - id: assignment_list_read
    endpoint: "GET /api/v1/courses/:id/assignments"
    dataType: assignmentList
    weight: 3.0
    status: available   # available | deprecated | removed | changed
    lastVerified: "2026-05-15"
```

### 22.2 Weekly CI verification

GitHub Actions runs weekly against sandbox credentials, verifying each documented endpoint returns the expected response format. Endpoint changes trigger automatic GitHub issues in the integration repository.

### 22.3 Capability gap registry

```yaml
- id: badge_read
  academicNookStatus: gap_noProtocol   # platform supports it, no AcademicDataType case yet
  studentValue: medium
  implementationComplexity: low
  githubIssue: 418
```

Four statuses: `implemented`, `protocolExists_notImplemented`, `gap_noProtocol`, `evaluated_notBuilding`. Community votes via GitHub reactions on gap issues surface prioritisation signal.

### 22.4 Runtime health monitor

Per-capability success tracked at runtime. Three consecutive failures trigger degraded state visible in settings. Anonymous degradation reports -- no student data, only adapter ID + capability + error class + timestamp -- surface to adapter maintainer. Degradation data is aggregated across users; individual user failures are never reported.

---

## 23. NookInsights Academic Dimensions

Approximately 20 new dimensions added to the NookInsights feature vector when AcademicNook is connected. Total vector size grows from ~75 to ~95 dimensions.

**Direction of data flow [ENFORCED]:** AcademicNook is **write-only** to the shared App Group — it contributes the `nook.academic.*` context below and reads **no** health namespace (`nook.cycle.*`, `nook.symptoms.*`, `nook.mind.*`, or any other). The academic feature dimensions are consumed by NookInsights inside the health apps; nothing flows the other way into an app used with teacher and counsellor roles. Enforcement is structural: AcademicNook's Package.swift cannot import any health-namespace read module, validated by the CI dependency-graph check (ARCHITECTURE.md §4). All findings involving academic dimensions are additionally subject to the surfacing gate (ARCHITECTURE.md §6.0).

```swift
// Academic workload context
var assignmentsDueTomorrow: Float?
var assignmentsDueThisWeek: Float?
var daysSinceLastGradeUpdate: Float?
var missedAssignmentsCount: Float?
var upcomingTestsCount: Float?
var averageAssignmentCompletionRate: Float?  // rolling 30-day

// Academic performance
var currentGPANormalised: Float?             // 0-1, normalised to personal range
var gradeTrajectory: Float?                  // positive = improving
var gradeVolatility: Float?                  // variance across courses
var failingCoursesCount: Float?

// College planning stress
var collegeApplicationDeadlineDays: Float?
var collegeListCompleteness: Float?
var recommendationRequestsPending: Float?

// Service obligations
var volunteerHourDeficitThisMonth: Float?
var serviceDeadlineDays: Float?

// School nutrition
var ateSchoolLunchToday: Float?
var schoolLunchSodiumMg: Float?
var schoolLunchCalories: Float?
var schoolLunchQualityScore: Float?

// Context quality
var hasAcademicContext: Float               // 0/1
var academicContextQuality: Float          // quality tier × 0.25
```

### 23.1 Key cross-suite correlations

**Workload-sleep lag**: Assignment density predicts sleep degradation with a personalised lag. The model learns each student's individual lag.

**Grade-nutrition correlation**: School lunch quality correlating with grade trajectory in afternoon courses. The first consumer edtech finding connecting cafeteria nutrition to academic outcomes at the individual level.

**Stress-symptom cascade**: Academic deadlines predict symptom clusters (headaches, fatigue, GI symptoms) with personalised timing.

**Habit-grade correlation**: Which HabitNook habits correlate most strongly with academic performance for this specific student.

---

## 24. ClassKit

ClassKit lives in `Packages/AcademicNookCore/Sources/ClassKit/`.

### 24.1 Managed Apple ID requirement

ClassKit data syncs via iCloud using the student's Managed Apple ID to the teacher's Schoolwork dashboard. On personal Apple IDs, ClassKit queries discard data silently without throwing exceptions. A mandatory SwiftData fallback layer preserves all progress data regardless of Managed Apple ID status.

```swift
final class ClassKitSessionRecorder {
    func recordStudySession(assignment: LMSAssignment, duration: TimeInterval, completionRate: Double) async {
        // Always write to SwiftData -- Managed Apple ID not required
        await SwiftDataRepository.shared.recordSession(...)

        // ClassKit write -- only meaningful with Managed Apple ID
        // Fails silently on personal Apple ID -- expected behaviour
        guard let context = CLSDataStore.shared.mainAppContext?.descendant(matching: assignment.classKitIdentifier) else { return }
        let activity = context.createNewActivity()
        activity.start()
        activity.addProgressRange(fromStart: 0, toEnd: completionRate)
        activity.stop()
        CLSDataStore.shared.save { error in
            if let error { logger.error("ClassKit save failed: \(error) -- local record preserved") }
        }
    }
}
```

### 24.2 CLSContext hierarchy

AcademicNook's CLSContext tree mirrors the course/assignment structure. Contexts are created lazily when an assignment is first logged:

```
mainAppContext
  └── [course.id]   (CLSContext, .chapter)
        └── [assignment.id]   (CLSContext, .task)
```

---

## 25. API Surface

```
Packages/AcademicNookCore/Sources/
  ClassKit/                    CLSDataStore, CLSContext, CLSActivity
  Authentication/              ASWebAuthenticationSession, ASAuthorizationSingleSignOnProvider
  LMSAdapters/
    Official/                  Google Classroom, Canvas, Schoology, Clever, PowerSchool
    Bridge/                    StudentVue via nook-sis-bridge (OneRoster), LINQ (food service)
  GradeEngine/                 CourseGradeScheme, WhatIfGradeEngine
  SyllabusParser/              VNRecognizeTextRequest, PDFKit, Foundation Models
  RubricDiscovery/             Foundation Models rubric extraction
  Bridge/
    OneRoster/                 OneRoster v1.2 REST provider
    LocalBridge/               NWListener + NWBrowser (Bonjour)
  FoodService/                 FoodServiceAdapter, Nutrislice, LINQ adapters
  Proxy/                       Cloudflare Worker JWT verification
  Config/                      MDM com.apple.configuration.managed reader
  Spotlight/                   CSIndexExtensionRequestHandler

Apps/AcademicNook/
  Extensions/
    NotificationFilter/        ILMessageFilterExtension (SMS categorisation only)
    AssetIngestion/            BADownloaderExtension (district asset cache)
    Indexer/                   CSIndexExtensionRequestHandler
  Info.plist                   ClassKit entitlement, NFC entitlement

Primary frameworks:
  ClassKit, EventKit, AuthenticationServices, ASWebAuthenticationSession,
  URLSession, Foundation Models, CoreML, UserNotifications, BGProcessingTask,
  AppIntents, WidgetKit, MetricKit, CloudKit/CKShare, Network/NWListener+NWBrowser,
  CoreNFC, Vision/VNRecognizeTextRequest, PDFKit, CoreSpotlight,
  UserDefaults (MDM Managed App Configuration)

Entitlements required before App Store submission:
  com.apple.developer.ClassKit-environment (standard, apply via developer portal)
  com.apple.developer.nfc.readersession.formats (standard)
  FamilyControls (ManagedSettings -- requires Apple review)
```

---

## 26. Privacy and FERPA

### 26.1 FERPA position

AcademicNook data is the student's personal planning data stored in their own iCloud container. It is not an educational record held by an institution under FERPA. A student voluntarily sharing their own planning data with a counsellor or teacher is not subject to FERPA's institutional record requirements -- it is analogous to a student showing a counsellor their personal planner.

Institutional platforms (Naviance, Canvas) receive updates when the student chooses to file data there. AcademicNook does not hold institutional educational records.

### 26.2 Sharing model invariants

- Data access is student-initiated always
- No role can find students by school or district -- shares only from student-initiated connections
- Health data is never part of any share scope
- All shares are scoped and revocable
- CloudKit CKShare infrastructure, no the Open Nook Foundation servers involved

### 26.3 Minor student considerations

AcademicNook is used by students, many of whom are minors. Connection disclosures (including the bridge flow in §8.2) do not assume the student has read Apple's developer documentation. They are written for a 14-year-old: plain English, one sentence of substance, no legal hedging. The bridge architecture also means no minor ever types an SIS password into this app.

---

## 27. Revision History

| Version | Date | Changes |
|---|---|---|
| 1.1 | July 2026 | Decision-record patch (DECISIONS.md). §8.2 on-device StudentVue credential scraping withdrawn and replaced with the foundation-published, district/self-hosted OneRoster/LTI bridge server; app never holds SIS credentials and refuses direct-scrape mode; threat model moves to the bridge repo. §7.2/§7.4 updated to match, with kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly for background OAuth tokens per ARCHITECTURE.md §14.18. §9.3 school-lunch HealthKit writes corrected to AcademicNook's own entitlement and authorization as declared secondary dietary writer (ARCHITECTURE.md §5.2). §15.2 rewritten to incremental authorization (base scopes at sign-in, Drive on first document fetch, Gmail on explicit opt-in); drive.readonly and gmail.readonly documented as restricted scopes with the on-device exemption and §15.6 domain-trust as the fleet path. §23 write-only App Group rule for AcademicNook [ENFORCED]. Org name unified to Open Nook Foundation. |
| 1.0 | May 2026 | Initial design document. Three-role architecture, full LMS adapter protocol, partner program, quality tiers, capability validation, OneRoster bridge, Cloudflare Worker proxy, Google Workspace integration, rubric discovery, what-if grade engine, grading scheme taxonomy, syllabus parsing pipeline, food service adapters, supplemental tools, community configuration repository, QR/NFC distribution, ClassKit, MDM configuration |
