import EventKit
import Foundation

// MARK: - CalendarManager

/// Integrates HabitKit with EventKit for two-way habit ↔ calendar sync (§8.16).
///
/// Habits can optionally be backed by a calendar event. The manager creates
/// a dedicated "HabitKit" calendar on first use, keeps events in sync with
/// the habit schedule, and detects "busy day" conditions by counting the
/// number of events on a given day.
public actor CalendarManager {

    // MARK: - Shared instance

    public static let shared = CalendarManager()

    // MARK: - Private state

    private let store = EKEventStore()
    private var habitKitCalendar: EKCalendar?

    /// Name of the calendar created by HabitKit.
    private static let calendarTitle = "HabitKit"

    // MARK: - Init

    private init() {}

    // MARK: - Authorization

    /// Requests EventKit write access for events.
    ///
    /// - Returns: `true` if access was granted.
    @discardableResult
    public func requestAuthorization() async throws -> Bool {
        try await store.requestWriteOnlyAccessToEvents()
    }

    // MARK: - Calendar management

    /// Returns (or creates) the dedicated HabitKit calendar.
    ///
    /// - Returns: The HabitKit `EKCalendar`.
    public func habitCalendar() throws -> EKCalendar {
        if let existing = habitKitCalendar { return existing }

        // Look for an existing HabitKit calendar.
        if let found = store.calendars(for: .event).first(where: { $0.title == Self.calendarTitle }) {
            habitKitCalendar = found
            return found
        }

        // Create a new one.
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = Self.calendarTitle
        calendar.cgColor = CGColor(srgbRed: 0.6, green: 0.4, blue: 1.0, alpha: 1.0)
        if let source = store.defaultCalendarForNewEvents?.source {
            calendar.source = source
        }
        try store.saveCalendar(calendar, commit: true)
        habitKitCalendar = calendar
        return calendar
    }

    // MARK: - Event sync

    /// Creates or updates a calendar event representing a habit completion.
    ///
    /// - Parameters:
    ///   - habitName: The habit's display name (used as the event title).
    ///   - date: The date of the completion (event spans the full day).
    ///   - eventID: Optional existing EKEvent identifier to update instead of create.
    /// - Returns: The `EKEvent.eventIdentifier` of the created/updated event.
    @discardableResult
    public func syncCompletion(
        habitName: String,
        date: Date,
        existingEventID: String? = nil
    ) async throws -> String {
        let calendar = try habitCalendar()

        let event: EKEvent
        if let existingID = existingEventID,
           let existing = store.event(withIdentifier: existingID) {
            event = existing
        } else {
            event = EKEvent(eventStore: store)
        }

        event.title = "✓ \(habitName)"
        event.isAllDay = true
        event.startDate = Calendar.current.startOfDay(for: date)
        event.endDate = event.startDate
        event.calendar = calendar
        event.notes = "Logged via HabitKit"

        try store.save(event, span: .thisEvent, commit: true)
        return event.eventIdentifier
    }

    /// Removes a previously synced calendar event.
    ///
    /// - Parameter eventID: The `EKEvent.eventIdentifier` to remove.
    public func removeEvent(eventID: String) throws {
        guard let event = store.event(withIdentifier: eventID) else { return }
        try store.remove(event, span: .thisEvent, commit: true)
    }

    // MARK: - Busy day detection

    /// Returns `true` if the given day has more than `threshold` calendar events.
    ///
    /// Used by `GetDailyHabitSummaryIntent` to tag missed habits as
    /// "environmental miss (busy day)".
    ///
    /// - Parameters:
    ///   - date: The day to examine.
    ///   - threshold: Number of events considered "busy" (default 4).
    /// - Returns: Whether the day is considered busy.
    public func isBusyDay(_ date: Date, threshold: Int = 4) -> Bool {
        let start = Calendar.current.startOfDay(for: date)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else {
            return false
        }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = store.events(matching: predicate)
        return events.count >= threshold
    }
}
