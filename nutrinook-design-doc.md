# NutriNook Design Document

**Version:** 1.1  
**Date:** July 2026  
**Status:** Pre-build. Core data model and ingestion pipeline designed. **Ruling (DECISIONS.md): the phase 2 build starts without the recipe engine** — recipe engine, meal planning, and grocery lists are designed and delivered within phase 2, not as entry criteria. Until the recipe engine ships, the 39-type completeness claim is qualified (see §1).

---

## Table of Contents

1. [North Star](#1-north-star)
2. [HealthKit Dietary Layer](#2-healthkit-dietary-layer)
3. [Food Database Architecture](#3-food-database-architecture)
4. [Food Logging Pipeline](#4-food-logging-pipeline)
5. [School Lunch Integration](#5-school-lunch-integration)
6. [Open Food Facts Bridge](#6-open-food-facts-bridge)
7. [Import Adapters](#7-import-adapters)
8. [NookInsights Nutrition Dimensions](#8-nookinsights-nutrition-dimensions)
9. [API Surface](#9-api-surface)
10. [Design Gaps](#10-design-gaps)
11. [Revision History](#11-revision-history)

---

## 1. North Star

> NutriNook writes to all 39 HealthKit dietary quantity types -- the complete micronutrient spectrum, **where data sources permit** -- treating food as data with the same rigour the suite applies to health data. It finds correlations between what a person eats and how they feel, sleep, and perform that no other nutrition app can find because no other app has access to the full health context.

**Completeness qualifier:** the primary v1 logging path (barcode → Open Food Facts) rates 0.50–0.75 on this document's own quality scale precisely because OFF is weak on micronutrients; USDA-quality micronutrient data for home-cooked food arrives with the recipe engine, which ships later in phase 2. Until then, marketing and in-app copy claim 39-type *capability*, not 39-type completeness of a typical user's log. Correlation findings are additionally gated on data quality by ARCHITECTURE.md §6.0 (`minQualityWeightedSupport = 0.60`).

Most nutrition apps treat food as a calorie counter with some macros. NutriNook treats food as a complete nutritional dataset -- all 39 HealthKit dietary types including micronutrients, minerals, and fatty acid subtypes that no consumer app currently tracks. The user does not need to understand micronutrients. NookInsights finds the patterns.

The specific finding that motivates the 39-type completeness: a user who logs food consistently discovers that their magnesium intake correlates with their sleep quality, or that their sodium intake on weekdays correlates with their afternoon fatigue in SymptomNook. These correlations exist in population research. NutriNook finds them at the individual level.

**What NutriNook explicitly is not:**

- Not a diet plan or calorie restriction tool -- no calorie goals, no food judgement language
- Not a weight management app -- BodyNook handles body composition; NutriNook handles intake
- Not a meal delivery or grocery service
- Not a replacement for dietitian consultation for people with clinical dietary needs

---

## 2. HealthKit Dietary Layer

### 2.1 All 39 dietary quantity types

NutriNook writes all 39 HealthKit dietary quantity types when data is available. Most food logging apps write 5-10. The full list matters because NookInsights needs the complete picture.

**Macronutrients and energy:**
`dietaryEnergyConsumed`, `dietaryCarbohydrates`, `dietaryFiber`, `dietarySugar`,
`dietaryFatTotal`, `dietaryFatSaturated`, `dietaryFatPolyunsaturated`, `dietaryFatMonounsaturated`,
`dietaryProtein`, `dietaryWater`

**Minerals:**
`dietaryCalcium`, `dietaryChloride`, `dietaryChromium`, `dietaryCopper`,
`dietaryIodine`, `dietaryIron`, `dietaryMagnesium`, `dietaryManganese`,
`dietaryMolybdenum`, `dietaryPhosphorus`, `dietaryPotassium`, `dietarySelenium`,
`dietarySodium`, `dietaryZinc`

**Vitamins:**
`dietaryVitaminA`, `dietaryThiamin`, `dietaryRiboflavin`, `dietaryNiacin`,
`dietaryPantothenicAcid`, `dietaryVitaminB6`, `dietaryBiotin`, `dietaryVitaminB12`,
`dietaryFolate`, `dietaryVitaminC`, `dietaryVitaminD`, `dietaryVitaminE`,
`dietaryVitaminK`

**Fatty acids and other:**
`dietaryCholesterol`, `dietaryCaffeine`

### 2.2 Write pattern

All dietary writes use a 15-minute meal window: a log within 15 minutes of the previous log's window extends the same meal event; otherwise a new meal event begins. Each nutrient type is written as a separate `HKQuantitySample` spanning the meal window, and the samples of one meal are wrapped in an `HKCorrelation` of type `.food` so consumers (and NutriNook itself) can reconstruct meals. One long-lived `HKHealthStore` is used suite-wide via `NookHealthStore` (ARCHITECTURE.md §14) — never a per-call `HKHealthStore()`.

```swift
func logMeal(_ items: [FoodItem], at date: Date = .now) async throws {
    // 15-minute meal window: attach to the open meal event or start a new one
    let meal = mealWindowStore.mealEvent(containing: date, window: .minutes(15))

    // Aggregate all nutrient quantities across items
    var nutrients: [HKQuantityTypeIdentifier: Double] = [:]
    for item in items {
        for (identifier, quantity) in item.nutrients {
            nutrients[identifier, default: 0] += quantity
        }
    }

    // One sample per nutrient type, spanning the meal window
    var samples: Set<HKSample> = []
    for (identifier, quantity) in nutrients {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier),
              let unit = unit(for: identifier) else { continue }
        samples.insert(HKQuantitySample(
            type: quantityType,
            quantity: HKQuantity(unit: unit, doubleValue: quantity),
            start: meal.start,
            end: meal.end(extendedTo: date),
            metadata: [
                HKMetadataKeyFoodType: items.map(\.name).joined(separator: ", ")
            ]
        ))
    }

    // Meal association: samples grouped under a .food correlation
    let correlation = HKCorrelation(
        type: HKCorrelationType(.food),
        start: meal.start,
        end: meal.end(extendedTo: date),
        objects: samples
    )
    try await NookHealthStore.shared.save(correlation)
}
```

---

## 3. Food Database Architecture

### 3.1 USDA Foundation Foods (bundled)

The primary nutritional data source is the USDA Foundation Foods database, bundled with the app. Foundation Foods contains ~3,300 foods with complete nutrient profiles across all 39 dietary types -- more complete coverage than any commercial database for the nutrients that matter for correlation analysis.

The bundled database is updated with each app release. Size: approximately 8-12MB JSON compressed. Indexed for fast lookup by food name and food category.

Foundation Foods is the source NutriNook uses for any food it can match -- it has better micronutrient data than Open Food Facts for the complete 39-type profile.

### 3.2 Open Food Facts (live adapter)

Open Food Facts provides barcode-based lookup for packaged foods. When a user scans a barcode, NutriNook queries the Open Food Facts API for the product. The returned data is typically strong on macros, sodium, and sugar, and weaker on micronutrients.

For micronutrients absent from the Open Food Facts record, NutriNook supplements with USDA Foundation Foods estimates for the closest matching food category.

```swift
struct OpenFoodFactsAdapter {
    static let baseURL = URL(string: "https://world.openfoodfacts.org/api/v2/product/")!

    func fetchProduct(barcode: String) async throws -> FoodProduct? {
        let url = baseURL.appending(path: barcode)
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OFFProductResponse.self, from: data)
        guard response.status == 1 else { return nil }
        return FoodProduct(from: response.product)
    }
}
```

### 3.3 Data quality scoring

Every logged food item carries a data quality score that NookInsights uses to weight nutrient contributions in correlation analysis:

| Source | Quality score | Completeness |
|---|---|---|
| USDA Foundation Foods | 0.95 | All 39 types typically available |
| Open Food Facts (complete record) | 0.75 | Strong on macros, sodium, sugar |
| Open Food Facts (partial) | 0.50 | Calories and macros only |
| Manual entry by user | 0.40 | User-provided values |
| USDA category estimate | 0.35 | Category-level estimate only |
| School lunch USDA estimate | 0.35 | NSLP compliance range estimate |

NookInsights weights nutrient contribution to correlation findings by this score. A magnesium-sleep correlation found primarily from 0.35-quality data is noted as lower confidence than one found from 0.95-quality data.

---

## 4. Food Logging Pipeline

### 4.1 Barcode scan (primary logging method)

`DataScannerViewController` handles barcode scanning for packaged foods. The scan-to-log flow:

1. User taps the camera icon
2. DataScannerViewController opens in barcode mode
3. Scan detected, Open Food Facts query fires immediately
4. While query is in flight, the barcode value is shown with a loading indicator
5. Product found: show name, serving size selector, portion estimator
6. User adjusts portion, taps Log
7. Nutrients written to HealthKit

If the barcode is not in Open Food Facts, the user is prompted to search by name or add the product manually. Manual additions are optionally submitted to Open Food Facts (see §6).

### 4.2 Text search

For unpackaged foods (produce, restaurant meals, homemade dishes), text search queries the bundled USDA Foundation Foods database first, then Open Food Facts. Debounced at 300ms. Results ranked by name similarity and food category relevance to the user's recent logging history.

### 4.3 Camera-based food identification

The camera can also attempt food identification for plated meals using Vision framework's image classification. This is a supplemental feature -- it suggests likely foods from a photographed plate, which the user confirms or corrects. It is not a primary logging path because accuracy is insufficient for reliable micronutrient data at the individual meal level.

The photo itself is stored as a `HKQuantitySample` metadata attachment for the meal, visible in the Health app's timeline.

### 4.4 Portion estimation

Portion estimation is the most friction-heavy part of food logging. NutriNook reduces this with:

- Common portion presets (1 cup, 1 serving, 100g, 1 oz) prominently displayed
- Remembered user portion preferences per food (the user always logs 2 eggs -- this becomes the default)
- Visual portion reference: a comparison image showing common household measures

---

## 5. School Lunch Integration

AcademicNook handles school lunch detection and menu display. NutriNook receives the meal log from AcademicNook when the student confirms which lunch items they ate.

The integration is one-directional: AcademicNook writes confirmed school-lunch items to HealthKit **under its own HealthKit entitlement and its own user-granted dietary-write authorization** — AcademicNook is the declared secondary writer for dietary types, scoped to confirmed school-lunch items only (ARCHITECTURE.md §5.2). Entitlements and authorization never cross bundle boundaries through a shared framework; what NookCore shares is code (sample construction, meal metadata, the 15-minute window logic), not permission. Samples carry AcademicNook as `HKSource`, which is how NutriNook and NookInsights attribute provenance. NutriNook does not query AcademicNook directly.

```swift
// NookCore -- school lunch write (called by AcademicNook)
func confirmSchoolLunchItems(_ items: [SchoolMenuItem]) async throws {
    var samples: [HKQuantitySample] = []
    for item in items {
        guard let nutrition = item.nutritionData else { continue }
        // Write available nutrient types
        if let cal = nutrition.calories {
            samples.append(makeSample(.dietaryEnergyConsumed, value: cal, unit: .kilocalorie()))
        }
        if let sodium = nutrition.sodiumMg {
            samples.append(makeSample(.dietarySodium, value: sodium, unit: .gramUnit(with: .milli)))
        }
        // ... all available types
    }
    if !samples.isEmpty {
        // Runs inside AcademicNook: its own entitlement, its own authorization,
        // AcademicNook as HKSource. Shared code from NookCore; permission is not shared.
        try await NookHealthStore.shared.save(samples)
    }
}
```

The school lunch sodium-to-afternoon-performance correlation (academicnook-design-doc.md §23) requires this integration, and is subject to the surfacing gate in ARCHITECTURE.md §6.0. NutriNook cannot find the correlation without the school lunch data; AcademicNook supplies it as the declared secondary dietary writer.

---

## 6. Open Food Facts Bridge

NutriNook contributes to Open Food Facts as a reverse bridge -- when a user adds a new food manually or corrects an existing product, NutriNook optionally submits the contribution to Open Food Facts.

This is the open-source equivalent of a nutritional data crowdsourcing model. The user's contribution improves the database for everyone.

```swift
struct OpenFoodFactsContributor {

    func suggestContribution(
        for product: FoodProduct,
        userAddedNutrients: [String: Double]
    ) -> ContributionSuggestion {
        // Show what would be submitted
        // User explicitly approves before any submission
        ContributionSuggestion(
            productName: product.name,
            barcode: product.barcode,
            addedNutrients: userAddedNutrients,
            requiresUserApproval: true
        )
    }

    func submit(_ suggestion: ContributionSuggestion) async throws {
        guard suggestion.userApproved else { return }
        // OFF API submission
        // No personal identifying information in the submission
        // Contribution is anonymous
    }
}
```

Contributions are anonymous. No user account, no username, no identifying information in the submission. The nutritional data is contributed as community data with no link to the user.

---

## 7. Import Adapters

### 7.1 MyFitnessPal CSV export

MyFitnessPal allows users to export their food diary as CSV. NutriNook ingests this for historical backfill:

```swift
struct MyFitnessPalImporter: NookImporter {
    func canImport(_ data: Data, filename: String) -> Bool {
        filename.lowercased().contains("food_diary") && filename.hasSuffix(".csv")
    }

    func importHistory(from data: Data) async throws -> ImportResult {
        // Parse MFP CSV format
        // Map MFP nutrient fields to HealthKit types
        // Write historical HKQuantitySample records
        // Return count of successfully imported meals
    }
}
```

### 7.2 Cronometer CSV export

Cronometer exports include more complete micronutrient data than MyFitnessPal. The import adapter maps Cronometer's nutrient field names to HealthKit types. Cronometer covers most of the 39 types, making it the highest-quality import source for historical data.

### 7.3 Import quality

Historical import data from third-party apps carries a quality score of 0.50-0.70 depending on the source's nutrient completeness. The quality score is attached to imported samples as metadata and used by NookInsights to weight historical nutrient data.

---

## 8. NookInsights Nutrition Dimensions

```swift
// Nutrition context dimensions in the feature vector
// Populated from HealthKit dietary samples (all sources: NutriNook, other apps, school lunch)

// Energy and macros
var caloriesLastMeal: Float?
var proteinGrams24h: Float?
var carbGrams24h: Float?
var fatGrams24h: Float?
var fiberGrams24h: Float?
var waterMl24h: Float?

// High-correlation micronutrients
// These are the nutrients with strongest documented health correlations
var sodiumMg24h: Float?             // blood pressure, headaches, fluid retention
var magnesiumMg24h: Float?          // sleep quality, muscle function
var ironMg24h: Float?               // energy, cognitive function
var vitaminD_IU_24h: Float?         // mood, immunity, sleep
var vitaminB12_mcg_24h: Float?      // energy, neurological function
var caffeineIntakeMg: Float?        // sleep latency, heart rate

// Meal timing
var lastMealHoursAgo: Float?        // circadian rhythm proxy
var mealCount24h: Float?

// Data quality
var nutritionDataQuality: Float?    // weighted average quality of data sources
var nutritionDataComplete: Float?   // 0/1 -- all 39 types have data for today
```

### 8.1 Key correlations NutriNook enables

**Sodium-sleep**: High sodium intake correlating with sleep fragmentation (SleepNook). Documented at population level, findable at individual level with daily tracking.

**Magnesium-sleep**: Low magnesium correlating with sleep quality decline. One of the best-documented dietary-sleep relationships.

**Caffeine timing**: Caffeine intake within 6 hours of sleep correlating with sleep latency and reduced deep sleep.

**Iron-energy**: Low iron correlating with fatigue ratings in SymptomNook. Particularly relevant for menstruating users (CycleNook cross-reference).

**Meal timing-sleep**: Large meals within 2 hours of sleep correlating with sleep quality reduction. Captured via `lastMealHoursAgo`.

---

## 9. API Surface

```
Packages/NutriNookCore/Sources/
  HealthKit/               HKQuantitySample writes, all 39 types
  Database/
    USDA/                  Bundled Foundation Foods SQLite database
    OpenFoodFacts/         Live API adapter + contribution submitter
  Logging/
    BarcodeScanner/        DataScannerViewController integration
    TextSearch/            USDA + OFF search pipeline
    CameraIdentification/  Vision food classification (supplemental)
    PortionEstimation/     Preset portions, user preferences
  SchoolLunch/             Shared framework write endpoint for AcademicNook
  Import/
    MyFitnessPalImporter/  CSV import adapter
    CronometerImporter/    CSV import adapter

Primary frameworks:
  HealthKit (all 39 HKQuantityTypeIdentifier dietary types)
  DataScannerViewController (barcode scanning)
  Vision (food image classification)
  URLSession (Open Food Facts API)
  CoreData/SQLite (USDA Foundation Foods bundled database)
  AppIntents, WidgetKit, UserNotifications, BGProcessingTask
```

---

## 10. Design Gaps

**Recipe engine** -- How NutriNook handles multi-ingredient recipes: ingredient entry, yield calculation, per-serving nutrition computation, recipe storage and recall. Not designed.

**Meal planning** -- Whether NutriNook has a meal planning feature (plan meals for the week, generate nutritional projections) and how it integrates with grocery list generation. Not designed.

**Grocery list** -- Whether NutriNook generates a grocery list from a meal plan or recipe set, and how it integrates with iOS Reminders or a third-party shopping app. Not designed.

**Restaurant meals** -- How NutriNook handles restaurant meals where barcode scanning is not applicable. Options: restaurant chain database, generic meal estimation by cuisine type, manual entry. Not designed.

**Dietary restrictions** -- Whether NutriNook tracks dietary restrictions (allergies, religious restrictions, medical dietary requirements) and uses them to flag or filter logged foods. Not designed.

**Nutritional goals** -- Whether NutriNook has any concept of nutritional targets (RDA-based, clinician-set, user-set) and how it presents progress against them without becoming prescriptive or anxiety-inducing. Not designed.

---

## 11. Revision History

| Version | Date | Changes |
|---|---|---|
| 1.1 | July 2026 | Decision-record patch (DECISIONS.md). Phase 2 rules: build starts without the recipe engine; 39-type completeness claim qualified until recipes ship, with quality gating deferred to ARCHITECTURE.md §6.0. §2.2 write pattern fixed to match its own prose — meal samples span the 15-minute window and are grouped under an HKCorrelation(.food); single shared NookHealthStore replaces per-call HKHealthStore(). §5 school-lunch writes corrected to AcademicNook's own entitlement/authorization as declared secondary dietary writer with HKSource provenance; stale "§23 of the main design doc" reference repointed to academicnook-design-doc.md §23. |
| 1.0 | May 2026 | Initial design document. All 39 HealthKit dietary types, USDA Foundation Foods bundled database, Open Food Facts live adapter and contribution bridge, data quality scoring model, food logging pipeline (barcode, text search, camera), school lunch integration via shared NookCore framework, MyFitnessPal and Cronometer CSV import adapters, NookInsights nutrition dimensions, design gaps |
