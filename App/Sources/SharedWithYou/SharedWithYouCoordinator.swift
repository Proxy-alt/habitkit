import Foundation
import SharedWithYou

// MARK: - SharedWithYouCoordinator

/// Surfaces habit templates shared via iMessage in the "Shared With You"
/// shelf (§8.32).
///
/// When someone shares a habitkit:// deep link via iMessage, the link appears
/// in the app's "Shared With You" section using `SWHighlightCenter`.
public final class SharedWithYouCoordinator: NSObject, SWHighlightCenterDelegate, ObservableObject, @unchecked Sendable {

    // MARK: - Shared instance

    public static let shared = SharedWithYouCoordinator()

    // MARK: - Published state

    @MainActor @Published public var highlights: [SWHighlight] = []

    // MARK: - Private state

    private let center = SWHighlightCenter()

    // MARK: - Init

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - SWHighlightCenterDelegate

    public func highlightCenterHighlightsDidChange(_ highlightCenter: SWHighlightCenter) {
        nonisolated(unsafe) let currentHighlights = highlightCenter.highlights.filter { highlight in
            highlight.url.scheme == "habitkit"
        }
        Task { @MainActor in
            self.highlights = currentHighlights
        }
    }

    // MARK: - Handling deep links

    /// Processes a `habitkit://` URL from a Shared With You highlight.
    ///
    /// - Parameter url: The URL from the highlight.
    /// - Returns: A `SharedWithYouDeepLink` if the URL is a valid HabitKit link.
    public static func deepLink(from url: URL) -> SharedWithYouDeepLink? {
        guard url.scheme == "habitkit" else { return nil }

        switch url.host {
        case "template":
            guard let id = url.pathComponents.dropFirst().first else { return nil }
            return .template(id: id)

        case "habit":
            guard let idString = url.pathComponents.dropFirst().first,
                  let id = UUID(uuidString: idString) else { return nil }
            return .habit(id: id)

        default:
            return nil
        }
    }
}

// MARK: - SharedWithYouDeepLink

/// The destination described by a Shared With You habitkit:// URL.
public enum SharedWithYouDeepLink: Sendable {
    /// Open a habit template from the library.
    case template(id: String)
    /// Navigate to a specific habit's detail view.
    case habit(id: UUID)
}
