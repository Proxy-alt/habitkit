import ActivityKit
import Foundation

/// Shared between the app (which starts/updates the activity) and the
/// HabitKitWidgets extension (which renders it) — both need the same type.
public struct HabitLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var remainingSeconds: Int
        public var habitName: String
        public var isComplete: Bool

        public init(remainingSeconds: Int, habitName: String, isComplete: Bool) {
            self.remainingSeconds = remainingSeconds
            self.habitName = habitName
            self.isComplete = isComplete
        }
    }

    public var habitID: UUID
    public var habitName: String
    public var targetSeconds: Int

    public init(habitID: UUID, habitName: String, targetSeconds: Int) {
        self.habitID = habitID
        self.habitName = habitName
        self.targetSeconds = targetSeconds
    }
}
