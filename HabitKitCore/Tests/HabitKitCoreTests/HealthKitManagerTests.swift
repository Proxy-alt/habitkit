import Foundation
import HealthKit
import Testing
@testable import HabitKitCore

// MARK: - MockHealthStore

final class MockHealthStore: HealthStore, @unchecked Sendable {
    var authorizationRequests: [(Set<HKSampleType>, Set<HKObjectType>)] = []
    var executedQueries: [HKQuery] = []
    var stoppedQueries: [HKQuery] = []
    var backgroundDeliveryRequests: [(HKObjectType, HKUpdateFrequency)] = []
    var savedSamples: [HKSample] = []
    var savedWorkouts: [(HKWorkoutActivityType, Date, Date)] = []

    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws {
        authorizationRequests.append((typesToShare, typesToRead))
    }

    func save(_ sample: HKSample) async throws {
        savedSamples.append(sample)
    }

    func execute(_ query: HKQuery) {
        executedQueries.append(query)
    }

    func stop(_ query: HKQuery) {
        stoppedQueries.append(query)
    }

    func enableBackgroundDelivery(
        for type: HKObjectType,
        frequency: HKUpdateFrequency
    ) async throws {
        backgroundDeliveryRequests.append((type, frequency))
    }

    func saveWorkout(
        activityType: HKWorkoutActivityType,
        start: Date,
        end: Date
    ) async throws {
        savedWorkouts.append((activityType, start, end))
    }
}

// MARK: - Tests

@Suite("HealthKitManager")
struct HealthKitManagerTests {

    // MARK: - requestAuthorization

    /// requestAuthorization is called without model objects, so no actor-boundary
    /// Sendable issue. Covers sampleTypes(for:) for every HabitHealthType.
    @Test("requestAuthorization succeeds via mock for all habit types")
    func requestAuthorizationAllTypes() async throws {
        let types: [HabitHealthType] = [.meditation, .workout, .waterIntake, .sleep, .standing, .stepGoal]
        for type in types {
            let mock = MockHealthStore()
            let manager = HealthKitManager(store: mock)
            do {
                try await manager.requestAuthorization(for: type)
                // If HealthKit is available, mock was called
                #expect(mock.authorizationRequests.count == 1)
            } catch HealthKitError.notAvailable {
                // HealthKit not available on this runner — guard path covered
            }
        }
    }

    // MARK: - observeAutoCompletion

    @Test("observeAutoCompletion for quantity types executes a query")
    func observeAutoCompletionQuantityTypes() async {
        let quantityTypes: [HabitHealthType] = [.waterIntake, .standing, .stepGoal]
        for type in quantityTypes {
            let mock = MockHealthStore()
            let manager = HealthKitManager(store: mock)
            guard HKHealthStore.isHealthDataAvailable() else { continue }
            await manager.observeAutoCompletion(for: type, threshold: 100) {}
            #expect(mock.executedQueries.count == 1)
        }
    }

    @Test("observeAutoCompletion for non-quantity types returns early")
    func observeAutoCompletionNonQuantityTypes() async {
        let nonQuantityTypes: [HabitHealthType] = [.meditation, .workout, .sleep]
        for type in nonQuantityTypes {
            let mock = MockHealthStore()
            let manager = HealthKitManager(store: mock)
            await manager.observeAutoCompletion(for: type, threshold: 1) {}
            // No query should be executed since primaryQuantityType returns nil
            #expect(mock.executedQueries.isEmpty)
        }
    }

    @Test("observeAutoCompletion does not install duplicate observers")
    func observeAutoCompletionNoDuplicates() async {
        let mock = MockHealthStore()
        let manager = HealthKitManager(store: mock)
        guard HKHealthStore.isHealthDataAvailable() else { return }

        await manager.observeAutoCompletion(for: .stepGoal, threshold: 10_000) {}
        await manager.observeAutoCompletion(for: .stepGoal, threshold: 10_000) {}

        // Second call should stop the first query and execute a new one
        #expect(mock.stoppedQueries.count == 1)
        #expect(mock.executedQueries.count == 2)
    }

    // MARK: - HealthKitError

    @Test("HealthKitError descriptions are non-empty")
    func healthKitErrorDescriptions() {
        #expect(!HealthKitError.notAvailable.localizedDescription.isEmpty)
        #expect(!HealthKitError.unsupportedType.localizedDescription.isEmpty)
        #expect(!HealthKitError.noSampleData.localizedDescription.isEmpty)
    }

    // MARK: - HabitHealthType coverage (via requestAuthorization path)

    @Test("requestAuthorization for meditation requests mindful session type")
    func authMeditation() async throws {
        let mock = MockHealthStore()
        let manager = HealthKitManager(store: mock)
        do {
            try await manager.requestAuthorization(for: .meditation)
            let types = mock.authorizationRequests.first?.0 ?? []
            let hasMindful = types.contains {
                $0.identifier == HKCategoryTypeIdentifier.mindfulSession.rawValue
            }
            #expect(hasMindful)
        } catch HealthKitError.notAvailable {}
    }

    @Test("requestAuthorization for workout requests workout type")
    func authWorkout() async throws {
        let mock = MockHealthStore()
        let manager = HealthKitManager(store: mock)
        do {
            try await manager.requestAuthorization(for: .workout)
            let types = mock.authorizationRequests.first?.0 ?? []
            let hasWorkout = types.contains { $0 is HKWorkoutType }
            #expect(hasWorkout)
        } catch HealthKitError.notAvailable {}
    }

    @Test("requestAuthorization for waterIntake requests dietary water type")
    func authWater() async throws {
        let mock = MockHealthStore()
        let manager = HealthKitManager(store: mock)
        do {
            try await manager.requestAuthorization(for: .waterIntake)
            let types = mock.authorizationRequests.first?.0 ?? []
            let hasWater = types.contains {
                $0.identifier == HKQuantityTypeIdentifier.dietaryWater.rawValue
            }
            #expect(hasWater)
        } catch HealthKitError.notAvailable {}
    }

    @Test("requestAuthorization for stepGoal requests step count type")
    func authStepGoal() async throws {
        let mock = MockHealthStore()
        let manager = HealthKitManager(store: mock)
        do {
            try await manager.requestAuthorization(for: .stepGoal)
            let types = mock.authorizationRequests.first?.0 ?? []
            let hasSteps = types.contains {
                $0.identifier == HKQuantityTypeIdentifier.stepCount.rawValue
            }
            #expect(hasSteps)
        } catch HealthKitError.notAvailable {}
    }
}
