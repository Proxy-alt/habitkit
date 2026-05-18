import AppIntents
import Foundation

public struct HabitEntity: AppEntity, Identifiable, Sendable {
    public static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit")
    public static var defaultQuery = HabitEntityQuery()

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

public struct HabitEntityQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [UUID]) async throws -> [HabitEntity] {
        // In a real app, this would query SwiftData using the provided identifiers.
        []
    }

    public func suggestedEntities() async throws -> [HabitEntity] {
        // In a real app, this would return all habits from SwiftData.
        []
    }
}
