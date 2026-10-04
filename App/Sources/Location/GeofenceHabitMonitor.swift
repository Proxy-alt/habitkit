import CoreLocation
import Foundation
import HabitNookCore
import SwiftData
import SwiftUI

/// Registers `CLMonitor` geofences for habits that opt in via
/// `HabitSchedule.geofence`, and automatically records a completion when the
/// user enters one.
@Observable
@MainActor
final class GeofenceHabitMonitor {
    private var modelContainer: ModelContainer?
    private var isMonitoring = false

    /// Stores the model container and starts the long-lived `CLMonitor` event
    /// loop. Safe to call once at app launch.
    func start(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        Task { await registerAllGeofences() }

        guard !isMonitoring else { return }
        isMonitoring = true
        Task { await LocationManager.shared.startMonitoring() }
    }

    /// Registers (or re-registers) the geofence for every habit that
    /// currently has one configured. Call again after any habit's
    /// `schedule.geofence` changes.
    func registerAllGeofences() async {
        guard let modelContainer else { return }
        let context = ModelContext(modelContainer)
        guard let habits = try? context.fetch(FetchDescriptor<Habit>()) else { return }

        var requestedAuthorization = false
        for habit in habits {
            guard let geofence = habit.schedule.geofence else { continue }

            if !requestedAuthorization {
                await LocationManager.shared.requestAuthorization()
                requestedAuthorization = true
            }

            let habitID = habit.id
            try? await LocationManager.shared.addGeofence(
                for: habitID,
                coordinate: CLLocationCoordinate2D(latitude: geofence.latitude, longitude: geofence.longitude),
                radiusMeters: geofence.radiusMeters
            ) { [weak self] in
                await self?.handleEntry(habitID: habitID)
            }
        }
    }

    /// Removes the geofence for a habit. Call when the user disables it.
    func removeGeofence(for habitID: UUID) async {
        await LocationManager.shared.removeGeofence(for: habitID)
    }

    // MARK: - Private

    private func handleEntry(habitID: UUID) async {
        guard let modelContainer else { return }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.id == habitID })
        guard let habit = try? context.fetch(descriptor).first else { return }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        guard !habit.completions.contains(where: { $0.completedAt >= startOfDay }) else { return }

        let completion = HabitCompletion(completedAt: Date(), habit: habit)
        context.insert(completion)
        habit.completions.append(completion)
        try? context.save()
    }
}
