import AlarmKit
import AppIntents
import Foundation
import SwiftUI

// MARK: - HabitAlarmScheduler

/// Schedules and cancels AlarmKit alarms for habit reminders (iOS 26+).
///
/// AlarmKit's own `AlarmManager` already tracks every alarm by its `UUID`, so
/// this wrapper keeps no state of its own — a habit can have several
/// reminders, each keyed by its own `HabitReminder.id`, which also enforces
/// "at most one active alarm per reminder" for free.
public enum HabitAlarmScheduler {

    /// Requests AlarmKit authorization if it hasn't been determined yet.
    @discardableResult
    public static func requestAuthorizationIfNeeded() async throws -> Bool {
        let manager = AlarmKit.AlarmManager.shared
        if manager.authorizationState == .authorized { return true }
        let state = try await manager.requestAuthorization()
        return state == .authorized
    }

    /// Schedules (or replaces) a single reminder's alarm.
    ///
    /// - Parameters:
    ///   - id: The `HabitReminder.id` to alarm for; doubles as the AlarmKit alarm id.
    ///   - habitID: The habit the reminder belongs to, carried in the alarm's metadata.
    ///   - habitName: User-visible title shown on the alarm screen.
    ///   - date: The exact date/time at which the alarm fires.
    ///   - tintColor: Color used to tint the alarm's system UI.
    ///   - stopIntent: Runs when the person taps the alarm's stop button.
    ///   - secondaryIntent: Runs when the person taps the alarm's secondary button.
    public static func scheduleAlarm(
        id: UUID,
        habitID: UUID,
        habitName: String,
        at date: Date,
        tintColor: Color,
        stopIntent: (any LiveActivityIntent)? = nil,
        secondaryIntent: (any LiveActivityIntent)? = nil
    ) async throws {
        try await requestAuthorizationIfNeeded()

        let stopButton = AlarmButton(
            text: "Complete",
            textColor: .white,
            systemImageName: "checkmark"
        )
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: habitName),
            stopButton: stopButton
        )
        let attributes = AlarmAttributes<HabitAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: HabitAlarmMetadata(habitID: habitID, habitName: habitName),
            tintColor: tintColor
        )
        let configuration = AlarmKit.AlarmManager.AlarmConfiguration<HabitAlarmMetadata>.alarm(
            schedule: .fixed(date),
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: secondaryIntent
        )
        _ = try await AlarmKit.AlarmManager.shared.schedule(id: id, configuration: configuration)
    }

    /// Starts (or replaces) a countdown-timer alarm for a live habit session.
    ///
    /// Unlike ``scheduleAlarm``, this drives AlarmKit's own system-managed
    /// Live Activity/Dynamic Island countdown UI — the app doesn't need to
    /// run its own `ActivityKit` activity alongside it.
    ///
    /// - Parameters:
    ///   - id: A session-scoped id (fresh per session, not the habit's own id)
    ///     so an abandoned session's alarm can never collide with a new one.
    ///   - habitID: The habit the session belongs to, carried in the alarm's metadata.
    ///   - habitName: User-visible title shown on the countdown/paused/alert UI.
    ///   - duration: How long the countdown runs, in seconds.
    ///   - tintColor: Color used to tint the alarm's system UI.
    ///   - stopIntent: Runs when the person taps the alarm's stop button once it fires.
    ///   - secondaryIntent: Runs when the person taps the alarm's secondary button.
    /// - Returns: The scheduled `Alarm`, already counting down.
    @discardableResult
    public static func startCountdownTimer(
        id: UUID,
        habitID: UUID,
        habitName: String,
        duration: TimeInterval,
        tintColor: Color,
        stopIntent: (any LiveActivityIntent)? = nil,
        secondaryIntent: (any LiveActivityIntent)? = nil
    ) async throws -> Alarm {
        try await requestAuthorizationIfNeeded()

        let stopButton = AlarmButton(text: "Complete", textColor: .white, systemImageName: "checkmark")
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: habitName),
            stopButton: stopButton
        )
        let pauseButton = AlarmButton(text: "Pause", textColor: .white, systemImageName: "pause.fill")
        let resumeButton = AlarmButton(text: "Resume", textColor: .white, systemImageName: "play.fill")
        let countdown = AlarmPresentation.Countdown(
            title: LocalizedStringResource(stringLiteral: habitName),
            pauseButton: pauseButton
        )
        let paused = AlarmPresentation.Paused(
            title: LocalizedStringResource(stringLiteral: habitName),
            resumeButton: resumeButton
        )
        let attributes = AlarmAttributes<HabitAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert, countdown: countdown, paused: paused),
            metadata: HabitAlarmMetadata(habitID: habitID, habitName: habitName),
            tintColor: tintColor
        )
        let configuration = AlarmKit.AlarmManager.AlarmConfiguration<HabitAlarmMetadata>.timer(
            duration: duration,
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: secondaryIntent
        )
        return try await AlarmKit.AlarmManager.shared.schedule(id: id, configuration: configuration)
    }

    /// Pauses a running countdown timer.
    public static func pauseCountdown(for id: UUID) throws {
        try AlarmKit.AlarmManager.shared.pause(id: id)
    }

    /// Resumes a paused countdown timer.
    public static func resumeCountdown(for id: UUID) throws {
        try AlarmKit.AlarmManager.shared.resume(id: id)
    }

    /// Cancels a single reminder's alarm if one exists.
    public static func cancelAlarm(for id: UUID) throws {
        try AlarmKit.AlarmManager.shared.cancel(id: id)
    }

    /// Stops an alarm that is currently alerting, equivalent to tapping its
    /// stop button. Used by the in-app fallback UI, since AlarmKit's system
    /// alert does not present while the app itself is in the foreground.
    public static func stopAlarm(for id: UUID) throws {
        try AlarmKit.AlarmManager.shared.stop(id: id)
    }

    /// Cancels all active alarms managed by HabitKit.
    public static func cancelAllAlarms() throws {
        for alarm in try AlarmKit.AlarmManager.shared.alarms {
            try AlarmKit.AlarmManager.shared.cancel(id: alarm.id)
        }
    }
}

// MARK: - HabitAlarmMetadata

/// Metadata attached to a HabitKit alarm, visible to the alarm's Live Activity UI.
public struct HabitAlarmMetadata: AlarmMetadata {
    public var habitID: UUID
    public var habitName: String

    public init(habitID: UUID, habitName: String) {
        self.habitID = habitID
        self.habitName = habitName
    }
}
