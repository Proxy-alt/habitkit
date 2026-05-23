import Foundation
import FoundationModels

// MARK: - HabitCoach

/// Uses on-device Foundation Models to generate habit suggestions, tag notes,
/// and produce a weekly coaching summary (§8.10).
///
/// All inference runs on-device via `LanguageModelSession`; no data leaves
/// the device. The session is prewarmed at app launch to minimise first-use
/// latency.
public actor HabitCoach {

    // MARK: - Shared instance

    public static let shared = HabitCoach()

    // MARK: - Private state

    private var session: LanguageModelSession?

    // MARK: - Init

    private init() {}

    // MARK: - Prewarm

    /// Prewarms the language model session so the first real request is fast.
    ///
    /// Call at app launch or `applicationDidBecomeActive`.
    public func prewarm() async {
        guard session == nil else { return }
        let newSession = LanguageModelSession()
        await newSession.prewarm()
        self.session = newSession
    }

    // MARK: - Habit suggestions

    /// Generates a list of new habit suggestions based on the user's existing habits.
    ///
    /// - Parameter existingHabitNames: Names of habits already in the user's library.
    /// - Returns: An array of `HabitSuggestion` structs, or an empty array on failure.
    public func suggestHabits(
        existingHabitNames: [String]
    ) async -> [HabitSuggestion] {
        let session = await getOrCreateSession()
        let existingList = existingHabitNames.joined(separator: ", ")
        let prompt = """
        The user already tracks these habits: \(existingList).
        Suggest 5 complementary habits they might benefit from.
        """
        do {
            let response = try await session.respond(
                to: prompt,
                generating: HabitSuggestionsResponse.self
            )
            return response.suggestions
        } catch {
            return []
        }
    }

    // MARK: - Note tagging

    /// Analyses a completion note and returns relevant tag strings.
    ///
    /// - Parameter note: The raw text note from a habit completion.
    /// - Returns: Up to 5 lowercase tag strings, or an empty array on failure.
    public func tagNote(_ note: String) async -> [String] {
        guard !note.isEmpty else { return [] }
        let session = await getOrCreateSession()
        let prompt = "Analyse this habit completion note and return up to 5 concise lowercase tags: \"\(note)\""
        do {
            let response = try await session.respond(
                to: prompt,
                generating: NoteTagsResponse.self
            )
            return response.tags
        } catch {
            return []
        }
    }

    // MARK: - Weekly summary

    /// Generates a short motivational weekly summary paragraph.
    ///
    /// - Parameters:
    ///   - completionRate: The overall completion percentage this week (0–100).
    ///   - topHabit: The name of the habit with the best streak.
    ///   - missedHabits: Names of habits missed most often this week.
    /// - Returns: A 2–3 sentence motivational paragraph, or an empty string on failure.
    public func weeklyCoachingSummary(
        completionRate: Int,
        topHabit: String,
        missedHabits: [String]
    ) async -> String {
        let session = await getOrCreateSession()
        let missed = missedHabits.isEmpty ? "none" : missedHabits.joined(separator: ", ")
        let prompt = """
        Write a 2-3 sentence motivational weekly habit summary.
        Overall completion rate: \(completionRate)%.
        Best performing habit: \(topHabit).
        Most-missed habits: \(missed).
        Tone: encouraging, specific, brief.
        """
        do {
            let response = try await session.respond(
                to: prompt,
                generating: WeeklySummaryResponse.self
            )
            return response.summary
        } catch {
            return ""
        }
    }

    // MARK: - Private

    private func getOrCreateSession() async -> LanguageModelSession {
        if let existing = session { return existing }
        let newSession = LanguageModelSession()
        self.session = newSession
        return newSession
    }
}

// MARK: - Generable response types

/// Guided-generation response for habit suggestions.
@Generable
public struct HabitSuggestionsResponse: Sendable {
    /// Array of suggested habits.
    @Guide(description: "List of habit suggestions", .count(5))
    public var suggestions: [HabitSuggestion]
}

/// A single AI-generated habit suggestion.
@Generable
public struct HabitSuggestion: Sendable {
    /// Short habit name (3–6 words).
    @Guide(description: "Short habit name", .maximumCount(6))
    public var name: String

    /// One-sentence rationale for the suggestion.
    @Guide(description: "Why this habit complements the user's existing habits")
    public var rationale: String

    /// Suggested SF Symbol name.
    @Guide(description: "SF Symbol identifier for this habit's icon")
    public var sfSymbol: String
}

/// Guided-generation response for note tags.
@Generable
private struct NoteTagsResponse: Sendable {
    /// Up to 5 lowercase tag strings.
    @Guide(description: "Lowercase tags extracted from the note", .count(1...5))
    var tags: [String]
}

/// Guided-generation response for the weekly summary.
@Generable
private struct WeeklySummaryResponse: Sendable {
    /// 2–3 sentence motivational summary.
    @Guide(description: "Motivational weekly summary paragraph")
    var summary: String
}
