import CoreLocation
import SwiftUI
import SwiftData
import HabitNookCore
import HabitNookIntents
import HabitNookUI
import NookCore
import NookUI

struct HabitDetailView: View {
    @Environment(\.nookTheme) private var theme
    @Environment(GeofenceHabitMonitor.self) private var geofenceMonitor
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var habit: Habit
    @State private var showDeleteConfirm = false
    @State private var isLocatingForGeofence = false

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
            Rectangle().fill(.nook(.base)).ignoresSafeArea()

            ScrollView {
                VStack(spacing: NookSpacing.lg.value) {
                    headerCard
                    statsRow
                    remindersSection
                    locationSection
                    heatmapSection
                    recentCompletions
                    dangerZone
                }
                .padding(.md)
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
        NookCard {
            HStack(spacing: NookSpacing.md.value) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 64, height: 64)
                    Image(systemName: habit.icon)
                        .nookIconSize(.md)
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: NookSpacing.xs.value) {
                    Text(habit.name)
                        .font(.nook(.title))
                        .foregroundStyle(.nook(.text))
                    Text(habitTypeLabel)
                        .font(.nook(.caption))
                        .foregroundStyle(.nook(.subtext))
                }

                Spacer()

                NookProgressRing(progress: completionRate30Days, size: 52)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: NookSpacing.md.value) {
            statCell(value: "\(currentStreak)", label: "Current Streak", icon: .flame, color: .warning)
            statCell(value: "\(longestStreak)", label: "Longest Streak", icon: .trophy, color: .primary)
            statCell(value: "\(Int(completionRate30Days * 100))%", label: "30-Day Rate", icon: .chartBar, color: .success)
        }
    }

    private func statCell(value: String, label: String, icon: NookSymbol, color: NookColour) -> some View {
        NookCard {
            VStack(spacing: NookSpacing.xs.value) {
                Image(nookSymbol: icon)
                    .foregroundStyle(.nook(color))
                Text(value)
                    .font(.nook(.title))
                    .foregroundStyle(.nook(.text))
                Text(label)
                    .font(.nook(.caption))
                    .foregroundStyle(.nook(.subtext))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var remindersSection: some View {
        NookCard {
            VStack(alignment: .leading, spacing: NookSpacing.sm.value) {
                Text("Reminders")
                    .font(.nook(.headline))
                    .foregroundStyle(.nook(.text))

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
                        .foregroundStyle(.nook(.text))

                        Spacer()

                        Button {
                            removeReminder(reminder)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.nook(.danger))
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Remove reminder")
                    }
                }

                Button("Add Reminder") {
                    addReminder()
                }
                .foregroundStyle(.nook(.primary))
                .font(.nook(.body))
            }
        }
    }

    private var locationSection: some View {
        NookCard {
            VStack(alignment: .leading, spacing: NookSpacing.sm.value) {
                Text("Location")
                    .font(.nook(.headline))
                    .foregroundStyle(.nook(.text))

                Toggle(
                    "Auto-complete on arrival",
                    isOn: Binding(
                        get: { habit.schedule.geofence != nil },
                        set: { setGeofenceEnabled($0) }
                    )
                )
                .tint(NookColourStyle(.primary))
                .foregroundStyle(.nook(.text))

                if let geofence = habit.schedule.geofence {
                    Stepper(
                        "Radius: \(Int(geofence.radiusMeters))m",
                        value: Binding(
                            get: { geofence.radiusMeters },
                            set: { updateGeofenceRadius(to: $0) }
                        ),
                        in: 50...1000,
                        step: 50
                    )
                    .foregroundStyle(.nook(.text))

                    HStack {
                        Button("Update to Current Location") {
                            updateGeofenceToCurrentLocation()
                        }
                        .foregroundStyle(.nook(.primary))
                        .font(.nook(.body))
                        .disabled(isLocatingForGeofence)

                        if isLocatingForGeofence {
                            ProgressView()
                                .tint(NookColourStyle(.primary))
                        }
                    }
                }
            }
        }
    }

    private var heatmapSection: some View {
        NookCard {
            VStack(alignment: .leading, spacing: NookSpacing.sm.value) {
                Text("Activity")
                    .font(.nook(.headline))
                    .foregroundStyle(.nook(.text))
                HeatmapView(habit: habit)
            }
        }
    }

    private var recentCompletions: some View {
        let recent = habit.completions
            .sorted { $0.completedAt > $1.completedAt }
            .prefix(10)

        return NookCard {
            VStack(alignment: .leading, spacing: NookSpacing.sm.value) {
                Text("Recent Completions")
                    .font(.nook(.headline))
                    .foregroundStyle(.nook(.text))

                if recent.isEmpty {
                    Text("No completions yet.")
                        .font(.nook(.body))
                        .foregroundStyle(.nook(.subtext))
                } else {
                    ForEach(Array(recent)) { completion in
                        CompletionRow(completion: completion)
                    }
                }
            }
        }
    }

    private var dangerZone: some View {
        VStack(spacing: NookSpacing.sm.value) {
            NookButton("Archive Habit", variant: .secondary) {
                cancelAllReminderAlarms()
                habit.isArchived = true
                dismiss()
            }
            NookButton("Delete Habit", variant: .danger) {
                showDeleteConfirm = true
            }
        }
    }

    private var accentColor: Color {
        Color(hex: habit.colorHex) ?? theme.color(.primary)
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

    private func setGeofenceEnabled(_ enabled: Bool) {
        if enabled {
            updateGeofenceToCurrentLocation()
        } else {
            habit.schedule.geofence = nil
            try? modelContext.save()
            let habitID = habit.id
            Task { await geofenceMonitor.removeGeofence(for: habitID) }
        }
    }

    private func updateGeofenceRadius(to radius: Double) {
        guard var geofence = habit.schedule.geofence else { return }
        geofence.radiusMeters = radius
        habit.schedule.geofence = geofence
        // registerAllGeofences reads from a fresh ModelContext, so unsaved
        // changes on this one would be invisible to it.
        try? modelContext.save()
        Task { await geofenceMonitor.registerAllGeofences() }
    }

    private func updateGeofenceToCurrentLocation() {
        isLocatingForGeofence = true
        let existingRadius = habit.schedule.geofence?.radiusMeters ?? 150
        Task {
            defer { isLocatingForGeofence = false }
            guard let coordinate = await LocationManager.shared.currentLocation() else { return }
            habit.schedule.geofence = HabitGeofence(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                radiusMeters: existingRadius
            )
            try? modelContext.save()
            await geofenceMonitor.registerAllGeofences()
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
    let completion: HabitCompletion

    var body: some View {
        VStack(alignment: .leading, spacing: NookSpacing.xs.value) {
            HStack {
                Image(nookSymbol: .checkmark)
                    .foregroundStyle(.nook(.success))

                Text(completion.completedAt, style: .date)
                    .font(.nook(.body))
                    .foregroundStyle(.nook(.text))

                Spacer()

                Text(completion.completedAt, style: .time)
                    .font(.nook(.caption))
                    .foregroundStyle(.nook(.subtext))
            }

            if let note = completion.note, !note.isEmpty {
                Text(note)
                    .font(.nook(.caption))
                    .foregroundStyle(.nook(.subtext))
                    .padding(.leading, .lg)
            }

            if !completion.tags.isEmpty {
                HStack(spacing: NookSpacing.xs.value) {
                    ForEach(completion.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.nook(.caption))
                            .foregroundStyle(.nook(.primary))
                            .padding(.horizontal, .sm)
                            .padding(.vertical, 2)
                            .background(.nook(.primary).opacity(0.12), in: Capsule())
                    }
                }
                .padding(.leading, .lg)
            }
        }
        .padding(.vertical, 2)
    }
}
