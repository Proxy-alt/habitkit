import Foundation
import LinkPresentation

// MARK: - HabitLinkPresenter

/// Fetches rich link metadata for habit instruction URLs (§8.41).
///
/// When a user attaches a URL to a habit (e.g. a YouTube workout video),
/// `HabitLinkPresenter` pre-fetches the `LPLinkMetadata` so the habit
/// detail view can show a rich preview card instead of a bare URL.
public actor HabitLinkPresenter {

    // MARK: - Shared instance

    public static let shared = HabitLinkPresenter()

    // MARK: - Private state

    /// In-memory metadata cache to avoid redundant fetches in a session.
    private var cache: [URL: LPLinkMetadata] = [:]

    // MARK: - Init

    private init() {}

    // MARK: - Fetching

    /// Fetches `LPLinkMetadata` for the given URL.
    ///
    /// Results are cached for the lifetime of the actor. Pass `skipCache: true`
    /// to force a fresh network fetch.
    ///
    /// - Parameters:
    ///   - url: The URL to fetch metadata for.
    ///   - skipCache: Set to `true` to bypass the in-memory cache.
    /// - Returns: `LPLinkMetadata` if the fetch succeeds, or `nil` on failure.
    public func fetchMetadata(for url: URL, skipCache: Bool = false) async -> LPLinkMetadata? {
        if !skipCache, let cached = cache[url] { return cached }

        do {
            let provider = LPMetadataProvider()
            provider.shouldFetchSubresources = true
            provider.timeout = 15
            let metadata = try await provider.startFetchingMetadata(for: url)
            cache[url] = metadata
            return metadata
        } catch {
            return nil
        }
    }

    /// Pre-fetches metadata for a list of URLs in parallel.
    ///
    /// - Parameter urls: The URLs to pre-warm.
    public func prefetch(urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    _ = await self.fetchMetadata(for: url)
                }
            }
        }
    }

    /// Clears the in-memory metadata cache.
    public func clearCache() {
        cache.removeAll()
    }
}
