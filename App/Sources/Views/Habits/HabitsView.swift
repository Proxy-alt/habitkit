import SwiftUI
import SwiftData
import HabitNookCore
import HabitNookUI
import NookCore
import NookUI

private func cancelReminderAlarms(for habit: Habit) {
    for reminder in habit.schedule.reminders {
        try? HabitAlarmScheduler.cancelAlarm(for: reminder.id)
    }
}

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var showAddHabit = false
    @State private var viewModel = HabitsViewModel()

    private var activeHabits: [Habit] { viewModel.activeHabits(from: habits) }
    private var archivedHabits: [Habit] { viewModel.archivedHabits(from: habits) }

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(.nook(.base)).ignoresSafeArea()

                List {
                    ForEach(activeHabits) { habit in
                        NavigationLink(destination: HabitDetailView(habit: habit)) {
                            HabitListRow(habit: habit, viewModel: viewModel)
                        }
                    }
                    .onMove(perform: moveHabits)
                    .onDelete(perform: deleteHabits)

                    if !archivedHabits.isEmpty {
                        Section {
                            Button {
                                viewModel.showArchived.toggle()
                            } label: {
                                Label(
                                    viewModel.showArchived
                                        ? "Hide Archived"
                                        : "Show Archived (\(archivedHabits.count))",
                                    nookSymbol: .archivebox
                                )
                                .foregroundStyle(.nook(.subtext))
                                .font(.nook(.body))
                            }
                            .accessibilityLabel(
                                viewModel.showArchived
                                    ? "Hide archived habits"
                                    : "Show \(archivedHabits.count) archived habits"
                            )

                            if viewModel.showArchived {
                                ForEach(archivedHabits) { habit in
                                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                                        HabitListRow(habit: habit, viewModel: viewModel, archived: true)
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
                        Image(nookSymbol: .plus)
                            .foregroundStyle(.nook(.primary))
                    }
                    .accessibilityLabel("Add habit")
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .foregroundStyle(.nook(.primary))
                        .accessibilityLabel("Edit habits")
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
            let habit = activeHabits[index]
            cancelReminderAlarms(for: habit)
            modelContext.delete(habit)
        }
    }
}

private struct HabitListRow: View {
    @Environment(\.nookTheme) private var theme
    let habit: Habit
    let viewModel: HabitsViewModel
    var archived: Bool = false

    var body: some View {
        HStack(spacing: NookSpacing.md.value) {
            ZStack {
                RoundedRectangle.nook(.sm)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: habit.icon)
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.nook(.headline))
                    .foregroundStyle(archived ? .nook(.subtext) : .nook(.text))

                Text(viewModel.scheduleDescription(for: habit))
                    .font(.nook(.caption))
                    .foregroundStyle(.nook(.subtext))
            }

            Spacer()

            if archived {
                Image(nookSymbol: .archivebox)
                    .font(.nook(.caption))
                    .foregroundStyle(.nook(.overlay0))
            }
        }
        .padding(.vertical, .xs)
    }

    private var accentColor: Color {
        Color(hex: habit.colorHex) ?? theme.color(.primary)
    }
}
