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

    /// Security-scoped bookmark data referencing a photo attached to this completion.
    public var photoBookmark: Data?

    /// Serialised `PaperMarkup` annotation attached to this completion.
    /// Stored with `.externalStorage` to keep binary markup data out of SQLite.
    /// `nil` if no annotation has been added.
    @Attribute(.externalStorage)
    public var paperMarkup: Data?

    /// The habit this completion belongs to.
    public var habit: Habit

    public init(
        id: UUID = UUID(),
        completedAt: Date = Date(),
        value: Double? = nil,
        durationSeconds: Int? = nil,
        note: String? = nil,
        photoBookmark: Data? = nil,
        paperMarkup: Data? = nil,
        habit: Habit
    ) {
        self.id = id
        self.completedAt = completedAt
        self.value = value
        self.durationSeconds = durationSeconds
        self.note = note
        self.photoBookmark = photoBookmark
        self.paperMarkup = paperMarkup
        self.habit = habit
    }
}
