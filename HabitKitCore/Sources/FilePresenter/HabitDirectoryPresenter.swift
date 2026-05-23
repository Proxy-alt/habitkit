import Foundation

// MARK: - HabitDirectoryPresenter

/// Implements `NSFilePresenter` to reactively observe the user's `.habit`
/// file directory for changes (§8.29).
///
/// When the user's iCloud Drive folder containing `.habit` files changes
/// (e.g. via Files.app on another device), the presenter posts a
/// notification so the repository can reload its data.
public final class HabitDirectoryPresenter: NSObject, NSFilePresenter, Sendable {

    // MARK: - Shared instance

    public static let shared = HabitDirectoryPresenter()

    // MARK: - NSFilePresenter

    public var presentedItemURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.habitkit.app"
        )
    }

    public var presentedItemOperationQueue: OperationQueue {
        OperationQueue.main
    }

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Registration

    /// Registers this presenter with `NSFileCoordinator`.
    ///
    /// Call at app launch. Balances with `unregister()` on termination.
    public func register() {
        NSFileCoordinator.addFilePresenter(self)
    }

    /// Removes this presenter from `NSFileCoordinator`.
    public func unregister() {
        NSFileCoordinator.removeFilePresenter(self)
    }

    // MARK: - NSFilePresenter callbacks

    public func presentedItemDidChange() {
        NotificationCenter.default.post(name: .habitDirectoryDidChange, object: nil)
    }

    public func presentedSubitemDidChange(at url: URL) {
        NotificationCenter.default.post(
            name: .habitDirectoryDidChange,
            object: nil,
            userInfo: ["changedURL": url]
        )
    }

    public func accommodatePresentedItemDeletion(completionHandler: @escaping (any Error?) -> Void) {
        completionHandler(nil)
    }
}

// MARK: - Notification names

public extension Notification.Name {
    /// Posted when the `.habit` file directory changes.
    /// `userInfo["changedURL"]` may contain the specific URL that changed.
    static let habitDirectoryDidChange = Notification.Name("com.habitkit.habitDirectoryDidChange")
}
