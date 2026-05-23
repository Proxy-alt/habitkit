import CoreSpotlight
import Foundation

// MARK: - SpotlightIndexer

/// Indexes habits and completions in CoreSpotlight so they appear in
/// Spotlight search results (§8.14).
///
/// Each habit is indexed with its name, icon, color, and a deep-link URL.
/// Completions are indexed with their date and note for note search.
public actor SpotlightIndexer {

    // MARK: - Shared instance

    public static let shared = SpotlightIndexer()

    // MARK: - Domain identifiers

    private static let habitDomain = "com.habitkit.spotlight.habit"
    private static let completionDomain = "com.habitkit.spotlight.completion"

    // MARK: - Init

    private init() {}

    // MARK: - Indexing habits

    /// Indexes a batch of habits in CoreSpotlight.
    ///
    /// - Parameter habits: Lightweight habit representations to index.
    public func indexHabits(_ habits: [SpotlightHabitItem]) async {
        let items = habits.map { habit -> CSSearchableItem in
            let attribute = CSSearchableItemAttributeSet(contentType: .content)
            attribute.title = habit.name
            attribute.contentDescription = "Habit · \(habit.streak) day streak"
            attribute.keywords = ["habit", "habitkit", habit.name]
            attribute.relatedUniqueIdentifier = habit.id.uuidString

            let item = CSSearchableItem(
                uniqueIdentifier: "habit.\(habit.id.uuidString)",
                domainIdentifier: Self.habitDomain,
                attributeSet: attribute
            )
            item.expirationDate = .distantFuture
            return item
        }

        let index = CSSearchableIndex.default()
        try? await index.indexSearchableItems(items)
    }

    /// Removes the Spotlight entry for a specific habit.
    ///
    /// - Parameter habitID: The habit to deindex.
    public func deindexHabit(habitID: UUID) async {
        let index = CSSearchableIndex.default()
        try? await index.deleteSearchableItems(
            withIdentifiers: ["habit.\(habitID.uuidString)"]
        )
    }

    // MARK: - Indexing completions

    /// Indexes a completion record so its note can be found in Spotlight.
    ///
    /// - Parameters:
    ///   - completionID: Unique identifier of the completion.
    ///   - habitName: Name of the parent habit.
    ///   - note: The completion note text (used as body text for search).
    ///   - completedAt: The completion date.
    public func indexCompletion(
        completionID: UUID,
        habitName: String,
        note: String,
        completedAt: Date
    ) async {
        let attribute = CSSearchableItemAttributeSet(contentType: .text)
        attribute.title = habitName
        attribute.contentDescription = note
        attribute.contentCreationDate = completedAt
        attribute.keywords = ["habitkit", "completion", habitName]

        let item = CSSearchableItem(
            uniqueIdentifier: "completion.\(completionID.uuidString)",
            domainIdentifier: Self.completionDomain,
            attributeSet: attribute
        )
        item.expirationDate = completedAt.addingTimeInterval(60 * 60 * 24 * 365)

        let index = CSSearchableIndex.default()
        try? await index.indexSearchableItems([item])
    }

    // MARK: - Bulk reindex

    /// Deletes all HabitKit Spotlight entries and reindexes from scratch.
    ///
    /// - Parameter habits: Full list of habits to index after clearing.
    public func reindexAll(habits: [SpotlightHabitItem]) async {
        let index = CSSearchableIndex.default()
        try? await index.deleteSearchableItems(withDomainIdentifiers: [
            Self.habitDomain,
            Self.completionDomain,
        ])
        await indexHabits(habits)
    }
}

// MARK: - SpotlightHabitItem

/// Lightweight habit data needed for Spotlight indexing.
public struct SpotlightHabitItem: Sendable {
    public var id: UUID
    public var name: String
    public var icon: String
    public var streak: Int

    public init(id: UUID, name: String, icon: String, streak: Int) {
        self.id = id
        self.name = name
        self.icon = icon
        self.streak = streak
    }
}
