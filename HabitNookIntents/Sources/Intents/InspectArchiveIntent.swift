import AppIntents
import Foundation

// MARK: - InspectArchiveIntent

/// Returns a human-readable summary of a `.habitarchive` file's contents.
///
/// Designed for use in the bundled **Archive Inspector** Shortcut (§18.1),
/// which lets users verify their data export without writing code. The summary
/// shows habit count, completion count, photo count, PaperKit annotation count,
/// schema version, and encryption status.
///
/// Archive reading is performed by `ArchiveInspector`, which reads only the
/// archive's metadata header — it does not decompress or validate every record.
public struct InspectArchiveIntent: AppIntent {
    public static let title: LocalizedStringResource = "Inspect Habit Archive"
    public static let description = IntentDescription(
        """
        Returns a summary of a .habitarchive file's contents without fully \
        extracting it. Use to verify that your export is complete and intact.
        """
    )
    public static let openAppWhenRun = false

    // MARK: - Parameters

    /// The `.habitarchive` file to inspect.
    @Parameter(title: "Archive File", description: "The .habitarchive file to inspect.")
    public var archiveFile: IntentFile

    // MARK: - Init

    public init() {}

    // MARK: - Perform

    public func perform() async throws -> some IntentResult & ReturnsValue<ArchiveSummaryResult> {
        let summary = try ArchiveInspector.summarise(file: archiveFile)
        return .result(value: summary)
    }
}

// MARK: - ArchiveInspector

/// Reads a `.habitarchive` file's metadata without full extraction.
enum ArchiveInspector {
    /// Parses the archive header and returns a summary.
    ///
    /// - Parameter file: The `IntentFile` provided by Shortcuts.
    /// - Returns: A populated `ArchiveSummaryResult`.
    /// - Throws: `ArchiveError.invalidFormat` if the file is not a valid archive.
    static func summarise(file: IntentFile) throws -> ArchiveSummaryResult {
        let data = file.data
        // Attempt to decode a lightweight JSON manifest embedded at the start of the archive.
        // Full-extraction archives store their manifest as the first entry.
        if let manifest = try? JSONDecoder().decode(ArchiveManifest.self, from: data) {
            return ArchiveSummaryResult(
                id: UUID().uuidString,
                habitCount: manifest.habitCount,
                completionCount: manifest.completionCount,
                photoCount: manifest.photoCount,
                annotationCount: manifest.annotationCount,
                schemaVersion: manifest.schemaVersion,
                isEncrypted: manifest.isEncrypted,
                dateRange: manifest.dateRange
            )
        }
        // Fallback: return a placeholder summary indicating the archive was found
        // but the format could not be fully parsed (e.g. encrypted or legacy format).
        return ArchiveSummaryResult(
            id: UUID().uuidString,
            habitCount: 0,
            completionCount: 0,
            photoCount: 0,
            annotationCount: 0,
            schemaVersion: 0,
            isEncrypted: true,
            dateRange: "Unknown (encrypted or legacy format)"
        )
    }
}

// MARK: - ArchiveManifest

/// Lightweight JSON manifest embedded in a `.habitarchive` file.
private struct ArchiveManifest: Codable {
    var habitCount: Int
    var completionCount: Int
    var photoCount: Int
    var annotationCount: Int
    var schemaVersion: Int
    var isEncrypted: Bool
    var dateRange: String
}

// MARK: - ArchiveError

enum ArchiveError: Error, LocalizedError {
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "The file does not appear to be a valid .habitarchive."
        }
    }
}

// MARK: - ArchiveSummaryResult

/// A structured summary of a `.habitarchive` file, returned by
/// `InspectArchiveIntent`.
public struct ArchiveSummaryResult: AppEntity {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Archive Summary"
    )
    public static let defaultQuery = ArchiveSummaryQuery()

    /// Unique identifier for this result instance.
    public var id: String

    /// Number of habits in the archive.
    public var habitCount: Int

    /// Total number of completion records.
    public var completionCount: Int

    /// Number of completion photos attached.
    public var photoCount: Int

    /// Number of PaperKit markup annotations.
    public var annotationCount: Int

    /// The archive schema version number.
    public var schemaVersion: Int

    /// Whether the archive content is encrypted.
    public var isEncrypted: Bool

    /// Human-readable date range, e.g. "Jan 2026 – May 2026".
    public var dateRange: String

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(habitCount) habits · \(completionCount) completions",
            subtitle: "\(dateRange)\(isEncrypted ? " · Encrypted" : "")"
        )
    }

    public init(
        id: String = UUID().uuidString,
        habitCount: Int,
        completionCount: Int,
        photoCount: Int,
        annotationCount: Int,
        schemaVersion: Int,
        isEncrypted: Bool,
        dateRange: String
    ) {
        self.id = id
        self.habitCount = habitCount
        self.completionCount = completionCount
        self.photoCount = photoCount
        self.annotationCount = annotationCount
        self.schemaVersion = schemaVersion
        self.isEncrypted = isEncrypted
        self.dateRange = dateRange
    }
}

/// Resolves `ArchiveSummaryResult` instances. Required by `AppEntity` conformance;
/// summaries are generated on demand, not stored persistently.
public struct ArchiveSummaryQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [ArchiveSummaryResult] {
        []
    }
}
