import SwiftUI
import SwiftData
import HabitKitCore
import HabitKitIntents
import HabitKitUI

struct HabitDetailView: View {
    @Environment(HKThemeManager.self) private var themes
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var habit: Habit
    @State private var showDeleteConfirm = false

    private var completionRate30Days: Double {
        let calendar = Calendar.current
        let now = Date()
        let days30 = (0..<30).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) }
        let completedDays = days30.filter { day in
            habit.completions.contains { calendar.isDate($0.completedAt, inSameDayAs: day) }
        }
        return Double(completedDays.count) / 30.0
    }

    private var currentStreak: Int {
        StreakCalculator.currentStreak(completions: habit.completions, schedule: habit.schedule)
    }

    private var longestStreak: Int {
        StreakCalculator.longestStreak(completions: habit.completions, schedule: habit.schedule)
    }

    var body: some View {
        ZStack {
            themes.current.baseColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: HKSpacing.lg) {
                    headerCard
                    statsRow
                    remindersSection
                    heatmapSection
                    recentCompletions
                    dangerZone
                }
                .padding(HKSpacing.md)
            }
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Delete \(habit.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Habit", role: .destructive) {
                cancelAllReminderAlarms()
                modelContext.delete(habit)
                dismiss()
            }
            Button("Archive Instead") {
                cancelAllReminderAlarms()
                habit.isArchived = true
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerCard: some View {
        HKCard {
            HStack(spacing: HKSpacing.md) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 64, height: 64)
                    Image(systemName: habit.icon)
                        .font(HKIconSize.md)
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: HKSpacing.xs) {
                    Text(habit.name)
                        .font(.hkTitle)
                        .foregroundStyle(themes.current.textColor)
                    Text(habitTypeLabel)
                        .font(.hkCaption)
                        .foregroundStyle(themes.current.subtextColor)
                }

                Spacer()

                HKProgressRing(progress: completionRate30Days, size: 52)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: HKSpacing.md) {
            statCell(value: "\(currentStreak)", label: "Current Streak", icon: HKSymbol.flame, color: themes.current.warningColor)
            statCell(value: "\(longestStreak)", label: "Longest Streak", icon: HKSymbol.trophy, color: themes.current.primaryColor)
            statCell(value: "\(Int(completionRate30Days * 100))%", label: "30-Day Rate", icon: HKSymbol.chartBar, color: themes.current.successColor)
        }
    }

    private func statCell(value: String, label: String, icon: String, color: Color) -> some View {
        HKCard {
            VStack(spacing: HKSpacing.xs) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(value)
                    .font(.hkTitle)
                    .foregroundStyle(themes.current.textColor)
                Text(label)
                    .font(.hkCaption)
                    .foregroundStyle(themes.current.subtextColor)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var remindersSection: some View {
        HKCard {
            VStack(alignment: .leading, spacing: HKSpacing.sm) {
                Text("Reminders")
                    .font(.hkHeadline)
                    .foregroundStyle(themes.current.textColor)

                ForEach(habit.schedule.reminders) { reminder in
                    HStack {
                        DatePicker(
                            "Reminder time",
                            selection: Binding(
                                get: { reminder.time },
                                set: { updateReminderTime(reminder, to: $0) }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .foregroundStyle(themes.current.textColor)

                        Spacer()

                        Button {
                            removeReminder(reminder)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(themes.current.dangerColor)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Remove reminder")
                    }
                }

                Button("Add Reminder") {
                    addReminder()
                }
                .foregroundStyle(themes.current.primaryColor)
                .font(.hkBody)
            }
        }
    }

    private var heatmapSection: some View {
        HKCard {
            VStack(alignment: .leading, spacing: HKSpacing.sm) {
                Text("Activity")
                    .font(.hkHeadline)
                    .foregroundStyle(themes.current.textColor)
                HeatmapView(habit: habit)
            }
        }
    }

    private var recentCompletions: some View {
        let recent = habit.completions
            .sorted { $0.completedAt > $1.completedAt }
            .prefix(10)

        return HKCard {
            VStack(alignment: .leading, spacing: HKSpacing.sm) {
                Text("Recent Completions")
                    .font(.hkHeadline)
                    .foregroundStyle(themes.current.textColor)

                if recent.isEmpty {
                    Text("No completions yet.")
                        .font(.hkBody)
                        .foregroundStyle(themes.current.subtextColor)
                } else {
                    ForEach(Array(recent)) { completion in
                        CompletionRow(completion: completion)
                    }
                }
            }
        }
    }

    private var dangerZone: some View {
        VStack(spacing: HKSpacing.sm) {
            HKButton("Archive Habit", variant: .secondary) {
                cancelAllReminderAlarms()
                habit.isArchived = true
                dismiss()
            }
            HKButton("Delete Habit", variant: .danger) {
                showDeleteConfirm = true
            }
        }
    }

    private var accentColor: Color {
        Color(hex: habit.colorHex) ?? themes.current.primaryColor
    }

    private func addReminder() {
        let reminder = HabitReminder(time: Date())
        habit.schedule.reminders.append(reminder)
        scheduleReminderAlarm(reminder)
    }

    private func removeReminder(_ reminder: HabitReminder) {
        habit.schedule.reminders.removeAll { $0.id == reminder.id }
        try? HabitAlarmScheduler.cancelAlarm(for: reminder.id)
    }

    private func updateReminderTime(_ reminder: HabitReminder, to newTime: Date) {
        guard let index = habit.schedule.reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        var updated = reminder
        updated.time = newTime
        habit.schedule.reminders[index] = updated
        scheduleReminderAlarm(updated)
    }

    private func scheduleReminderAlarm(_ reminder: HabitReminder) {
        let habitID = habit.id
        let habitName = habit.name
        let icon = habit.icon
        let tintColor = accentColor
        Task {
            try? await HabitAlarmScheduler.scheduleAlarm(
                id: reminder.id,
                habitID: habitID,
                habitName: habitName,
                at: reminder.time,
                tintColor: tintColor,
                stopIntent: CompleteHabitAlarmIntent(habit: HabitEntity(id: habitID, name: habitName, icon: icon))
            )
        }
    }

    private func cancelAllReminderAlarms() {
        for reminder in habit.schedule.reminders {
            try? HabitAlarmScheduler.cancelAlarm(for: reminder.id)
        }
    }

    private var habitTypeLabel: String {
        switch habit {
        case is TimedHabit: return "Timed Habit"
        case is QuantityHabit: return "Quantity Habit"
        case is ChecklistHabit: return "Checklist Habit"
        case is NegativeHabit: return "Avoidance Habit"
        default: return "Habit"
        }
    }
}

private struct CompletionRow: View {
    @Environment(HKThemeManager.self) private var themes
    let completion: HabitCompletion

    var body: some View {
        VStack(alignment: .leading, spacing: HKSpacing.xs) {
            HStack {
                Image(systemName: HKSymbol.checkmark)
                    .foregroundStyle(themes.current.successColor)

                Text(completion.completedAt, style: .date)
                    .font(.hkBody)
                    .foregroundStyle(themes.current.textColor)

                Spacer()

                Text(completion.completedAt, style: .time)
                    .font(.hkCaption)
                    .foregroundStyle(themes.current.subtextColor)
            }

            if let note = completion.note, !note.isEmpty {
                Text(note)
                    .font(.hkCaption)
                    .foregroundStyle(themes.current.subtextColor)
                    .padding(.leading, HKSpacing.lg)
            }

            if !completion.tags.isEmpty {
                HStack(spacing: HKSpacing.xs) {
                    ForEach(completion.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.hkCaption)
                            .foregroundStyle(themes.current.primaryColor)
                            .padding(.horizontal, HKSpacing.sm)
                            .padding(.vertical, 2)
                            .background(themes.current.primaryColor.opacity(0.12), in: Capsule())
                    }
                }
                .padding(.leading, HKSpacing.lg)
            }
        }
        .padding(.vertical, 2)
    }
}
