import CoreLocation
import Foundation

// MARK: - LocationManager

/// Monitors geofence regions for location-triggered habit completion (§8.8).
///
/// Uses `CLMonitor` (iOS 17+) to observe entry/exit of circular geofence
/// regions. Each habit can register a single geofence; crossing its boundary
/// automatically triggers a completion log via `onEntry`.
public actor LocationManager: NSObject {

    // MARK: - Shared instance

    public static let shared = LocationManager()

    // MARK: - Private state

    private var monitor: CLMonitor?
    private var onEntryHandlers: [String: @Sendable () async -> Void] = [:]

    // MARK: - Init

    private override init() {}

    // MARK: - Authorization

    /// Requests When-In-Use location authorization.
    ///
    /// Full accuracy is required for precise geofence delivery.
    public func requestAuthorization() async {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Geofence management

    /// Registers a circular geofence for a habit.
    ///
    /// - Parameters:
    ///   - habitID: Unique identifier for the habit — used as the region identifier.
    ///   - coordinate: The centre of the geofence region.
    ///   - radiusMeters: The radius in metres (clamped to 50–1000 m).
    ///   - onEntry: Called when the device enters the geofence.
    public func addGeofence(
        for habitID: UUID,
        coordinate: CLLocationCoordinate2D,
        radiusMeters: CLLocationDistance,
        onEntry: @Sendable @escaping () async -> Void
    ) async throws {
        let clampedRadius = min(max(radiusMeters, 50), 1000)
        let identifier = habitID.uuidString

        let monitor = try await getOrCreateMonitor()
        let condition = CLMonitor.CircularGeographicCondition(
            center: coordinate,
            radius: clampedRadius
        )
        await monitor.add(condition, identifier: identifier)
        onEntryHandlers[identifier] = onEntry
    }

    /// Removes the geofence registered for the given habit.
    ///
    /// - Parameter habitID: The habit whose geofence should be removed.
    public func removeGeofence(for habitID: UUID) async {
        let identifier = habitID.uuidString
        if let monitor {
            await monitor.remove(identifier)
        }
        onEntryHandlers.removeValue(forKey: identifier)
    }

    // MARK: - Event processing

    /// Processes a `CLMonitor.Event` and calls the corresponding entry handler.
    ///
    /// Call this from the `CLMonitor.events` async sequence consumer.
    ///
    /// - Parameter event: The event emitted by `CLMonitor`.
    public func handleEvent(_ event: CLMonitor.Event) async {
        guard event.state == .satisfied,
              let handler = onEntryHandlers[event.identifier] else { return }
        await handler()
    }

    /// Starts the internal event-processing loop for `CLMonitor`.
    ///
    /// This runs indefinitely until cancelled. Call from a long-lived `Task`.
    public func startMonitoring() async {
        guard let monitor = try? await getOrCreateMonitor() else { return }
        do {
            for try await event in await monitor.events {
                await handleEvent(event)
            }
        } catch {
            // Event stream terminated; nothing further to process.
        }
    }

    // MARK: - Private

    private func getOrCreateMonitor() async throws -> CLMonitor {
        if let existing = monitor { return existing }
        let newMonitor = await CLMonitor("com.habitkit.geofence")
        self.monitor = newMonitor
        return newMonitor
    }
}
