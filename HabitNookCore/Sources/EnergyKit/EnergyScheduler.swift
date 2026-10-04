import EnergyKit
import Foundation

// MARK: - EnergyScheduler

/// Integrates with the iOS EnergyKit `ElectricityGuidance` API to schedule
/// high-power domestic habits during low-carbon or off-peak grid periods (§8.40).
///
/// `ElectricityGuidance.sharedService.guidance(using:at:)` returns a live
/// `AsyncSequence` of guidance updates scoped to an `EnergyVenue` (the user's
/// home, resolved via `EnergyVenue.venues()`) — not a one-shot query. This
/// scheduler takes the first emitted update and picks the best-rated window
/// from it, since HabitNook only needs a point-in-time recommendation.
public actor EnergyScheduler {

    // MARK: - Shared instance

    public static let shared = EnergyScheduler()

    // MARK: - Init

    private init() {}

    // MARK: - Venues

    /// Returns the energy venues (e.g. the user's home) available for guidance queries.
    @available(iOS 26.1, *)
    public func availableVenues() async -> [EnergyVenue] {
        (try? await EnergyVenue.venues()) ?? []
    }

    // MARK: - Guidance

    /// Returns the recommended next window for a domestic power habit at the given venue.
    ///
    /// - Parameters:
    ///   - habitName: Display name of the habit (used for user-facing messages).
    ///   - durationMinutes: How long the habit takes (e.g. 60 for a dishwasher cycle).
    ///   - lookaheadHours: How far ahead to search for a low-carbon window.
    ///   - venueID: The `EnergyVenue` to request guidance for.
    /// - Returns: An `EnergyWindow` if a suitable window is found, or `nil`.
    public func recommendedWindow(
        for habitName: String,
        durationMinutes: Int,
        lookaheadHours: Int = 24,
        venueID: UUID
    ) async -> EnergyWindow? {
        let now = Date()
        guard let lookaheadEnd = Calendar.current.date(
            byAdding: .hour,
            value: lookaheadHours,
            to: now
        ) else { return nil }

        let query = ElectricityGuidance.Query(suggestedAction: .shift)
        let minimumDuration = TimeInterval(durationMinutes * 60)

        do {
            for try await guidance in ElectricityGuidance.sharedService.guidance(using: query, at: venueID) {
                let best = guidance.values
                    .filter { $0.interval.start >= now && $0.interval.end <= lookaheadEnd }
                    .filter { $0.interval.duration >= minimumDuration }
                    .max { $0.rating < $1.rating }
                guard let best else { return nil }
                return EnergyWindow(start: best.interval.start, end: best.interval.end, cleanlinessRating: best.rating)
            }
        } catch {
            return nil
        }
        return nil
    }

    /// Returns the current grid cleanliness rating at the given venue, or `nil` if unavailable.
    public func currentRating(venueID: UUID) async -> Double? {
        let now = Date()
        let query = ElectricityGuidance.Query(suggestedAction: .shift)

        do {
            for try await guidance in ElectricityGuidance.sharedService.guidance(using: query, at: venueID) {
                return guidance.values.first { $0.interval.contains(now) }?.rating
            }
        } catch {
            return nil
        }
        return nil
    }
}

// MARK: - EnergyWindow

/// A recommended low-carbon window for running a domestic habit.
public struct EnergyWindow: Sendable {
    /// Start of the window.
    public var start: Date
    /// End of the window.
    public var end: Date
    /// Relative grid cleanliness rating from `ElectricityGuidance.Value` — higher is
    /// cleaner. Unitless: the API does not expose an absolute grams-CO₂/kWh figure.
    public var cleanlinessRating: Double

    public init(start: Date, end: Date, cleanlinessRating: Double) {
        self.start = start
        self.end = end
        self.cleanlinessRating = cleanlinessRating
    }

    /// The duration of the window in minutes.
    public var durationMinutes: Int {
        Int(end.timeIntervalSince(start) / 60)
    }

    /// Whether the window starts within the next hour.
    public var isImminent: Bool {
        start.timeIntervalSinceNow < 3600
    }
}
