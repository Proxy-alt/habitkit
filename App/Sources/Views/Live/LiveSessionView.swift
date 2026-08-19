import SwiftUI
import SwiftData
import ActivityKit
import HabitKitCore
import HabitKitUI

struct LiveSessionView: View {
    @Environment(HKThemeManager.self) private var themes
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    @State private var activeHabit: TimedHabit?
    @State private var sessionStartDate: Date?
    @State private var elapsed: TimeInterval = 0
    @State private var note = ""
    @State private var isComplete = false
    @State private var timer: Timer?

    private var activeTimedHabits: [TimedHabit] {
        habits.compactMap { $0 as? TimedHabit }.filter { !$0.isArchived }
    }

    private var progress: Double {
        guard let habit = activeHabit, habit.targetDurationSeconds > 0 else { return 0 }
        return min(elapsed / Double(habit.targetDurationSeconds), 1.0)
    }

    private var remaining: TimeInterval {
        guard let habit = activeHabit else { return 0 }
        return max(Double(habit.targetDurationSeconds) - elapsed, 0)
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
        sessionStartDate = Date()
        elapsed = 0
        isComplete = false
        startLiveActivity(for: habit)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let start = sessionStartDate else { return }
            elapsed = Date().timeIntervalSince(start)
            if let habit = activeHabit, elapsed >= Double(habit.targetDurationSeconds) {
                isComplete = true
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func completeSession(for habit: TimedHabit) {
        let completion = HabitCompletion(
            completedAt: Date(),
            durationSeconds: Int(elapsed),
            note: note.isEmpty ? nil : note,
            habit: habit
        )
        modelContext.insert(completion)
        stopSession()
        endLiveActivity(completed: true)
    }

    private func stopSession() {
        stopTimer()
        activeHabit = nil
        sessionStartDate = nil
        elapsed = 0
        note = ""
    }

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

    private func endLiveActivity(completed: Bool) {
        Task {
            for activity in Activity<HabitLiveActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
