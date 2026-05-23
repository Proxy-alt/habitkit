import Foundation
import IdentityLookup

// MARK: - HabitMessageFilter (§8.33)

/// An `ILMessageFilterExtension` that filters SMS messages related to Focus
/// modes linked to HabitKit habits.
///
/// When a Focus Mode with "silence notifications" is active, HabitKit's
/// message filter extension can suppress SMS messages from known habit-related
/// senders (e.g. gym class confirmation SMSs) so they do not disturb the
/// user's Focus session.
///
/// This class is the entry point for the `HabitMessageFilter` extension target.
public final class HabitMessageFilter: ILMessageFilterExtension {}

// MARK: - ILMessageFilterQueryHandling

extension HabitMessageFilter: ILMessageFilterQueryHandling {

    public func handle(
        _ queryRequest: ILMessageFilterQueryRequest,
        context: ILMessageFilterExtensionContext,
        completion: @escaping (ILMessageFilterQueryResponse) -> Void
    ) {
        let response = ILMessageFilterQueryResponse()

        guard let sender = queryRequest.sender,
              let messageBody = queryRequest.messageBody else {
            response.action = .none
            completion(response)
            return
        }

        // Load the list of suppressed senders written by the main app.
        let suppressedSenders = loadSuppressedSenders()
        let lowercasedSender = sender.lowercased()

        // Check sender list first.
        if suppressedSenders.contains(where: { lowercasedSender.contains($0) }) {
            response.action = .filter
            completion(response)
            return
        }

        // Check message body for habit keywords that suggest it is a scheduling
        // message for a linked habit category (e.g. "class confirmed", "booking").
        let habitKeywords = loadHabitKeywords()
        let lowercasedBody = messageBody.lowercased()
        let matchesKeyword = habitKeywords.contains { lowercasedBody.contains($0) }

        response.action = matchesKeyword ? .filter : .none
        completion(response)
    }

    // MARK: - Private helpers

    private func loadSuppressedSenders() -> [String] {
        let defaults = UserDefaults(suiteName: "group.com.habitkit.app")
        return defaults?.stringArray(forKey: "filter.suppressedSenders") ?? []
    }

    private func loadHabitKeywords() -> [String] {
        let defaults = UserDefaults(suiteName: "group.com.habitkit.app")
        return defaults?.stringArray(forKey: "filter.habitKeywords") ?? [
            "class confirmed",
            "booking confirmed",
            "appointment reminder",
            "gym session",
            "workout reminder",
        ]
    }
}

// MARK: - HabitMessageFilterManager

/// Main-app API for configuring the message filter extension.
public enum HabitMessageFilterManager {

    /// Adds a sender to the suppressed-senders list read by the extension.
    ///
    /// - Parameter sender: Partial sender string (e.g. "GymCo", "+447700").
    public static func suppressSender(_ sender: String) {
        let defaults = UserDefaults(suiteName: "group.com.habitkit.app")
        var current = defaults?.stringArray(forKey: "filter.suppressedSenders") ?? []
        let lowercased = sender.lowercased()
        if !current.contains(lowercased) {
            current.append(lowercased)
        }
        defaults?.set(current, forKey: "filter.suppressedSenders")
    }

    /// Removes a sender from the suppressed list.
    ///
    /// - Parameter sender: The sender string to remove.
    public static func unsuppressSender(_ sender: String) {
        let defaults = UserDefaults(suiteName: "group.com.habitkit.app")
        var current = defaults?.stringArray(forKey: "filter.suppressedSenders") ?? []
        current.removeAll { $0 == sender.lowercased() }
        defaults?.set(current, forKey: "filter.suppressedSenders")
    }

    /// Updates the keyword list used for body-text filtering.
    ///
    /// - Parameter keywords: New set of lowercase keywords.
    public static func updateKeywords(_ keywords: [String]) {
        let defaults = UserDefaults(suiteName: "group.com.habitkit.app")
        defaults?.set(keywords.map { $0.lowercased() }, forKey: "filter.habitKeywords")
    }
}
