import HealthKit

/// Abstraction over `HKHealthStore` for testability.
///
/// Replace direct `HKHealthStore` usage in `HealthKitManager` with calls
/// through this protocol so tests can use a fake implementation.
public protocol HealthStore: Sendable {
    /// Requests authorization to read and share the given HealthKit types.
    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws
    /// Saves a single HealthKit sample.
    func save(_ sample: HKSample) async throws
    /// Executes a HealthKit query.
    func execute(_ query: HKQuery)
    /// Stops a previously executed HealthKit query.
    func stop(_ query: HKQuery)
    /// Enables background delivery for a HealthKit object type at the given frequency.
    func enableBackgroundDelivery(
        for type: HKObjectType,
        frequency: HKUpdateFrequency
    ) async throws
}

// MARK: - Live conformance

/// Extends `HKHealthStore` to conform to ``HealthStore``.
///
/// `requestAuthorization(toShare:read:)`, `execute(_:)`, and `stop(_:)` are
/// already provided by HealthKit; only the async wrappers for `save` and
/// `enableBackgroundDelivery` need to be added.
extension HKHealthStore: @retroactive HealthStore {
    /// Saves a single HealthKit sample using a checked throwing continuation.
    public func save(_ sample: HKSample) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.save(sample) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Enables background delivery using a checked throwing continuation.
    public func enableBackgroundDelivery(
        for type: HKObjectType,
        frequency: HKUpdateFrequency
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.enableBackgroundDelivery(for: type, frequency: frequency) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
