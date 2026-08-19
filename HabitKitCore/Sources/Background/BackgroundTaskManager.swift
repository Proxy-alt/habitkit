import BackgroundTasks
import Foundation

// MARK: - BackgroundTaskManager

/// Registers and handles BGContinuedProcessingTask and BGAppRefreshTask
/// background tasks for HabitKit (§8.19).
///
/// Two tasks are registered:
/// - **Archive export** (`com.habitkit.bg.archiveExport`): A
///   `BGContinuedProcessingTask` that runs a full archive export after the
///   user starts the process in the foreground.
/// - **HealthKit backfill** (`com.habitkit.bg.healthBackfill`): A
///   `BGProcessingTask` that writes queued HealthKit samples that could not
///   be written while the app was in the foreground.
public final class BackgroundTaskManager: Sendable {

    // MARK: - Shared instance

    public static let shared = BackgroundTaskManager()

    // MARK: - Task identifiers

    public static let archiveExportIdentifier = "com.habitkit.bg.archiveExport"
    public static let healthBackfillIdentifier = "com.habitkit.bg.healthBackfill"

    // MARK: - Init

    private init() {}

    // MARK: - Registration

    /// Registers all background task identifiers with `BGTaskScheduler`.
    ///
    /// Call from `application(_:didFinishLaunchingWithOptions:)` or the
    /// SwiftUI `.task` modifier on the root view.
    public func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.archiveExportIdentifier,
            using: nil
        ) { task in
            Self.handleArchiveExport(task: task)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.healthBackfillIdentifier,
            using: nil
        ) { task in
            Self.handleHealthBackfill(task: task)
        }
    }

    // MARK: - Scheduling

    /// Schedules a BGContinuedProcessingTask for an archive export.
    ///
    /// Call this after the user initiates an export in the UI.
    public func scheduleArchiveExport() throws {
        let request = BGContinuedProcessingTaskRequest(
            identifier: Self.archiveExportIdentifier,
            title: "Exporting Habit Archive",
            subtitle: "Preparing your habit data for export"
        )
        try BGTaskScheduler.shared.submit(request)
    }

    /// Schedules a BGProcessingTask to backfill HealthKit samples.
    ///
    /// - Parameter requiresNetwork: Pass `true` when the export requires a
    ///   network connection (e.g. CloudKit sync).
    public func scheduleHealthBackfill(requiresNetwork: Bool = false) throws {
        let request = BGProcessingTaskRequest(identifier: Self.healthBackfillIdentifier)
        request.requiresNetworkConnectivity = requiresNetwork
        request.requiresExternalPower = false
        try BGTaskScheduler.shared.submit(request)
    }

    // MARK: - Task handlers

    private static func handleArchiveExport(task: BGTask) {
        nonisolated(unsafe) let task = task
        let exportTask = Task {
            defer { task.setTaskCompleted(success: true) }
            // Notify the app to start the export; the continuation task keeps
            // the process alive in the background while it runs.
            NotificationCenter.default.post(
                name: .backgroundArchiveExportRequested,
                object: nil
            )
        }
        task.expirationHandler = {
            exportTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    private static func handleHealthBackfill(task: BGTask) {
        nonisolated(unsafe) let task = task
        let backfillTask = Task {
            defer { task.setTaskCompleted(success: true) }
            NotificationCenter.default.post(
                name: .backgroundHealthBackfillRequested,
                object: nil
            )
        }
        task.expirationHandler = {
            backfillTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}

// MARK: - Notification names

public extension Notification.Name {
    /// Posted when the system wakes the app to run an archive export.
    static let backgroundArchiveExportRequested = Notification.Name(
        "com.habitkit.backgroundArchiveExportRequested"
    )
    /// Posted when the system wakes the app to backfill HealthKit data.
    static let backgroundHealthBackfillRequested = Notification.Name(
        "com.habitkit.backgroundHealthBackfillRequested"
    )
}
