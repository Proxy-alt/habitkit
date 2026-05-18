import SwiftUI
import SwiftData
import HabitKitCore
import HabitKitUI

struct TodayView: View {
    @Environment(HKThemeManager.self) private var themes
    @Query private var habits: [Habit]
    @State private var showAddHabit = false

    private var todayHabits: [Habit] {
        let today = Date()
        return habits.filter { !$0.isArchived && $0.schedule.isDue(on: today) }
    }

    private var incomplete: [Habit] {
        todayHabits.filter { habit in
            !habit.completions.contains { Calendar.current.isDateInToday($0.completedAt) }
        }
    }

    private var complete: [Habit] {
        todayHabits.filter { habit in
            habit.completions.contains { Calendar.current.isDateInToday($0.completedAt) }
        }
    }

    private var allComplete: Bool { incomplete.isEmpty && !todayHabits.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                themes.current.baseColor.ignoresSafeArea()

                if todayHabits.isEmpty {
                    EmptyTodayView(showAddHabit: $showAddHabit)
                } else if allComplete {
                    AllCompleteView()
                } else {
                    habitList
                }
            }
            .navigationTitle(todayTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(themes.current.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitView()
            }
        }
    }

    private var habitList: some View {
        List {
            if !incomplete.isEmpty {
                Section("Remaining") {
                    ForEach(incomplete) { habit in
                        HabitRow(habit: habit)
                    }
                }
            }
            if !complete.isEmpty {
                Section("Completed") {
                    ForEach(complete) { habit in
                        HabitRow(habit: habit, muted: true)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }

    private var todayTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
}

private struct EmptyTodayView: View {
    @Environment(HKThemeManager.self) private var themes
    @Binding var showAddHabit: Bool

    var body: some View {
        VStack(spacing: HKSpacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(themes.current.primaryColor)

            Text("No habits yet")
                .font(.hkTitle)
                .foregroundStyle(themes.current.textColor)

            Text("Add your first habit to get started.")
                .font(.hkBody)
                .foregroundStyle(themes.current.subtextColor)
                .multilineTextAlignment(.center)

            HKButton("Add a Habit", variant: .primary) {
                showAddHabit = true
            }
        }
        .padding(HKSpacing.xl)
    }
}

private struct AllCompleteView: View {
    @Environment(HKThemeManager.self) private var themes

    var body: some View {
        VStack(spacing: HKSpacing.lg) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(themes.current.successColor)
                .symbolEffect(.bounce)

            Text("All done!")
                .font(.hkLargeTitle)
                .foregroundStyle(themes.current.textColor)

            Text("Every habit complete for today. Come back tomorrow.")
                .font(.hkBody)
                .foregroundStyle(themes.current.subtextColor)
                .multilineTextAlignment(.center)
        }
        .padding(HKSpacing.xl)
    }
}
