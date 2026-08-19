import Foundation
import SwiftData

// MARK: - ProgressionPlan

/// Defines how a habit's target evolves over time via scheduled increments
/// and/or CoreML-driven nudges.
///
/// A `nil` `progressionPlan` on a `Habit` means the target is fixed.
@Model
public class ProgressionPlan {

    /// The target value at the moment the plan was created.
    public var baseTarget: Double

    /// The currently active target used for completion evaluation.
    public var currentTarget: Double

    /// The step size applied at each scheduled increment.
    public var incrementValue: Double

    /// How often (in days) a scheduled increment fires. 28 = monthly.
    public var incrementIntervalDays: Int

    /// The next date a scheduled increment is due. `nil` if no auto-schedule.
    public var nextScheduledIncrease: Date?

    /// When `true`, the CoreML clustering model may surface nudge suggestions.
    /// Opt-in per habit; default `true`.
    public var coreMLNudgesEnabled: Bool

    /// The model will not suggest a target below this floor. `nil` = no floor.
    public var minimumTarget: Double?

    /// The model will not suggest a target above this ceiling. `nil` = no ceiling.
    public var maximumTarget: Double?

    /// Full history of target changes, ordered oldest-first.
    @Relationship(deleteRule: .cascade)
    public var history: [ProgressionEvent]

    /// The habit this plan belongs to.
    public var habit: Habit

    public init(
        baseTarget: Double,
        currentTarget: Double,
        incrementValue: Double = 0,
        incrementIntervalDays: Int = 0,
        nextScheduledIncrease: Date? = nil,
        coreMLNudgesEnabled: Bool = true,
        minimumTarget: Double? = nil,
        maximumTarget: Double? = nil,
        history: [ProgressionEvent] = [],
        habit: Habit
    ) {
        self.baseTarget = baseTarget
        self.currentTarget = currentTarget
        self.incrementValue = incrementValue
        self.incrementIntervalDays = incrementIntervalDays
        self.nextScheduledIncrease = nextScheduledIncrease
        self.coreMLNudgesEnabled = coreMLNudgesEnabled
        self.minimumTarget = minimumTarget
        self.maximumTarget = maximumTarget
        self.history = history
        self.habit = habit
    }
}

// MARK: - ProgressionEvent

/// Records a single change to a `ProgressionPlan`'s target value.
@Model
public class ProgressionEvent {

    /// When the change occurred.
    public var date: Date

    /// The target before the change.
    public var previousTarget: Double

    /// The target after the change.
    public var newTarget: Double

    /// Raw storage for the `ProgressionSource` enum.
    public var sourceRaw: String

    /// The mechanism that triggered the change.
    public var source: ProgressionSource {
        get { ProgressionSource(rawValue: sourceRaw) ?? .userInitiated }
        set { sourceRaw = newValue.rawValue }
    }

    /// The Foundation Models–generated rationale for CoreML-driven changes;
    /// `nil` for scheduled or user-initiated changes.
    public var nudgeRationale: String?

    public init(
        date: Date = Date(),
        previousTarget: Double,
        newTarget: Double,
        source: ProgressionSource,
        nudgeRationale: String? = nil
    ) {
        self.date = date
        self.previousTarget = previousTarget
        self.newTarget = newTarget
        self.sourceRaw = source.rawValue
        self.nudgeRationale = nudgeRationale
    }
}

// MARK: - ProgressionSource

/// Identifies what triggered a `ProgressionEvent`.
public enum ProgressionSource: String, Codable, Sendable {
    /// An automatic increment from the plan's schedule.
    case scheduled
    /// The user manually changed the target.
    case userInitiated
    /// The user accepted a CoreML nudge suggestion.
    case coreMLAccepted
    /// The user dismissed a CoreML nudge at the banner.
    case coreMLDismissed
    /// The user completed the two-tap loosen confirmation flow (negative habits).
    case coreMLLoosenConfirmed
    /// The user reached the second confirmation tap but cancelled.
    case coreMLLoosenCancelled
}

// MARK: - NegativeProgressionPlan

/// A progression plan specialised for negative (avoidance) habits.
///
/// The target represents a *ceiling* — the maximum allowed quantity.
/// Progression always moves toward restriction: the ceiling lowers over time.
/// Loosening the threshold requires a higher CoreML confidence threshold and
/// a mandatory two-tap confirmation flow.
@available(iOS 26.0, macOS 26.0, watchOS 26.0, *)
@Model
public class NegativeProgressionPlan: ProgressionPlan {

    /// Y-axis: the time window in minutes during which the threshold applies.
    /// `nil` = per-day (default).
    public var timeWindowMinutes: Int?

    /// Hour component of the optional time window start (e.g. 18 for 6pm).
    public var timeWindowStartHour: Int?

    /// Minute component of the optional time window start.
    public var timeWindowStartMinute: Int?

    /// Hour component of the optional time window end.
    public var timeWindowEndHour: Int?

    /// Minute component of the optional time window end.
    public var timeWindowEndMinute: Int?

    /// Minimum CoreML confidence to suggest tightening the threshold.
    /// Default 0.65 — suggest restriction readily.
    public var coreMLTightenConfidence: Float

    /// Minimum CoreML confidence to suggest loosening the threshold.
    /// Default 0.90 — require strong sustained evidence.
    public var coreMLLoosenConfidence: Float

    /// Loosening always requires deliberate two-tap confirmation.
    /// This property is a read-only audit marker — it is not configurable.
    public var requireConfirmationToLoosen: Bool { true }

    public init(
        baseTarget: Double,
        currentTarget: Double,
        incrementValue: Double = 0,
        incrementIntervalDays: Int = 0,
        nextScheduledIncrease: Date? = nil,
        coreMLNudgesEnabled: Bool = true,
        minimumTarget: Double? = nil,
        maximumTarget: Double? = nil,
        history: [ProgressionEvent] = [],
        habit: Habit,
        timeWindowMinutes: Int? = nil,
        timeWindowStartHour: Int? = nil,
        timeWindowStartMinute: Int? = nil,
        timeWindowEndHour: Int? = nil,
        timeWindowEndMinute: Int? = nil,
        coreMLTightenConfidence: Float = 0.65,
        coreMLLoosenConfidence: Float = 0.90
    ) {
        self.timeWindowMinutes = timeWindowMinutes
        self.timeWindowStartHour = timeWindowStartHour
        self.timeWindowStartMinute = timeWindowStartMinute
        self.timeWindowEndHour = timeWindowEndHour
        self.timeWindowEndMinute = timeWindowEndMinute
        self.coreMLTightenConfidence = coreMLTightenConfidence
        self.coreMLLoosenConfidence = coreMLLoosenConfidence
        super.init(
            baseTarget: baseTarget,
            currentTarget: currentTarget,
            incrementValue: incrementValue,
            incrementIntervalDays: incrementIntervalDays,
            nextScheduledIncrease: nextScheduledIncrease,
            coreMLNudgesEnabled: coreMLNudgesEnabled,
            minimumTarget: minimumTarget,
            maximumTarget: maximumTarget,
            history: history,
            habit: habit
        )
    }
}
