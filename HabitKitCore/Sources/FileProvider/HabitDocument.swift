import Foundation
import UniformTypeIdentifiers

// MARK: - HabitDocument

/// A `FileDocument`-compatible wrapper for the `.habitarchive` file type (§8.15).
///
/// HabitKit declares the `com.habitkit.habitarchive` UTType so archives appear
/// as first-class documents in Files.app and can be shared via the share sheet.
/// The document wraps a JSON-encoded `ArchivePayload`.
public struct HabitDocument: Sendable {

    // MARK: - UTType

    /// The uniform type identifier for HabitKit archive files.
    public static let archiveType = UTType(exportedAs: "com.habitkit.habitarchive")

    // MARK: - Properties

    /// The raw archive data.
    public var data: Data

    // MARK: - Init

    public init(data: Data) {
        self.data = data
    }

    /// Creates a `HabitDocument` from a file URL.
    ///
    /// - Parameter url: The `.habitarchive` file URL.
    /// - Throws: Any file-reading error.
    public init(url: URL) throws {
        self.data = try Data(contentsOf: url)
    }

    // MARK: - Persistence

    /// Writes the archive to a file URL.
    ///
    /// - Parameter url: Destination URL (must have `.habitarchive` extension).
    /// - Throws: Any file-writing error.
    public func write(to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }
}

// MARK: - ArchivePayload

/// The serialisable payload embedded in a `.habitarchive` file.
public struct ArchivePayload: Codable, Sendable {
    /// Schema version — increment when the payload format changes.
    public var schemaVersion: Int

    /// ISO 8601 export timestamp.
    public var exportedAt: String

    /// Snapshot of all exported habits (lightweight JSON).
    public var habits: [ArchiveHabitRecord]

    /// Whether the habit data is AES-GCM encrypted.
    public var isEncrypted: Bool

    /// Encrypted payload blob; `nil` when `isEncrypted == false`.
    public var encryptedData: Data?

    public init(
        schemaVersion: Int = 1,
        exportedAt: String,
        habits: [ArchiveHabitRecord],
        isEncrypted: Bool = false,
        encryptedData: Data? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.habits = habits
        self.isEncrypted = isEncrypted
        self.encryptedData = encryptedData
    }
}

// MARK: - ArchiveHabitRecord

/// A flat, serialisable representation of a habit for archive export.
public struct ArchiveHabitRecord: Codable, Sendable {
    public var id: String
    public var name: String
    public var icon: String
    public var colorHex: String
    public var createdAt: Date
    public var completionCount: Int
    public var currentStreak: Int

    public init(
        id: String,
        name: String,
        icon: String,
        colorHex: String,
        createdAt: Date,
        completionCount: Int,
        currentStreak: Int
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.completionCount = completionCount
        self.currentStreak = currentStreak
    }
}
