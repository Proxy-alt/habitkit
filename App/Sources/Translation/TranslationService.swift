import Foundation
import Translation

// MARK: - TranslationService

/// Provides on-device translation of habit completion notes (§8.20).
///
/// Uses the iOS 18+ Translation framework for privacy-preserving, on-device
/// translation. Falls back gracefully when translation is unavailable.
public actor TranslationService {

    // MARK: - Shared instance

    public static let shared = TranslationService()

    // MARK: - Init

    private init() {}

    // MARK: - Translation

    /// Translates a completion note into the device's preferred language.
    ///
    /// - Parameters:
    ///   - note: The source text to translate.
    ///   - sourceLanguage: BCP 47 language tag (e.g. "es", "fr"). Pass `nil`
    ///     to use automatic language detection.
    ///   - targetLanguage: The target BCP 47 language tag. Defaults to the
    ///     first preferred language on the device.
    /// - Returns: The translated string, or the original note if translation fails.
    public func translate(
        note: String,
        from sourceLanguage: Locale.Language? = nil,
        to targetLanguage: Locale.Language? = nil
    ) async -> String {
        guard !note.isEmpty else { return note }
        let source = sourceLanguage ?? Locale.Language(identifier: "en")
        let target = targetLanguage ?? Locale.preferredLanguages.first.flatMap {
            Locale.Language(identifier: $0)
        }

        do {
            let session = TranslationSession(installedSource: source, target: target)
            let response = try await session.translate(note)
            return response.targetText
        } catch {
            return note
        }
    }

    /// Checks whether translation between two languages requires a download.
    ///
    /// - Parameters:
    ///   - source: Source language (nil = auto-detect).
    ///   - target: Target language.
    /// - Returns: `true` if a language pack download is needed before translation.
    public func requiresDownload(
        from source: Locale.Language?,
        to target: Locale.Language
    ) async -> Bool {
        let availability = await LanguageAvailability().status(
            from: source ?? Locale.Language(identifier: "en"),
            to: target
        )
        return availability != .installed
    }
}
