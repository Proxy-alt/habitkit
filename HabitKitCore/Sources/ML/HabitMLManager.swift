import CoreML
import Foundation

// MARK: - HabitMLManager

/// Manages on-device CoreML clustering and personalised nudge predictions (§8.36).
///
/// HabitKit ships a compiled `HabitCluster.mlmodel` that classifies completion
/// patterns into clusters. An `MLUpdateTask` retrains the model periodically
/// using the user's own completion history, scheduled via `BGProcessingTask`.
public actor HabitMLManager {

    // MARK: - Shared instance

    public static let shared = HabitMLManager()

    // MARK: - Private state

    private var compiledModelURL: URL?

    // MARK: - Init

    private init() {}

    // MARK: - Cluster prediction

    /// Predicts the habit cluster for a given completion pattern.
    ///
    /// - Parameters:
    ///   - completionRate: 0.0–1.0 weekly completion rate.
    ///   - avgCompletionHour: Average hour of day completions occur (0–23).
    ///   - streakLength: Current streak length in days.
    /// - Returns: A `HabitCluster` enum value, or `nil` if the model is not loaded.
    public func predictCluster(
        completionRate: Double,
        avgCompletionHour: Double,
        streakLength: Int
    ) async -> HabitCluster? {
        guard let url = compiledModelURL ?? defaultModelURL() else { return nil }
        guard let model = try? MLModel(contentsOf: url) else { return nil }

        let input = try? MLDictionaryFeatureProvider(dictionary: [
            "completion_rate": completionRate as NSNumber,
            "avg_completion_hour": avgCompletionHour as NSNumber,
            "streak_length": Double(streakLength) as NSNumber,
        ])
        guard let input, let output = try? model.prediction(from: input) else { return nil }

        guard let clusterID = output.featureValue(for: "cluster_label")?.int64Value else {
            return nil
        }
        return HabitCluster(rawValue: Int(clusterID))
    }

    // MARK: - Model update

    /// Schedules an `MLUpdateTask` to retrain the local model with new data.
    ///
    /// This is called from the `BGProcessingTask` handler registered in
    /// `BackgroundTaskManager`.
    ///
    /// - Parameter trainingBatches: Array of (featureDict, label) tuples.
    public func updateModel(
        trainingBatches: [([String: Double], Int)]
    ) async throws {
        guard let modelURL = defaultModelURL() else { return }
        let outputURL = updatedModelURL()

        let trainingData = try trainingBatches.map { features, label -> MLFeatureProvider in
            var dict: [String: Any] = features.mapValues { $0 as NSNumber }
            dict["cluster_label"] = Int64(label) as NSNumber
            return try MLDictionaryFeatureProvider(dictionary: dict)
        }
        let batchProvider = MLArrayBatchProvider(array: trainingData)

        let updateTask = try MLUpdateTask(
            forModelAt: modelURL,
            trainingData: batchProvider,
            configuration: nil
        ) { [weak self] context in
            guard let updatedModel = context.model else { return }
            try? updatedModel.write(to: outputURL)
            Task { await self?.loadUpdatedModel(at: outputURL) }
        }
        updateTask.resume()
    }

    // MARK: - Private helpers

    private func loadUpdatedModel(at url: URL) {
        compiledModelURL = url
    }

    private func defaultModelURL() -> URL? {
        Bundle.main.url(forResource: "HabitCluster", withExtension: "mlmodelc")
    }

    private func updatedModelURL() -> URL {
        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.habitkit.app"
        ) ?? FileManager.default.temporaryDirectory
        return container.appendingPathComponent("HabitCluster_updated.mlmodelc")
    }
}

// MARK: - HabitCluster

/// The cluster that a habit's completion pattern falls into.
public enum HabitCluster: Int, Sendable {
    /// Morning routines, high consistency.
    case morningConsistent = 0
    /// Evening routines, moderate consistency.
    case eveningModerate = 1
    /// Sporadic completion, low streak.
    case sporadic = 2
    /// Recently started, trend improving.
    case improving = 3
    /// High completion rate but declining streak.
    case declining = 4
}
