import PaperKit
import SwiftUI
import UIKit

// MARK: - PaperMarkupCoordinator

/// Presents the PaperKit markup canvas for annotating habit completion photos (§8.42).
///
/// `PaperMarkupViewController.Delegate` only reports live editing interactions
/// (drawing/selection/adornment changes) — it has no finish/cancel callback, so
/// this coordinator supplies its own Done/Cancel bar buttons and reads the
/// `PaperMarkup` back from the view controller directly when the user taps Done.
@MainActor
public final class PaperMarkupCoordinator: NSObject, ObservableObject {

    // MARK: - Shared instance

    public static let shared = PaperMarkupCoordinator()

    // MARK: - Published state

    @Published public var isPresentingMarkup = false
    @Published public var lastMarkupData: Data?

    // MARK: - Private state

    private var onSave: ((Data) -> Void)?
    private weak var markupViewController: PaperMarkupViewController?
    private weak var presentingViewController: UIViewController?

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
        guard let image = UIImage(data: imageData), let cgImage = image.cgImage else { return }

        self.onSave = onSave
        self.presentingViewController = presentingViewController

        var markup: PaperMarkup
        if let existingMarkup, let loaded = try? PaperMarkup(dataRepresentation: existingMarkup) {
            markup = loaded
        } else {
            let bounds = CGRect(origin: .zero, size: image.size)
            markup = PaperMarkup(bounds: bounds)
            markup.insertNewImage(cgImage, frame: bounds)
        }

        let markupVC = PaperMarkupViewController(markup: markup, supportedFeatureSet: .latest)
        markupVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped)
        )
        markupVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(doneTapped)
        )
        self.markupViewController = markupVC

        let nav = UINavigationController(rootViewController: markupVC)
        nav.modalPresentationStyle = .fullScreen
        presentingViewController.present(nav, animated: true)
        isPresentingMarkup = true
    }

    // MARK: - Bar button actions

    @objc private func doneTapped() {
        guard let markup = markupViewController?.markup else {
            dismiss()
            return
        }
        Task {
            if let data = try? await markup.dataRepresentation() {
                lastMarkupData = data
                onSave?(data)
            }
            dismiss()
        }
    }

    @objc private func cancelTapped() {
        dismiss()
    }

    private func dismiss() {
        presentingViewController?.dismiss(animated: true)
        isPresentingMarkup = false
        markupViewController = nil
        presentingViewController = nil
        onSave = nil
    }
}
