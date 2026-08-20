import Foundation
import SwiftData

/// Provides a configured `ModelContainer` for the full HabitKitCore schema.
public actor ModelContainerConfiguration {

    // MARK: - Schema

    /// All `PersistentModel` types that make up the HabitKitCore schema.
    private static let allModelTypes: [any PersistentModel.Type] = [
        Habit.self,
        TimedHabit.self,
        QuantityHabit.self,
        ChecklistHabit.self,
        NegativeHabit.self,
        HabitCompletion.self,
        HabitSchedule.self,
        ProgressionPlan.self,
        ProgressionEvent.self,
        NegativeProgressionPlan.self,
        VisionProfile.self,
    ]

    // MARK: - Factory

    /// Creates and returns a fully configured `ModelContainer`.
    ///
    /// - Parameter cloudKitEnabled: When `true` the container will sync with
    ///   iCloud via CloudKit using the container identifier
    ///   `iCloud.com.habitkit.app`.
    /// - Returns: A ready-to-use `ModelContainer`.
    /// - Throws: Any error raised by `ModelContainer.init`.
    public static func makeContainer(cloudKitEnabled: Bool) throws -> ModelContainer {
        let schema = Schema(allModelTypes)

        let configuration: ModelConfiguration
        if cloudKitEnabled {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.habitkit.app")
            )
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
        }

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Creates an in-memory container suitable for SwiftUI previews and unit tests.
    ///
    /// - Returns: An in-memory `ModelContainer`.
    /// - Throws: Any error raised by `ModelContainer.init`.
    public static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema(allModelTypes)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
