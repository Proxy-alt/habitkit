import Foundation
import JournalingSuggestions

// MARK: - JournalingSuggestionsCoordinator

/// Presents the JournalingSuggestionsPicker after habit milestones (§8.25).
///
/// After a streak milestone (7, 30, 100 days) or when completing all habits
/// for the day, HabitKit can offer the JournalingSuggestionsPicker so the
/// user can add their completion as a journal-worthy moment.
public final class JournalingSuggestionsCoordinator: ObservableObject, Sendable {

    // MARK: - Shared instance

    public static let shared = JournalingSuggestionsCoordinator()

    // MARK: - Published state

    @MainActor @Published public var isPresentingPicker = false
    @MainActor @Published public var selectedSuggestion: JournalingSuggestion?

    // MARK: - Pending context

    @MainActor private var pendingHabitName: String = ""
    @MainActor private var pendingMilestone: MilestoneKind = .allDone

    // MARK: - Init

    private init() {}

    // MARK: - Presentation

    /// Triggers the journaling suggestions picker for a streak milestone.
    ///
    /// - Parameters:
    ///   - habitName: The habit that reached the milestone.
    ///   - streakDays: The number of days in the streak.
    @MainActor
    public func presentForStreakMilestone(habitName: String, streakDays: Int) {
        pendingHabitName = habitName
        pendingMilestone = .streak(days: streakDays)
        isPresentingPicker = true
    }

    /// Triggers the journaling suggestions picker after all habits are done.
    @MainActor
    public func presentForAllHabitsDone() {
        pendingMilestone = .allDone
        isPresentingPicker = true
    }

    // MARK: - Handling selection

    /// Handles the user selecting a journaling suggestion.
    ///
    /// - Parameter suggestion: The `JournalingSuggestion` chosen by the user.
    @MainActor
    public func handleSelection(_ suggestion: JournalingSuggestion) {
        selectedSuggestion = suggestion
        isPresentingPicker = false

        // Post a notification so interested views can present the journal compose UI.
        NotificationCenter.default.post(
            name: .journalSuggestionSelected,
            object: nil,
            userInfo: [
                "suggestion": suggestion,
                "habitName": pendingHabitName,
                "milestone": pendingMilestone.rawValue,
            ]
        )
    }

    /// Called when the user dismisses the picker without selecting.
    @MainActor
    public func handleDismiss() {
        isPresentingPicker = false
    }
}

// MARK: - MilestoneKind

/// The type of habit milestone that triggered the journaling prompt.
public enum MilestoneKind: Sendable {
    case allDone
    case streak(days: Int)

    var rawValue: String {
        switch self {
        case .allDone: return "allDone"
        case .streak(let days): return "streak.\(days)"
        }
    }
}

// MARK: - Notification names

public extension Notification.Name {
    /// Posted when the user selects a journaling suggestion.
    static let journalSuggestionSelected = Notification.Name("com.habitkit.journalSuggestionSelected")
}
