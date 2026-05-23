import Foundation

// MARK: - EnergyScheduler

/// Integrates with the iOS ElectricityGuidance API to schedule high-power
/// domestic habits during low-carbon or off-peak grid periods (§8.40).
///
/// HabitKit uses `ElectricityGuidance` (iOS 26) to check the local grid's
/// carbon intensity and suggest optimal windows for power-consuming habits
/// like "charge EV" or "run dishwasher".
public actor EnergyScheduler {

    // MARK: - Shared instance

    public static let shared = EnergyScheduler()

    // MARK: - Init

    private init() {}

    // MARK: - Guidance

    /// Returns the recommended next window for a domestic power habit.
    ///
    /// - Parameters:
    ///   - habitName: Display name of the habit (used for user-facing messages).
    ///   - durationMinutes: How long the habit takes (e.g. 60 for a dishwasher cycle).
    ///   - lookaheadHours: How far ahead to search for a low-carbon window.
    /// - Returns: An `EnergyWindow` if a suitable window is found, or `nil`.
    public func recommendedWindow(
        for habitName: String,
        durationMinutes: Int,
        lookaheadHours: Int = 24
    ) async -> EnergyWindow? {
        // ElectricityGuidance is only available in regions with grid data.
        guard let guidance = ElectricityGuidance.shared else { return nil }

        let now = Date()
        guard let lookaheadEnd = Calendar.current.date(
            byAdding: .hour,
            value: lookaheadHours,
            to: now
        ) else { return nil }

        do {
            let windows = try await guidance.lowCarbonWindows(
                from: now,
                to: lookaheadEnd,
                minimumDuration: TimeInterval(durationMinutes * 60)
            )
            guard let best = windows.first else { return nil }
            return EnergyWindow(
                start: best.startDate,
                end: best.endDate,
                carbonIntensityGramsPerKWh: best.carbonIntensity.value
            )
        } catch {
            return nil
        }
    }

    /// Returns the current grid carbon intensity, or `nil` if unavailable.
    public func currentCarbonIntensity() async -> Double? {
        guard let guidance = ElectricityGuidance.shared else { return nil }
        do {
            let intensity = try await guidance.currentCarbonIntensity()
            return intensity.value
        } catch {
            return nil
        }
    }
}

// MARK: - EnergyWindow

/// A recommended low-carbon window for running a domestic habit.
public struct EnergyWindow: Sendable {
    /// Start of the window.
    public var start: Date
    /// End of the window.
    public var end: Date
    /// Estimated grid carbon intensity in grams of CO₂ per kWh.
    public var carbonIntensityGramsPerKWh: Double

    public init(start: Date, end: Date, carbonIntensityGramsPerKWh: Double) {
        self.start = start
        self.end = end
        self.carbonIntensityGramsPerKWh = carbonIntensityGramsPerKWh
    }

    /// The duration of the window in minutes.
    public var durationMinutes: Int {
        Int(end.timeIntervalSince(start) / 60)
    }

    /// Whether the window starts within the next hour.
    public var isImminente: Bool {
        start.timeIntervalSinceNow < 3600
    }
}
