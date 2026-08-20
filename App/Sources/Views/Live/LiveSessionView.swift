import SwiftUI
import SwiftData
import ActivityKit
import HabitKitCore
import HabitKitIntents
import HabitKitUI

struct LiveSessionView: View {
    @Environment(HKThemeManager.self) private var themes
    @Environment(\.modelContext) private var modelContext
    @Environment(AppNavigator.self) private var navigator
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    @State private var activeHabit: TimedHabit?
    @State private var timerAlarmID: UUID?
    @State private var fireDate: Date?
    @State private var pausedRemaining: TimeInterval?
    @State private var now = Date()
    @State private var note = ""
    @State private var isComplete = false
    @State private var uiTimer: Timer?

    private var activeTimedHabits: [TimedHabit] {
        habits.compactMap { $0 as? TimedHabit }.filter { !$0.isArchived }
    }

    private var isPaused: Bool { pausedRemaining != nil }

    /// Mirrors AlarmKit's own countdown: computed from `fireDate` rather than
    /// tracked separately, so it can't drift from the alarm actually driving
    /// the system Live Activity/Dynamic Island UI.
    private var remaining: TimeInterval {
        if let pausedRemaining { return pausedRemaining }
        guard let fireDate else { return 0 }
        return max(fireDate.timeIntervalSince(now), 0)
    }

