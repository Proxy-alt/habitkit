import Foundation
import HealthKit

// MARK: - HabitHealthType

/// The HealthKit data category that a habit maps to.
public enum HabitHealthType: Sendable {
    /// Mindfulness / meditation minutes.
    case meditation
    /// General workout (active energy + exercise time).
    case workout
    /// Dietary water intake.
    case waterIntake
    /// Sleep analysis.
    case sleep
    /// Stand hours (Apple Watch standing).
    case standing
    /// Step count goal.
    case stepGoal
}

// MARK: - HealthKitManager

/// Manages all interactions with HealthKit on behalf of HabitKit.
///
/// Obtain the shared instance via `HealthKitManager.shared`.
public actor HealthKitManager {

    // MARK: - Singleton

    public static let shared = HealthKitManager()

    // MARK: - Private state

    private let store = HKHealthStore()

    /// Active query handles keyed by `HabitHealthType` so we can avoid
    /// installing duplicate background observers.
    private var activeQueries: [HabitHealthTypeCodable: HKObserverQuery] = [:]

    private init() {}

    // MARK: - Authorization

    /// Requests HealthKit authorisation for the sample types used by `habitType`.
    ///
    /// - Parameter habitType: The kind of health data this habit writes.
    /// - Throws: `HealthKitError.notAvailable` when HealthKit is not supported
    ///   on the current device, or any `HKError` from the system.
    public func requestAuthorization(for habitType: HabitHealthType) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        let writeTypes = sampleTypes(for: habitType)
        try await store.requestAuthorization(toShare: writeTypes, read: [])
    }

    // MARK: - Writing completions

    /// Writes a `HabitCompletion` to HealthKit as the appropriate sample type.
    ///
    /// - Parameters:
    ///   - completion: The completion record to write.
    ///   - habitType: The HealthKit category this completion maps to.
    /// - Throws: `HealthKitError.notAvailable`, `HealthKitError.noSampleData`,
    ///   or any underlying `HKError`.
    public func writeCompletion(_ completion: HabitCompletion, habitType: HabitHealthType) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let samples = try buildSamples(from: completion, for: habitType)
        guard !samples.isEmpty else {
            throw HealthKitError.noSampleData
        }
        try await store.save(samples)
    }

    // MARK: - Auto-completion observation

    /// Starts a background HealthKit observer that calls `onMet` whenever the
    /// cumulative value for `habitType` on the current day crosses `threshold`.
    ///
    /// - Parameters:
    ///   - habitType: The kind of health data to observe.
    ///   - threshold: The value that must be reached to trigger `onMet`.
    ///   - onMet: Async closure called (on an unspecified executor) when the
    ///     threshold is first met on any given day.
    public func observeAutoCompletion(
        for habitType: HabitHealthType,
        threshold: Double,
        onMet: @Sendable @escaping () async -> Void
    ) async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let key = HabitHealthTypeCodable(habitType)

        // Avoid duplicate observers.
        if let existing = activeQueries[key] {
            store.stop(existing)
        }

        guard let primaryType = primaryQuantityType(for: habitType) else { return }

        let query = HKObserverQuery(sampleType: primaryType, predicate: nil) {
            [weak self] _, completionHandler, error in
            guard error == nil, let self else {
                completionHandler()
                return
            }

            Task {
                await self.handleObserverFired(
                    habitType: habitType,
                    threshold: threshold,
                    onMet: onMet
                )
                completionHandler()
            }
        }

        activeQueries[key] = query
        store.execute(query)

        // Enable background delivery so the observer fires even when the app is suspended.
        if let delivery = backgroundDeliveryFrequency(for: habitType) {
            try? await store.enableBackgroundDelivery(for: primaryType, frequency: delivery)
        }
    }

    // MARK: - Private helpers

    private func handleObserverFired(
        habitType: HabitHealthType,
        threshold: Double,
        onMet: @Sendable @escaping () async -> Void
    ) async {
        guard let sum = try? await fetchTodaySum(for: habitType), sum >= threshold else { return }
        await onMet()
    }

    private func fetchTodaySum(for habitType: HabitHealthType) async throws -> Double {
        guard let quantityType = primaryQuantityType(for: habitType) else {
            throw HealthKitError.unsupportedType
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        return try await withCheckedThrowingContinuation { continuation in
            let statsQuery = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let unit = self.preferredUnit(for: habitType)
                let sum = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: sum)
            }
            store.execute(statsQuery)
        }
    }

    // MARK: - Type resolution

    private func sampleTypes(for habitType: HabitHealthType) -> Set<HKSampleType> {
        switch habitType {
        case .meditation:
            return [HKObjectType.categoryType(forIdentifier: .mindfulSession)!]
        case .workout:
            return [HKObjectType.workoutType()]
        case .waterIntake:
            return [HKObjectType.quantityType(forIdentifier: .dietaryWater)!]
        case .sleep:
            return [HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!]
        case .standing:
            return [HKObjectType.quantityType(forIdentifier: .appleStandTime)!]
        case .stepGoal:
            return [HKObjectType.quantityType(forIdentifier: .stepCount)!]
        }
    }

    private func primaryQuantityType(for habitType: HabitHealthType) -> HKQuantityType? {
        switch habitType {
        case .waterIntake:
            return HKObjectType.quantityType(forIdentifier: .dietaryWater)
        case .standing:
            return HKObjectType.quantityType(forIdentifier: .appleStandTime)
        case .stepGoal:
            return HKObjectType.quantityType(forIdentifier: .stepCount)
        default:
            return nil
        }
    }

    private func preferredUnit(for habitType: HabitHealthType) -> HKUnit {
        switch habitType {
        case .waterIntake:
            return HKUnit.literUnit(with: .milli)
        case .standing:
            return HKUnit.minute()
        case .stepGoal:
            return HKUnit.count()
        default:
            return HKUnit.count()
        }
    }

    private func backgroundDeliveryFrequency(for habitType: HabitHealthType) -> HKUpdateFrequency? {
        switch habitType {
        case .stepGoal, .standing:
            return .immediate
        case .waterIntake:
            return .hourly
        default:
            return nil
        }
    }

    // MARK: - Sample building

    private func buildSamples(
        from completion: HabitCompletion,
        for habitType: HabitHealthType
    ) throws -> [HKSample] {
        let start = completion.completedAt
        var end = completion.completedAt

        switch habitType {

        case .meditation:
            if let duration = completion.durationSeconds {
                end = start.addingTimeInterval(TimeInterval(duration))
            }
            guard let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { break }
            let sample = HKCategorySample(
                type: type,
                value: HKCategoryValue.notApplicable.rawValue,
                start: start,
                end: max(start, end)
            )
            return [sample]

        case .workout:
            let duration = completion.durationSeconds.map { TimeInterval($0) } ?? 60
            end = start.addingTimeInterval(duration)
            let workout = HKWorkout(
                activityType: .other,
                start: start,
                end: max(start, end)
            )
            return [workout]

        case .waterIntake:
            guard let type = HKObjectType.quantityType(forIdentifier: .dietaryWater) else { break }
            let ml = completion.value ?? 250
            let quantity = HKQuantity(unit: HKUnit.literUnit(with: .milli), doubleValue: ml)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: start, end: start)
            return [sample]

        case .sleep:
            let duration = completion.durationSeconds.map { TimeInterval($0) } ?? 3600 * 8
            end = start.addingTimeInterval(duration)
            guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { break }
            let sample = HKCategorySample(
                type: type,
                value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                start: start,
                end: max(start, end)
            )
            return [sample]

        case .standing:
            guard let type = HKObjectType.quantityType(forIdentifier: .appleStandTime) else { break }
            let minutes = completion.value ?? 1
            let quantity = HKQuantity(unit: HKUnit.minute(), doubleValue: minutes)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: start, end: start)
            return [sample]

        case .stepGoal:
            guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else { break }
            let steps = completion.value ?? 10_000
            let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: steps)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: start, end: start)
            return [sample]
        }

        throw HealthKitError.unsupportedType
    }
}

// MARK: - Supporting types

/// Internal Hashable wrapper for `HabitHealthType` (needed for dictionary keys).
private struct HabitHealthTypeCodable: Hashable {
    let rawValue: Int

    init(_ type: HabitHealthType) {
        switch type {
        case .meditation: rawValue = 0
        case .workout: rawValue = 1
        case .waterIntake: rawValue = 2
        case .sleep: rawValue = 3
        case .standing: rawValue = 4
        case .stepGoal: rawValue = 5
        }
    }
}

/// Errors thrown by `HealthKitManager`.
public enum HealthKitError: Error, Sendable {
    /// HealthKit is not available on this device (e.g. iPod touch, macOS without entitlement).
    case notAvailable
    /// The habit type cannot be mapped to a HealthKit sample.
    case unsupportedType
    /// The completion record does not contain enough data to build a sample.
    case noSampleData
}
