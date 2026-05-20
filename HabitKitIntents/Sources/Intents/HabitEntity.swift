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

    public init(id: UUID, name: String, icon: String) {
        self.id = id
        self.name = name
        self.icon = icon
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: icon))
    }
}

/// Resolves ``HabitEntity`` values from the persistent store by identifier.
public struct HabitEntityQuery: EntityQuery {
    public init() {}

    /// Returns the entities that match the given identifiers.
    ///
    /// The real implementation queries SwiftData via the shared `ModelContainer`.
    public func entities(for identifiers: [UUID]) async throws -> [HabitEntity] {
        []
    }

    /// Returns a list of habits to suggest when no query has been typed.
    public func suggestedEntities() async throws -> [HabitEntity] {
        []
    }
}
