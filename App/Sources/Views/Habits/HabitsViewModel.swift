import Foundation
import HabitKitCore

@Observable
@MainActor
final class HabitsViewModel {
    var showArchived = false

    func activeHabits(from habits: [Habit]) -> [Habit] {
        habits.filter { !$0.isArchived }
    }

    func archivedHabits(from habits: [Habit]) -> [Habit] {
        habits.filter { $0.isArchived }
    }

    func scheduleDescription(for habit: Habit) -> String {
        switch habit.schedule.frequency {
        case .daily: return "Every day"
        case .weekly(let days):
            let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let sorted = days.sorted().compactMap { names[safe: $0] }
            return sorted.joined(separator: ", ")
        case .interval(let n): return "Every \(n) days"
        case .xTimesPerWeek(let x): return "\(x)× per week"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
