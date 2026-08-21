import Foundation

/// Persists today's skipped habit IDs in the shared App Group `UserDefaults`.
///
/// Skips are stored per calendar day so they expire naturally at midnight.
enum SkipStore {
    private static let suiteName = "group.com.habitkit.app"

    private static func key(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "hk_skipped_\(formatter.string(from: date))"
    }

    /// Returns the set of habit ID strings skipped today.
    static func skippedTodayIDs() -> Set<String> {
        let ids = UserDefaults(suiteName: suiteName)?.stringArray(forKey: key()) ?? []
        return Set(ids)
    }

    /// Records a habit as skipped for today.
    static func skip(habitID: UUID) {
        let defaults = UserDefaults(suiteName: suiteName)
        var ids = defaults?.stringArray(forKey: key()) ?? []
        let str = habitID.uuidString
        guard !ids.contains(str) else { return }
        ids.append(str)
        defaults?.set(ids, forKey: key())
    }
}
