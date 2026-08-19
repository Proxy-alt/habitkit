import Foundation
import ShazamKit

// MARK: - ShazamMatcher

/// Matches ambient audio against a custom ShazamKit catalog to detect
/// practice-session audio cues (§8.22).
///
/// For instrument-practice habits, a custom catalog can include short
/// reference signatures recorded from the target instrument. When the
/// microphone picks up a match, the habit is auto-completed.
public actor ShazamMatcher: NSObject {

    // MARK: - Shared instance

    public static let shared = ShazamMatcher()

    // MARK: - Private state

    private var session: SHSession?
    private var onMatchHandler: (@Sendable (SHMatchedMediaItem) -> Void)?
    private var onNoMatchHandler: (@Sendable () -> Void)?

    // MARK: - Init

    private override init() {}

    // MARK: - Custom catalog matching

    /// Starts an audio matching session using a custom `SHCustomCatalog`.
    ///
    /// - Parameters:
    ///   - catalog: A `SHCustomCatalog` containing the reference signatures.
    ///   - onMatch: Called when a match is found; receives the matched item.
    ///   - onNoMatch: Called when a 5-second query produces no match.
    public func startMatching(
        catalog: SHCustomCatalog,
        onMatch: @Sendable @escaping (SHMatchedMediaItem) -> Void,
        onNoMatch: @Sendable @escaping () -> Void
    ) {
        onMatchHandler = onMatch
        onNoMatchHandler = onNoMatch

        let newSession = SHSession(catalog: catalog)
        newSession.delegate = self
        self.session = newSession

        let audioEngine = SHManagedSession()
        Task {
            await audioEngine.prepare()
            for await result in audioEngine.results {
                switch result {
                case .match(let match):
                    if let item = match.mediaItems.first {
                        onMatch(item)
                    }
                case .noMatch:
                    onNoMatch()
                case .error(let error, _):
                    if (error as NSError).domain != SHErrorDomain { continue }
                }
            }
        }
    }

    /// Stops the active matching session.
    public func stopMatching() {
        session = nil
        onMatchHandler = nil
        onNoMatchHandler = nil
    }

    // MARK: - Catalog building

    /// Builds a `SHCustomCatalog` from a set of audio data blobs.
    ///
    /// - Parameter audioFiles: Array of `(title, artist, audioData)` tuples
    ///   where `audioData` is PCM audio data to generate a signature from.
    /// - Returns: A populated `SHCustomCatalog`, or `nil` if generation fails.
    public static func buildCatalog(
        from audioFiles: [(title: String, artist: String, audioData: Data)]
    ) async -> SHCustomCatalog? {
        let catalog = SHCustomCatalog()
        for item in audioFiles {
            guard let signature = try? SHSignature(dataRepresentation: item.audioData) else {
                continue
            }
            let mediaItem = SHMediaItem(properties: [
                .title: item.title,
                .artist: item.artist,
            ])
            try? catalog.addReferenceSignature(signature, representing: [mediaItem])
        }
        return catalog
    }
}

// MARK: - SHSessionDelegate

extension ShazamMatcher: SHSessionDelegate {
    nonisolated public func session(_ session: SHSession, didFind match: SHMatch) {
        guard let item = match.mediaItems.first else { return }
        Task {
            let handler = await self.onMatchHandler
            handler?(item)
        }
    }

    nonisolated public func session(
        _ session: SHSession,
        didNotFindMatchFor signature: SHSignature,
        error: (any Error)?
    ) {
        Task {
            let handler = await self.onNoMatchHandler
            handler?()
        }
    }
}
