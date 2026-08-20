import Foundation
import SwiftData

/// Records a single instance of a habit being completed.
@Model
public class HabitCompletion {
    /// Stable unique identifier for this completion record.
    public var id: UUID

    /// The exact date and time the completion was recorded.
    public var completedAt: Date

    /// For quantity habits: the amount logged in this session.
    public var value: Double?

    /// For timed habits: the number of seconds spent in this session.
    public var durationSeconds: Int?

    /// Optional user note attached to this completion.
    public var note: String?

    /// JSON-encoded `[String]` of tags. Stored as `Data` for the same reason
    /// as other array-typed `@Model` properties in this codebase: Array<String>
    /// uses Builtin.BridgeObject for its CoW storage buffer, which crashes
    /// SchemaProperty during SwiftData's schema analysis.
    private var tagsData: Data = Data()

    /// Tags describing this completion's note, generated on-device by
    /// `HabitCoach.tagNote` when a note is present. Empty until tagging
    /// finishes (or if there was no note to tag).
    public var tags: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: tagsData)) ?? []
        }
        set {
            tagsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    /// Security-scoped bookmark data referencing a photo attached to this completion.
    public var photoBookmark: Data?

    /// Serialised `PaperMarkup` annotation attached to this completion.
    /// Stored with `.externalStorage` to keep binary markup data out of SQLite.
    /// `nil` if no annotation has been added.
    @Attribute(.externalStorage)
    public var paperMarkup: Data?

    /// The habit this completion belongs to.
    @Relationship(inverse: \Habit.completions)
    public var habit: Habit

    public init(
        id: UUID = UUID(),
        completedAt: Date = Date(),
        value: Double? = nil,
        durationSeconds: Int? = nil,
        note: String? = nil,
        tags: [String] = [],
        photoBookmark: Data? = nil,
        paperMarkup: Data? = nil,
        habit: Habit
    ) {
        self.id = id
        self.completedAt = completedAt
        self.value = value
        self.durationSeconds = durationSeconds
        self.note = note
        self.tagsData = (try? JSONEncoder().encode(tags)) ?? Data()
        self.photoBookmark = photoBookmark
        self.paperMarkup = paperMarkup
        self.habit = habit
    }
}
