import Foundation
import HabitKitCore

@Observable
@MainActor
final class TodayViewModel {
    private(set) var todayHabits: [Habit] = []
    private(set) var isLoading = false

    var incompleteHabits: [Habit] {
        todayHabits.filter { habit in
            !habit.completions.contains { Calendar.current.isDateInToday($0.completedAt) }
        }
    }

    var completeHabits: [Habit] {
        todayHabits.filter { habit in
            habit.completions.contains { Calendar.current.isDateInToday($0.completedAt) }
        }
    }

    var isAllComplete: Bool { incompleteHabits.isEmpty && !todayHabits.isEmpty }

    var todayTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    func load(from habits: [Habit]) {
        let today = Date()
        todayHabits = habits.filter { !$0.isArchived && $0.schedule.isDue(on: today) }
    }
}
