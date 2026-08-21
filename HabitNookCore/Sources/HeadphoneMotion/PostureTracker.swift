import CoreMotion
import Foundation

// MARK: - PostureTracker

/// Tracks user posture during seated work habits using AirPods Pro
/// headphone motion sensors (§8.39).
///
/// `CMHeadphoneMotionManager` provides pitch/roll/yaw from AirPods Pro.
/// When the user's head pitch consistently deviates from neutral during a
/// "desk posture" habit session, the tracker logs a posture warning.
public actor PostureTracker {

    // MARK: - Shared instance

    public static let shared = PostureTracker()

    // MARK: - Private state

    private let motionManager = CMHeadphoneMotionManager()
    private var badPostureCount = 0
    private var totalSamples = 0

    /// Pitch deviation in radians considered "bad posture" (head down > 30°).
    private static let badPostureThresholdRadians: Double = 0.52

    /// Fraction of samples that must be bad posture to trigger a warning.
    private static let badPostureFractionThreshold: Double = 0.4

    // MARK: - Init

    private init() {}

    // MARK: - Authorization

    /// Returns whether headphone motion is available on this device.
    public var isAvailable: Bool {
        motionManager.isDeviceMotionAvailable
    }

    // MARK: - Session management

    /// Starts a posture-tracking session.
    ///
    /// - Parameter onWarning: Called when the posture warning threshold is crossed.
    public func startSession(onWarning: @Sendable @escaping () -> Void) {
        guard motionManager.isDeviceMotionAvailable else { return }
        badPostureCount = 0
        totalSamples = 0

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard error == nil, let motion, let self else { return }
            let pitch = motion.attitude.pitch
            Task {
                await self.handleMotionUpdate(pitch: pitch, onWarning: onWarning)
            }
        }
    }

    /// Stops the posture-tracking session.
    public func stopSession() {
        motionManager.stopDeviceMotionUpdates()
    }

    /// The fraction of samples that showed poor posture (0.0–1.0).
    public var badPostureFraction: Double {
        guard totalSamples > 0 else { return 0 }
        return Double(badPostureCount) / Double(totalSamples)
    }

    // MARK: - Private

    private func handleMotionUpdate(
        pitch: Double,
        onWarning: @Sendable @escaping () -> Void
    ) {
        totalSamples += 1
        if abs(pitch) > Self.badPostureThresholdRadians {
            badPostureCount += 1
        }

        // Check fraction threshold after at least 30 samples (~30 seconds at 1 Hz).
        if totalSamples >= 30,
           badPostureFraction > Self.badPostureFractionThreshold {
            onWarning()
        }
    }
}