    private var progress: Double {
        guard let habit = activeHabit, habit.targetDurationSeconds > 0 else { return 0 }
        return 1.0 - (remaining / Double(habit.targetDurationSeconds))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themes.current.baseColor.ignoresSafeArea()

                if let habit = activeHabit {
                    activeSession(for: habit)
                } else {
                    habitPicker
                }
            }
            .navigationTitle("Live")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { consumePendingTimer() }
        .onChange(of: navigator.pendingTimerHabit) { _, _ in consumePendingTimer() }
    }

    private func consumePendingTimer() {
        guard let habit = navigator.pendingTimerHabit else { return }
        navigator.pendingTimerHabit = nil
        startSession(for: habit)
    }

    private func activeSession(for habit: TimedHabit) -> some View {
        VStack(spacing: HKSpacing.xl) {
            Spacer()

            Text(habit.name)
                .font(.hkLargeTitle)
                .foregroundStyle(themes.current.textColor)

            ZStack {
                HKProgressRing(progress: progress, lineWidth: 16, size: 240) {
                    VStack(spacing: HKSpacing.xs) {
                        Text(timeString(remaining))
                            .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                            .foregroundStyle(themes.current.textColor)
                        Text("remaining")
                            .font(.hkCaption)
                            .foregroundStyle(themes.current.subtextColor)
                    }
                }
            }

            HKTextField("Add a note…", text: $note)
                .padding(.horizontal, HKSpacing.lg)

            HStack(spacing: HKSpacing.md) {
                HKButton("Abandon", variant: .secondary) {
                    stopSession()
                }

                if !isComplete {
                    HKButton(isPaused ? "Resume" : "Pause", variant: .secondary) {
                        isPaused ? resumeSession() : pauseSession()
                    }
                }

                HKButton(isComplete ? "Done!" : "Complete", variant: .primary) {
                    completeSession(for: habit)
                }
            }
            .padding(.horizontal, HKSpacing.lg)

            Spacer()
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private var habitPicker: some View {
        VStack(spacing: HKSpacing.lg) {
            if activeTimedHabits.isEmpty {
                VStack(spacing: HKSpacing.md) {
                    Image(systemName: HKSymbol.timer)
                        .font(HKIconSize.xl)
                        .foregroundStyle(themes.current.subtextColor)
                    Text("No Timed Habits")
                        .font(.hkTitle)
                        .foregroundStyle(themes.current.textColor)
                    Text("Create a timed habit to use the Live session view.")
                        .font(.hkBody)
                        .foregroundStyle(themes.current.subtextColor)
                        .multilineTextAlignment(.center)
                }
                .padding(HKSpacing.xl)
            } else {
                Text("Choose a habit to start")
                    .font(.hkTitle)
                    .foregroundStyle(themes.current.textColor)

                ScrollView {
                    VStack(spacing: HKSpacing.sm) {
                        ForEach(activeTimedHabits) { habit in
                            Button {
                                startSession(for: habit)
                            } label: {
                                HKCard {
                                    HStack {
                                        Image(systemName: habit.icon)
                                            .font(.hkHeadline)
                                            .foregroundStyle(themes.current.primaryColor)
                                        VStack(alignment: .leading) {
                                            Text(habit.name)
                                                .font(.hkHeadline)
                                                .foregroundStyle(themes.current.textColor)
                                            Text("\(habit.targetDurationSeconds / 60) min")
                                                .font(.hkCaption)
                                                .foregroundStyle(themes.current.subtextColor)
                                        }
                                        Spacer()
                                        Image(systemName: HKSymbol.play)
                                            .font(.title)
                                            .foregroundStyle(themes.current.primaryColor)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Start \(habit.name) session, \(habit.targetDurationSeconds / 60) minutes")
                        }
                    }
                    .padding(HKSpacing.md)
                }
            }
        }
    }

    private func startSession(for habit: TimedHabit) {
        activeHabit = habit
        isComplete = false
        pausedRemaining = nil
        now = Date()
        fireDate = now.addingTimeInterval(Double(habit.targetDurationSeconds))

        let alarmID = UUID()
        timerAlarmID = alarmID
        startCountdownAlarm(id: alarmID, habit: habit)
        startLiveActivity(for: habit)
    }

    /// AlarmKit's own countdown presentation only shows up as an alert once
    /// the timer fires — it doesn't render an ongoing Live Activity while
    /// counting down. This app-owned activity fills that gap; its content
    /// state is pushed on every tick in `startTimer` so it stays in sync.
    private func startLiveActivity(for habit: TimedHabit) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = HabitLiveActivityAttributes(
            habitID: habit.id,
            habitName: habit.name,
            targetSeconds: habit.targetDurationSeconds
        )
        let state = HabitLiveActivityAttributes.ContentState(
            remainingSeconds: habit.targetDurationSeconds,
            habitName: habit.name,
            isComplete: false
        )
        _ = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: nil)
        )
    }

    private func updateLiveActivity() {
        guard let habit = activeHabit else { return }
        let remainingSeconds = Int(remaining.rounded())
        let habitName = habit.name
        let complete = isComplete
        Task {
            for activity in Activity<HabitLiveActivityAttributes>.activities {
                let state = HabitLiveActivityAttributes.ContentState(
                    remainingSeconds: remainingSeconds,
                    habitName: habitName,
                    isComplete: complete
                )
                await activity.update(.init(state: state, staleDate: nil))
            }
        }
    }

    private func endLiveActivity() {
        Task {
            for activity in Activity<HabitLiveActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private func startCountdownAlarm(id: UUID, habit: TimedHabit) {
        let habitID = habit.id
        let habitName = habit.name
        let icon = habit.icon
        let tintColor = Color(hex: habit.colorHex) ?? themes.current.primaryColor
        let duration = TimeInterval(habit.targetDurationSeconds)
        Task {
            try? await HabitAlarmScheduler.startCountdownTimer(
                id: id,
                habitID: habitID,
                habitName: habitName,
                duration: duration,
                tintColor: tintColor,
                stopIntent: CompleteHabitAlarmIntent(habit: HabitEntity(id: habitID, name: habitName, icon: icon))
            )
        }
    }

    private func pauseSession() {
        guard let alarmID = timerAlarmID, pausedRemaining == nil else { return }
        pausedRemaining = remaining
        try? HabitAlarmScheduler.pauseCountdown(for: alarmID)
        updateLiveActivity()
    }

    private func resumeSession() {
        guard let alarmID = timerAlarmID, let paused = pausedRemaining else { return }
        now = Date()
        fireDate = now.addingTimeInterval(paused)
        pausedRemaining = nil
        try? HabitAlarmScheduler.resumeCountdown(for: alarmID)
        updateLiveActivity()
    }

    private func startTimer() {
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            now = Date()
            if !isPaused, remaining <= 0 {
                isComplete = true
            }
            updateLiveActivity()
        }
    }

    private func stopTimer() {
        uiTimer?.invalidate()
        uiTimer = nil
    }

    private func completeSession(for habit: TimedHabit) {
        let elapsedSeconds = max(habit.targetDurationSeconds - Int(remaining), 0)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let completion = HabitCompletion(
            completedAt: Date(),
            durationSeconds: elapsedSeconds,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            habit: habit
        )
        modelContext.insert(completion)
        tagNoteIfNeeded(trimmedNote, for: completion)
        stopSession()
    }

    /// Tags run on-device via `HabitCoach` after the completion is already
    /// saved, so logging a habit never waits on model inference.
    private func tagNoteIfNeeded(_ note: String, for completion: HabitCompletion) {
        guard !note.isEmpty else { return }
        let completionID = completion.id
        Task {
            let tags = await HabitCoach.shared.tagNote(note)
            guard !tags.isEmpty else { return }
            let descriptor = FetchDescriptor<HabitCompletion>(
                predicate: #Predicate { $0.id == completionID }
            )
            guard let saved = try? modelContext.fetch(descriptor).first else { return }
            saved.tags = tags
            try? modelContext.save()
        }
    }

    private func stopSession() {
        stopTimer()
        if let alarmID = timerAlarmID {
            try? HabitAlarmScheduler.cancelAlarm(for: alarmID)
        }
        endLiveActivity()
        activeHabit = nil
        timerAlarmID = nil
        fireDate = nil
        pausedRemaining = nil
        note = ""
        isComplete = false
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
