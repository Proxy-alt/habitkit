import Foundation
import MetricKit

// MARK: - MetricKitSubscriber

/// Subscribes to MetricKit payloads and surfaces performance data in
/// HabitKit's on-device diagnostic dashboard (§8.27).
///
/// MXMetricManager delivers payloads once per day. The subscriber stores
/// the most recent payload in `UserDefaults` (app group) so the Settings
/// screen can display memory, CPU, and launch-time metrics without
/// the user needing to send data anywhere.
public final class MetricKitSubscriber: NSObject, MXMetricManagerSubscriber, Sendable {

    // MARK: - Shared instance

    public static let shared = MetricKitSubscriber()

    // MARK: - UserDefaults keys

    private static let latestMetricsKey = "metrickit.latestSummary"

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Subscription management

    /// Registers the subscriber with `MXMetricManager`.
    ///
    /// Call once at app launch.
    public func subscribe() {
        MXMetricManager.shared.add(self)
    }

    /// Removes the subscriber from `MXMetricManager`.
    public func unsubscribe() {
        MXMetricManager.shared.remove(self)
    }

    // MARK: - MXMetricManagerSubscriber

    public func didReceive(_ payloads: [MXMetricPayload]) {
        guard let payload = payloads.last else { return }
        let summary = MetricSummary(from: payload)
        let defaults = UserDefaults(suiteName: "group.com.habitkit.app")
        if let data = try? JSONEncoder().encode(summary) {
            defaults?.set(data, forKey: Self.latestMetricsKey)
        }
    }

    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        // Diagnostic payloads (crashes, hang reports) are stored separately.
        guard let payload = payloads.last,
              let data = try? payload.jsonRepresentation() else { return }
        let defaults = UserDefaults(suiteName: "group.com.habitkit.app")
        defaults?.set(data, forKey: "metrickit.latestDiagnostic")
    }

    // MARK: - Reading metrics

    /// Returns the most recently received `MetricSummary`, if available.
    public static func latestSummary() -> MetricSummary? {
        let defaults = UserDefaults(suiteName: "group.com.habitkit.app")
        guard let data = defaults?.data(forKey: latestMetricsKey) else { return nil }
        return try? JSONDecoder().decode(MetricSummary.self, from: data)
    }
}

// MARK: - MetricSummary

/// A Codable summary of the most recent MetricKit payload.
public struct MetricSummary: Codable, Sendable {
    /// Average app launch time in milliseconds.
    public var averageLaunchTimeMs: Double

    /// Average CPU time used per session in milliseconds.
    public var averageCPUTimeMs: Double

    /// Peak memory usage in megabytes.
    public var peakMemoryMB: Double

    /// Number of app hangs recorded in the reporting period.
    public var hangCount: Int

    /// Date this summary was generated.
    public var generatedAt: Date

    public init(
        averageLaunchTimeMs: Double,
        averageCPUTimeMs: Double,
        peakMemoryMB: Double,
        hangCount: Int,
        generatedAt: Date = Date()
    ) {
        self.averageLaunchTimeMs = averageLaunchTimeMs
        self.averageCPUTimeMs = averageCPUTimeMs
        self.peakMemoryMB = peakMemoryMB
        self.hangCount = hangCount
        self.generatedAt = generatedAt
    }

    init(from payload: MXMetricPayload) {
        let launchMetrics = payload.applicationLaunchMetrics
        averageLaunchTimeMs = launchMetrics?.histogrammedTimeToFirstDraw.bucketEnumerator
            .compactMap { $0 as? MXHistogramBucket<UnitDuration> }
            .first
            .map { $0.bucketStart.converted(to: .milliseconds).value } ?? 0

        let cpuMetrics = payload.cpuMetrics
        averageCPUTimeMs = cpuMetrics?.cumulativeCPUTime.converted(to: .milliseconds).value ?? 0

        let memMetrics = payload.memoryMetrics
        peakMemoryMB = memMetrics?.peakMemoryUsage.converted(to: .megabytes).value ?? 0

        hangCount = payload.applicationResponsivenessMetrics?.histogrammedAppHangTime
            .bucketEnumerator
            .allObjects
            .count ?? 0

        generatedAt = Date()
    }
}
