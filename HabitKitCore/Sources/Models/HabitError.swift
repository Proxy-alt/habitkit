import Foundation

/// Errors thrown by HabitKitCore operations.
public enum HabitError: LocalizedError, Sendable {
    /// The habit has already been completed today.
    case alreadyCompletedToday
    /// The habit was not found in the persistent store.
    case notFound(UUID)
    /// A HealthKit operation failed.
    case healthKitUnavailable
    /// The model container could not be created.
    case persistenceFailure(String)

    public var errorDescription: String? {
        switch self {
        case .alreadyCompletedToday:
            return "This habit has already been completed today."
        case .notFound(let id):
            return "Habit with ID \(id) was not found."
        case .healthKitUnavailable:
            return "HealthKit is not available on this device."
        case .persistenceFailure(let reason):
            return "Persistence failure: \(reason)"
        }
    }
}
