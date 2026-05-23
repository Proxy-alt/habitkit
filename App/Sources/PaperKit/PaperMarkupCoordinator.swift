import PaperKit
import SwiftUI
import UIKit

// MARK: - PaperMarkupCoordinator

/// Presents the PaperKit markup canvas for annotating habit completion photos (§8.42).
///
/// When a user long-presses a completion photo in the detail view, the
/// coordinator presents `PaperMarkupViewController`. On dismissal the
/// serialised `PaperMarkup` data is stored in `HabitCompletion.paperMarkup`.
@MainActor
public final class PaperMarkupCoordinator: NSObject, ObservableObject {

    // MARK: - Shared instance

    public static let shared = PaperMarkupCoordinator()

    // MARK: - Published state

    @Published public var isPresentingMarkup = false
    @Published public var lastMarkupData: Data?

    // MARK: - Private state

    private var completionID: UUID?
    private var onSave: ((Data) -> Void)?

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Presentation

    /// Presents the PaperKit markup canvas for the given completion photo.
    ///
    /// - Parameters:
    ///   - imageData: The base photo to annotate.
    ///   - existingMarkup: Existing serialised `PaperMarkup`, if any.
    ///   - completionID: The completion record this markup belongs to.
    ///   - onSave: Called with the serialised markup `Data` when the user saves.
    public func presentMarkup(
        imageData: Data,
        existingMarkup: Data?,
        completionID: UUID,
        onSave: @escaping (Data) -> Void,
        from presentingViewController: UIViewController
    ) {
        self.completionID = completionID
        self.onSave = onSave

        let markupVC = PaperMarkupViewController()
        markupVC.delegate = self

        if let existingMarkup,
           let markup = try? PaperMarkup(data: existingMarkup) {
            markupVC.markup = markup
        }

        if let image = UIImage(data: imageData) {
            markupVC.backgroundImage = image
        }

        let nav = UINavigationController(rootViewController: markupVC)
        nav.modalPresentationStyle = .fullScreen
        presentingViewController.present(nav, animated: true)
        isPresentingMarkup = true
    }
}

// MARK: - PaperMarkupViewControllerDelegate

extension PaperMarkupCoordinator: PaperMarkupViewControllerDelegate {
    public func markupViewControllerDidFinish(
        _ controller: PaperMarkupViewController,
        markup: PaperMarkup
    ) {
        isPresentingMarkup = false
        guard let data = try? markup.serialisedData() else { return }
        lastMarkupData = data
        onSave?(data)
    }

    public func markupViewControllerDidCancel(_ controller: PaperMarkupViewController) {
        isPresentingMarkup = false
    }
}
