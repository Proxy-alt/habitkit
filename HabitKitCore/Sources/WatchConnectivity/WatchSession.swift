import Foundation
import WatchConnectivity

// MARK: - WatchSession

/// Manages WatchConnectivity communication between HabitKit on iPhone
/// and the companion Apple Watch app (§8.12).
///
/// Sends today's habits to the watch on activation and receives log-habit
/// messages from the watch face complications and Glance. Thread-safe via
/// the `WCSessionDelegate` callback queue.
public final class WatchSession: NSObject, WCSessionDelegate, Sendable {

    // MARK: - Shared instance

    public static let shared = WatchSession()

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Activation

    /// Activates the WCSession if the platform supports it.
    ///
    /// Call at app launch before any send/receive calls.
    public func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Sending data to watch

    /// Pushes today's habit context to the watch via `updateApplicationContext`.
    ///
    /// Context is delivered when the watch becomes reachable and replaces any
    /// previously sent context.
    ///
    /// - Parameter habits: Lightweight dictionary representations of today's habits.
    public func sendHabitsContext(_ habits: [[String: any Sendable]]) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }
        let context: [String: Any] = ["habits": habits, "timestamp": Date().timeIntervalSince1970]
        try? WCSession.default.updateApplicationContext(context)
    }

    /// Sends a "habit logged" confirmation message to the watch.
    ///
    /// - Parameters:
    ///   - habitID: UUID of the habit that was logged.
    ///   - habitName: Display name.
    public func sendLogConfirmation(habitID: UUID, habitName: String) {
        guard WCSession.isSupported(),
              WCSession.default.isReachable else { return }
        let message: [String: Any] = [
            "action": "habitLogged",
            "habitID": habitID.uuidString,
            "habitName": habitName,
        ]
        WCSession.default.sendMessage(message, replyHandler: nil)
    }

    // MARK: - WCSessionDelegate

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        // Activation complete; no action required — host app handles reachability.
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingMessage(message)
    }

    public func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        handleIncomingMessage(message)
        replyHandler(["status": "received"])
    }

    // MARK: - Message handling

    private func handleIncomingMessage(_ message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        switch action {
        case "logHabit":
            guard let idString = message["habitID"] as? String,
                  let habitID = UUID(uuidString: idString) else { return }
            NotificationCenter.default.post(
                name: .watchDidRequestLogHabit,
                object: nil,
                userInfo: ["habitID": habitID]
            )
        default:
            break
        }
    }
}

// MARK: - Notification names

public extension Notification.Name {
    /// Posted when the Apple Watch requests that a habit be logged.
    /// `userInfo["habitID"]` contains the `UUID`.
    static let watchDidRequestLogHabit = Notification.Name("com.habitkit.watchDidRequestLogHabit")
}
