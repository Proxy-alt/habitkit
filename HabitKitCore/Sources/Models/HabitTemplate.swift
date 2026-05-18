import Foundation

// MARK: - HabitType

/// The kind of habit encoded in a template file.
public enum HabitType: String, Codable, Sendable {
    case yesNo
    case timed
    case quantity
    case checklist
    case negative
}

// MARK: - TemplateSchedule

/// Lightweight schedule description stored inside a template file.
public struct TemplateSchedule: Codable, Sendable {
    /// Frequency string that mirrors the `ScheduleFrequency` cases.
    /// Accepted values: "daily", "weekly", "interval", "xTimesPerWeek"
    public var frequency: String

    /// Reminder times expressed as "HH:mm" strings in 24-hour format.
    public var reminderTimes: [String]

    /// Optional supplementary data required by certain frequencies.
    /// For "weekly": comma-separated day integers (e.g. "1,3,5")
    /// For "interval": the number of days between occurrences (e.g. "2")
    /// For "xTimesPerWeek": the target count (e.g. "3")
    public var frequencyDetail: String?

    public init(
        frequency: String,
        reminderTimes: [String] = [],
        frequencyDetail: String? = nil
    ) {
        self.frequency = frequency
        self.reminderTimes = reminderTimes
        self.frequencyDetail = frequencyDetail
    }
}

// MARK: - HabitTemplate

/// Represents a shareable / importable habit definition in the `.habit` JSON format.
public struct HabitTemplate: Codable, Sendable {
    // MARK: Core identity

    /// Human-readable habit name.
    public var name: String

    /// SF Symbol name for the habit icon.
    public var icon: String

    /// Hex color string, e.g. "#FF5733".
    public var colorHex: String

    /// What kind of habit this is.
    public var type: HabitType

    // MARK: Scheduling

    /// How and when the habit should be performed.
    public var schedule: TemplateSchedule

    // MARK: Type-specific fields

    /// For `.timed` habits: target session length in seconds.
    public var targetDurationSeconds: Int?

    /// For `.quantity` habits: the numeric target.
    public var targetQuantity: Double?

    /// For `.quantity` habits: the unit label (e.g. "glasses").
    public var unit: String?

    /// For `.checklist` habits: ordered list of step descriptions.
    public var steps: [String]?

    /// For `.negative` habits: what the user is trying to avoid.
    public var avoidTarget: String?

    // MARK: Metadata

    /// Optional short description shown in the template browser.
    public var templateDescription: String?

    /// Semantic version of this template format, e.g. "1.0".
    public var templateVersion: String

    public init(
        name: String,
        icon: String,
        colorHex: String,
        type: HabitType,
        schedule: TemplateSchedule,
        targetDurationSeconds: Int? = nil,
        targetQuantity: Double? = nil,
        unit: String? = nil,
        steps: [String]? = nil,
        avoidTarget: String? = nil,
        templateDescription: String? = nil,
        templateVersion: String = "1.0"
    ) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.type = type
        self.schedule = schedule
        self.targetDurationSeconds = targetDurationSeconds
        self.targetQuantity = targetQuantity
        self.unit = unit
        self.steps = steps
        self.avoidTarget = avoidTarget
        self.templateDescription = templateDescription
        self.templateVersion = templateVersion
    }

    // MARK: - Coding keys

    private enum CodingKeys: String, CodingKey {
        case name, icon, colorHex, type, schedule
        case targetDurationSeconds, targetQuantity, unit, steps, avoidTarget
        case templateDescription, templateVersion
    }

    // MARK: - Serialisation

    /// Decodes a `HabitTemplate` from raw `.habit` file data (JSON).
    ///
    /// - Parameter data: Raw bytes of a `.habit` JSON file.
    /// - Returns: The decoded template.
    /// - Throws: A `DecodingError` if the data is malformed.
    public static func decode(from data: Data) throws -> HabitTemplate {
        let decoder = JSONDecoder()
        return try decoder.decode(HabitTemplate.self, from: data)
    }

    /// Encodes this template to `.habit` file data (pretty-printed JSON).
    ///
    /// - Returns: UTF-8 encoded JSON data.
    /// - Throws: An `EncodingError` if the template cannot be encoded.
    public func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    // MARK: - Conversion helpers

    /// Converts the template's schedule into a `ScheduleFrequency` value.
    ///
    /// - Returns: The matching `ScheduleFrequency`, or `nil` if the frequency
    ///   string is unrecognised or the required detail is missing.
    public func resolvedFrequency() -> ScheduleFrequency? {
        switch schedule.frequency {
        case "daily":
            return .daily

        case "weekly":
            guard let detail = schedule.frequencyDetail else { return nil }
            let dayInts = detail
                .split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            return .weekly(days: Set(dayInts))

        case "interval":
            guard let detail = schedule.frequencyDetail, let n = Int(detail) else { return nil }
            return .interval(every: n)

        case "xTimesPerWeek":
            guard let detail = schedule.frequencyDetail, let x = Int(detail) else { return nil }
            return .xTimesPerWeek(x: x)

        default:
            return nil
        }
    }
}
