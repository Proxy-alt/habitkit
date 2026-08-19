import BackgroundAssets
import Foundation

// MARK: - ThemeDownloadExtension

/// BADownloaderExtension that fetches updated `themes.json` in the background
/// so theme previews are available before the user opens the app (§8.28).
///
/// This class is the entry point for the Background Assets extension target.
/// The extension is separate from the main app; this file documents the
/// protocol implementation used in that extension.
public final class ThemeDownloadExtension: BADownloaderExtension {

    // MARK: - Constants

    /// URL of the hosted themes manifest.
    private static let themesManifestURL = URL(
        string: "https://habitkit.app/assets/themes.json"
    )

    // MARK: - Init

    public init() {}

    // MARK: - BADownloaderExtension

    public func downloads(
        for request: BAContentRequest,
        manifestURL: URL,
        extensionInfo: BAAppExtensionInfo
    ) -> Set<BADownload> {
        guard let url = Self.themesManifestURL else { return [] }
        let download = BAURLDownload(
            identifier: "com.habitkit.themes.json",
            request: URLRequest(url: url),
            essential: false,
            fileSize: 65_536,
            applicationGroupIdentifier: "group.com.habitkit.app",
            priority: .default
        )
        return [download]
    }

    public func backgroundDownload(
        _ download: BADownload,
        finishedWithFileURL fileURL: URL
    ) {
        // Move the downloaded themes.json to the shared app group container
        // so HKThemeManager can pick it up on next launch.
        let destination = sharedThemesURL()
        try? FileManager.default.removeItem(at: destination)
        try? FileManager.default.moveItem(at: fileURL, to: destination)
    }

    public func backgroundDownload(
        _ download: BADownload,
        failedWithError error: any Error
    ) {
        // Failures are silent — the app ships with built-in themes and
        // will retry on next background asset check.
    }

    // MARK: - Private helpers

    private func sharedThemesURL() -> URL {
        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.habitkit.app"
        ) ?? FileManager.default.temporaryDirectory
        return container.appendingPathComponent("themes.json")
    }
}
