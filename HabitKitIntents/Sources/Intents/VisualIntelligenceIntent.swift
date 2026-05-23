import AppIntents
import Foundation

// MARK: - VisualIntelligenceIntent (§8.3)

/// Allows Visual Intelligence (iOS 26) to recognise a habit QR code or
/// NFC tag label and surface a "Log Habit" action in the Visual Intelligence overlay.
///
/// When the user points the camera at a HabitKit QR code, iOS invokes this
/// intent automatically. The `habitIdentifier` parameter carries the scanned value.
public struct VisualIntelligenceIntent: AppIntent {
    public static let title: LocalizedStringResource = "Recognise Habit Tag"
    public static let description = IntentDescription(
        "Recognises a HabitKit QR code or NFC label and offers to log the habit."
    )
    public static let openAppWhenRun = false
    public static let isDiscoverable = false  // Surface via Visual Intelligence only

    // MARK: - Parameters

    /// The raw string payload from the scanned QR code or NFC tag.
    @Parameter(
        title: "Habit Identifier",
        description: "Raw habitkit:// URL or UUID from a scanned QR code or NFC tag."
    )
    public var habitIdentifier: String

    // MARK: - Init

    public init() {}
    public init(habitIdentifier: String) {
        self.habitIdentifier = habitIdentifier
    }

    // MARK: - Perform

    public func perform() async throws -> some IntentResult & ReturnsValue<HabitEntity> {
        // Parse habitkit:// URL or bare UUID.
        let habitID: UUID
        if let url = URL(string: habitIdentifier),
           url.scheme == "habitkit",
           url.host == "habit",
           let idString = url.pathComponents.dropFirst().first,
           let id = UUID(uuidString: idString) {
            habitID = id
        } else if let id = UUID(uuidString: habitIdentifier) {
            habitID = id
        } else {
            throw VisualIntelligenceError.unrecognisedTag
        }

        let store = HabitIntentStore(modelContainer: try IntentModelContainer.make())
        let allHabits = try await store.fetchAllHabits()
        guard let habit = allHabits.first(where: { $0.id == habitID }) else {
            throw VisualIntelligenceError.habitNotFound
        }
        return .result(value: habit)
    }
}

// MARK: - VisualIntelligenceError

enum VisualIntelligenceError: Error, LocalizedError {
    case unrecognisedTag
    case habitNotFound

    var errorDescription: String? {
        switch self {
        case .unrecognisedTag: return "The scanned tag could not be recognised as a HabitKit habit."
        case .habitNotFound: return "The habit referenced by this tag no longer exists."
        }
    }
}
