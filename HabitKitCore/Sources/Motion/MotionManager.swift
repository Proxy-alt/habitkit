import CoreMotion
import Foundation

// MARK: - MotionManager

/// Wraps `CMMotionActivityManager` and `CMPedometer` to detect physical activity
/// and step progress for habit auto-completion (§8.7).
///
/// Motion data is used read-only: HabitKit never writes motion data. The actor
/// manages CMMotionActivity observation and live step counts.
public actor MotionManager {

    // MARK: - Shared instance

    public static let shared = MotionManager()

    // MARK: - Private state

    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()

    /// Cached activity classification from the most recent update.
    private var latestActivity: ActivityClassification = .unknown

    // MARK: - Init

    private init() {}

    // MARK: - Authorization

    /// Returns whether motion activity authorization has been granted.
    public var isAuthorized: Bool {
        CMMotionActivityManager.authorizationStatus() == .authorized
    }

    // MARK: - Activity observation

    /// Starts observing motion activity updates and calls `handler` on each change.
    ///
    /// - Parameter handler: Closure called with the latest `ActivityClassification`
    ///   whenever CMMotionActivityManager fires an update.
    public func startActivityObservation(
        handler: @Sendable @escaping (ActivityClassification) -> Void
    ) {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        activityManager.startActivityUpdates(to: .main) { [weak activityManager] activity in
            guard let activity else { return }
            let classification = ActivityClassification(from: activity)
            handler(classification)
        }
    }

    /// Stops all activity updates.
    public func stopActivityObservation() {
        activityManager.stopActivityUpdates()
    }

    // MARK: - Step counting

    /// Returns the cumulative step count since the start of today.
    ///
    /// - Returns: Step count as an integer, or `0` if unavailable.
    public func todayStepCount() async -> Int {
        guard CMPedometer.isStepCountingAvailable() else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        return await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(from: start, to: Date()) { data, error in
                guard error == nil, let steps = data?.numberOfSteps else {
                    continuation.resume(returning: 0)
                    return
                }
                continuation.resume(returning: steps.intValue)
            }
        }
    }

    /// Starts live pedometer updates, calling `handler` with cumulative steps.
    ///
    /// - Parameter handler: Called with updated step count on each pedometer event.
    public func startLiveStepUpdates(handler: @Sendable @escaping (Int) -> Void) {
        guard CMPedometer.isStepCountingAvailable() else { return }
        let start = Calendar.current.startOfDay(for: Date())
        pedometer.startUpdates(from: start) { data, error in
            guard error == nil, let data else { return }
            handler(data.numberOfSteps.intValue)
        }
    }

    /// Stops live pedometer updates.
    public func stopLiveStepUpdates() {
        pedometer.stopUpdates()
    }
}

// MARK: - ActivityClassification

/// Simplified activity state derived from `CMMotionActivity`.
public enum ActivityClassification: Sendable {
    case stationary
    case walking
    case running
    case cycling
    case automotive
    case unknown

    /// Creates a classification from a raw `CMMotionActivity`.
    init(from activity: CMMotionActivity) {
        if activity.running { self = .running }
        else if activity.cycling { self = .cycling }
        else if activity.walking { self = .walking }
        else if activity.stationary { self = .stationary }
        else if activity.automotive { self = .automotive }
        else { self = .unknown }
    }
}
