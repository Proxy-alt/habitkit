import AppIntents
import Foundation

/// An `AppEntity` representing a single `Habit` for use in Siri, Shortcuts,
/// Spotlight, and Visual Intelligence surfaces.
///
/// `HabitEntity` is a lightweight projection — it carries only the fields
/// needed for display and identification. Full model data lives in SwiftData.
public struct HabitEntity: AppEntity, Identifiable, Sendable {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit")
    public static let defaultQuery = HabitEntityQuery()

    public let id: UUID
    public let name: String
    public let icon: String

    /// The current streak length in days.
    public let streak: Int

    /// Whether this habit has a completion recorded for today.
    public let isCompletedToday: Bool

    public init(id: UUID, name: String, icon: String, streak: Int = 0, isCompletedToday: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.streak = streak
        self.isCompletedToday = isCompletedToday
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: icon))
    }
}

/// Resolves ``HabitEntity`` values from the persistent store by identifier.
public struct HabitEntityQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [UUID]) async throws -> [HabitEntity] {
        let store = HabitIntentStore(modelContainer: try IntentModelContainer.make())
        return try await store.fetchEntities(for: identifiers)
    }

    public func suggestedEntities() async throws -> [HabitEntity] {
        let store = HabitIntentStore(modelContainer: try IntentModelContainer.make())
        return try await store.fetchAllEntities()
    }
}
