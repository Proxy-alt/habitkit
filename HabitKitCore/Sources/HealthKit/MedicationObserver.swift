import Foundation
import HealthKit

// MARK: - MedicationObserver

/// Observes HKMedicationDoseEvent to auto-complete medication habits (§8.26).
///
/// When a user logs a medication dose via the Health app or another app,
/// HabitKit can automatically complete a linked habit — removing the need
/// to double-log.
public actor MedicationObserver {

    // MARK: - Shared instance

    public static let shared = MedicationObserver()

    // MARK: - Private state

    private let store: HKHealthStore
    private var activeQueries: [UUID: HKObserverQuery] = [:]

    // MARK: - Init

    private init() {
        self.store = HKHealthStore()
    }

    // MARK: - Authorization

    /// Requests HealthKit read access for medication dose events.
    ///
    /// - Throws: `HealthKitError.notAvailable` or any HKError.
    public func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        guard let medicationType = HKObjectType.clinicalType(forIdentifier: .medicationRecord) else {
            throw HealthKitError.unsupportedType
        }
        try await store.requestAuthorization(toShare: [], read: [medicationType])
    }

    // MARK: - Observation

    /// Starts observing medication dose events for a specific medication name.
    ///
    /// - Parameters:
    ///   - habitID: The habit linked to this medication.
    ///   - medicationName: The medication to watch (used as a filter hint).
    ///   - onDoseLogged: Called when a dose is recorded for the matching medication.
    public func observeMedication(
        for habitID: UUID,
        medicationName: String,
        onDoseLogged: @Sendable @escaping (Date) async -> Void
    ) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let sampleType = HKObjectType.clinicalType(forIdentifier: .medicationRecord) else {
            return
        }

        // Stop any existing observer for this habit.
        stopObservation(for: habitID)

        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: nil
        )

        let query = HKObserverQuery(sampleType: sampleType, predicate: predicate) {
            [weak self] _, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }
            Task {
                await self?.handleMedicationUpdate(
                    medicationName: medicationName,
                    onDoseLogged: onDoseLogged
                )
            }
            completionHandler()
        }

        activeQueries[habitID] = query
        store.execute(query)
    }

    /// Stops observing medication events for a specific habit.
    ///
    /// - Parameter habitID: The habit whose observer should be removed.
    public func stopObservation(for habitID: UUID) {
        if let query = activeQueries[habitID] {
            store.stop(query)
            activeQueries.removeValue(forKey: habitID)
        }
    }

    // MARK: - Private helpers

    private func handleMedicationUpdate(
        medicationName: String,
        onDoseLogged: @Sendable @escaping (Date) async -> Void
    ) async {
        guard let sampleType = HKObjectType.clinicalType(forIdentifier: .medicationRecord) else {
            return
        }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )
        let samples: [HKSample] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: 10,
                sortDescriptors: [sort]
            ) { _, results, _ in
                continuation.resume(returning: results ?? [])
            }
            store.execute(query)
        }

        if let latest = samples.first {
            await onDoseLogged(latest.startDate)
        }
    }
}
