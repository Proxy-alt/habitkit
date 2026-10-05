import SwiftUI
import HabitNookCore
import HabitNookUI
import NookCore
import NookUI

struct HeatmapView: View {
    let habit: Habit

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 11
    private let cellSpacing: CGFloat = 2
    private let weeks = 52

    private var completionDates: Set<DateComponents> {
        Set(habit.completions.map {
            calendar.dateComponents([.year, .month, .day], from: $0.completedAt)
        })
    }

    private var startDate: Date {
        let weeksAgo = calendar.date(byAdding: .weekOfYear, value: -weeks, to: Date()) ?? Date()
        let weekday = calendar.component(.weekday, from: weeksAgo)
        return calendar.date(byAdding: .day, value: -(weekday - 1), to: weeksAgo) ?? weeksAgo
    }

    private func isCompleted(_ date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return completionDates.contains(components)
    }

    private func cellRole(for date: Date) -> NookColour {
        guard date <= Date() else { return .surface0 }
        return isCompleted(date) ? .primary : .surface1
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: cellSpacing) {
                ForEach(0..<weeks, id: \.self) { week in
                    VStack(spacing: cellSpacing) {
                        ForEach(0..<7, id: \.self) { day in
                            let date = dateFor(week: week, day: day)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.nook(cellRole(for: date)))
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    private func dateFor(week: Int, day: Int) -> Date {
        let daysFromStart = week * 7 + day
        return calendar.date(byAdding: .day, value: daysFromStart, to: startDate) ?? startDate
    }
}
