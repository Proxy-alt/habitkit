import SwiftUI
import SwiftData
import HabitKitCore
import HabitKitUI

struct HabitsView: View {
    @Environment(HKThemeManager.self) private var themes
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var showAddHabit = false
    @State private var showArchived = false

    private var activeHabits: [Habit] { habits.filter { !$0.isArchived } }
    private var archivedHabits: [Habit] { habits.filter { $0.isArchived } }

    var body: some View {
        NavigationStack {
            ZStack {
                themes.current.baseColor.ignoresSafeArea()

                List {
                    ForEach(activeHabits) { habit in
                        NavigationLink(destination: HabitDetailView(habit: habit)) {
                            HabitListRow(habit: habit)
                        }
                    }
                    .onMove(perform: moveHabits)
                    .onDelete(perform: deleteHabits)

                    if !archivedHabits.isEmpty {
                        Section {
                            Button {
                                showArchived.toggle()
                            } label: {
                                Label(showArchived ? "Hide Archived" : "Show Archived (\(archivedHabits.count))",
                                      systemImage: "archivebox")
                                    .foregroundStyle(themes.current.subtextColor)
                                    .font(.hkBody)
                            }

                            if showArchived {
                                ForEach(archivedHabits) { habit in
                                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                                        HabitListRow(habit: habit, archived: true)
                                    }
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddHabit = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(themes.current.primaryColor)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .foregroundStyle(themes.current.primaryColor)
                }
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitView()
            }
        }
    }

    private func moveHabits(from source: IndexSet, to destination: Int) {
        var reordered = activeHabits
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, habit) in reordered.enumerated() {
            habit.sortOrder = index
        }
    }

    private func deleteHabits(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(activeHabits[index])
        }
    }
}

private struct HabitListRow: View {
    @Environment(HKThemeManager.self) private var themes
    let habit: Habit
    var archived: Bool = false

    var body: some View {
        HStack(spacing: HKSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: habit.icon)
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.hkHeadline)
                    .foregroundStyle(archived ? themes.current.subtextColor : themes.current.textColor)

                Text(scheduleDescription)
                    .font(.hkCaption)
                    .foregroundStyle(themes.current.subtextColor)
            }

            Spacer()

            if archived {
                Image(systemName: "archivebox")
                    .font(.hkCaption)
                    .foregroundStyle(themes.current.overlay0Color)
            }
        }
        .padding(.vertical, HKSpacing.xs)
    }

    private var accentColor: Color {
        Color(hex: habit.colorHex) ?? themes.current.primaryColor
    }

    private var scheduleDescription: String {
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
