import CoreLocation
import Foundation
import WeatherKit

// MARK: - WeatherContextManager

/// Tags habit completions with weather context using WeatherKit (§8.37).
///
/// After a user completes a habit, HabitKit optionally tags the completion
/// with a `HKWeatherContext` snapshot. This data is used in the analytics
/// view to surface correlations like "you miss running when it rains".
public actor WeatherContextManager {

    // MARK: - Shared instance

    public static let shared = WeatherContextManager()

    // MARK: - Private state

    private let service = WeatherService.shared
    private var cachedContext: (context: HKWeatherContext, expiry: Date)?

    // MARK: - Init

    private init() {}

    // MARK: - Weather context

    /// Returns a `HKWeatherContext` for the current location and time.
    ///
    /// Results are cached for 15 minutes to avoid redundant network requests.
    ///
    /// - Parameter location: The user's current `CLLocation`.
    /// - Returns: A `HKWeatherContext`, or `nil` if WeatherKit is unavailable.
    public func currentContext(at location: CLLocation) async -> HKWeatherContext? {
        // Return cached value if still fresh.
        if let cached = cachedContext, cached.expiry > Date() {
            return cached.context
        }

        do {
            let weather = try await service.weather(for: location)
            let current = weather.currentWeather
            let context = HKWeatherContext(
                conditionRaw: current.condition.description,
                temperatureCelsius: current.temperature.converted(to: .celsius).value,
                uvIndex: Double(current.uvIndex.value),
                windSpeedKph: current.wind.speed.converted(to: .kilometersPerHour).value,
                precipitationChance: weather.hourlyForecast.forecast.first?.precipitationChance ?? 0,
                recordedAt: Date()
            )
            cachedContext = (context, Date().addingTimeInterval(15 * 60))
            return context
        } catch {
            return nil
        }
    }
}

// MARK: - HKWeatherContext

/// A snapshot of weather conditions at the time of a habit completion.
public struct HKWeatherContext: Codable, Sendable {
    /// Raw weather condition description (e.g. "Mostly Clear").
    public var conditionRaw: String

    /// Temperature in degrees Celsius.
    public var temperatureCelsius: Double

    /// UV index value.
    public var uvIndex: Double

    /// Wind speed in km/h.
    public var windSpeedKph: Double

    /// Precipitation chance as a fraction 0.0–1.0.
    public var precipitationChance: Double

    /// When this context was captured.
    public var recordedAt: Date

    // MARK: - Derived properties

    /// Returns `true` if conditions suggest outdoor exercise may be unpleasant.
    public var isAdverseForOutdoors: Bool {
        precipitationChance > 0.6 || windSpeedKph > 50 || temperatureCelsius < -5
    }

    public init(
        conditionRaw: String,
        temperatureCelsius: Double,
        uvIndex: Double,
        windSpeedKph: Double,
        precipitationChance: Double,
        recordedAt: Date
    ) {
        self.conditionRaw = conditionRaw
        self.temperatureCelsius = temperatureCelsius
        self.uvIndex = uvIndex
        self.windSpeedKph = windSpeedKph
        self.precipitationChance = precipitationChance
        self.recordedAt = recordedAt
    }
}
