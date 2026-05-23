import Foundation
import UIKit

// MARK: - HandoffManager

/// Donates and receives NSUserActivity continuations for Handoff (§8.11).
///
/// HabitKit donates activities when the user views a specific habit or starts
/// a timed session. Receiving the activity on another device restores the
/// same screen via deep-link.
public final class HandoffManager: NSObject, Sendable {

    // MARK: - Activity types

    /// Unique activity type for viewing a specific habit's detail screen.
    public static let viewHabitActivityType = "com.habitkit.activity.viewHabit"

    /// Unique activity type for a live timed session.
    public static let liveSessionActivityType = "com.habitkit.activity.liveSession"

    // MARK: - Donation

    /// Donates a "view habit" Handoff activity.
    ///
    /// - Parameters:
    ///   - habitID: The UUID of the habit being viewed.
    ///   - habitName: The display name used as the activity title.
    /// - Returns: The `NSUserActivity` — retain it in the active view's controller.
    @discardableResult
    public static func donateViewHabit(habitID: UUID, habitName: String) -> NSUserActivity {
        let activity = NSUserActivity(activityType: viewHabitActivityType)
        activity.title = habitName
        activity.userInfo = ["habitID": habitID.uuidString]
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier = habitID.uuidString
        activity.becomeCurrent()
        return activity
    }

    /// Donates a "live session" Handoff activity for a timed habit.
    ///
    /// - Parameters:
    ///   - habitID: The habit being timed.
    ///   - habitName: Display name.
    ///   - remainingSeconds: Current countdown value.
    /// - Returns: The `NSUserActivity` — retain it; update `userInfo` as time elapses.
    @discardableResult
    public static func donateLiveSession(
        habitID: UUID,
        habitName: String,
        remainingSeconds: Int
    ) -> NSUserActivity {
        let activity = NSUserActivity(activityType: liveSessionActivityType)
        activity.title = "Timer: \(habitName)"
        activity.userInfo = [
            "habitID": habitID.uuidString,
            "remainingSeconds": remainingSeconds,
        ]
        activity.isEligibleForHandoff = true
        activity.becomeCurrent()
        return activity
    }

    // MARK: - Restoration

    /// Parses an incoming `NSUserActivity` and returns the deep-link destination.
    ///
    /// - Parameter activity: The incoming activity from the system.
    /// - Returns: A `HandoffDestination` describing which screen to restore.
    public static func destination(from activity: NSUserActivity) -> HandoffDestination? {
        switch activity.activityType {
        case viewHabitActivityType:
            guard let idString = activity.userInfo?["habitID"] as? String,
                  let id = UUID(uuidString: idString) else { return nil }
            return .habitDetail(id: id)

        case liveSessionActivityType:
            guard let idString = activity.userInfo?["habitID"] as? String,
                  let id = UUID(uuidString: idString) else { return nil }
            let remaining = activity.userInfo?["remainingSeconds"] as? Int ?? 0
            return .liveSession(habitID: id, remainingSeconds: remaining)

        default:
            return nil
        }
    }
}

// MARK: - HandoffDestination

/// The screen that should be restored when a Handoff activity is received.
public enum HandoffDestination: Sendable {
    /// Navigate to the habit detail view for the given habit.
    case habitDetail(id: UUID)
    /// Restore a live timer session for the given habit.
    case liveSession(habitID: UUID, remainingSeconds: Int)
}
