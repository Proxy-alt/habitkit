import AlarmKit
import Foundation
import HabitKitCore
import SwiftData
import SwiftUI

/// Watches AlarmKit's alarm state and surfaces a simple in-app alert when one
/// of a habit's reminders starts alerting.
///
/// AlarmKit's own full-screen alert only presents when the app is backgrounded
/// or the device is locked — while HabitKit is in the foreground, an alerting
/// alarm is otherwise invisible. This fills that gap.
@Observable
@MainActor
final class InAppAlarmMonitor {
    struct AlertingHabit: Identifiable {
        var id: UUID { reminderID }
        let reminderID: UUID
        let habitID: UUID
        let habitName: String
    }

    private(set) var alertingHabit: AlertingHabit?
    private var modelContainer: ModelContainer?
    private var watchTask: Task<Void, Never>?

    func start(modelContainer: ModelContainer) {
        guard watchTask == nil else { return }
        self.modelContainer = modelContainer
        watchTask = Task { [weak self] in
            guard let self else { return }
            for await alarms in AlarmKit.AlarmManager.shared.alarmUpdates {
                await self.handle(alarms: alarms)
            }
        }
    }

    private func handle(alarms: [Alarm]) async {
        guard let alerting = alarms.first(where: { $0.state == .alerting }) else {
            alertingHabit = nil
            return
        }
        guard alertingHabit?.reminderID != alerting.id, let modelContainer else { return }

        let context = ModelContext(modelContainer)
        guard let habits = try? context.fetch(FetchDescriptor<Habit>()) else { return }
        for habit in habits {
            if habit.schedule.reminders.contains(where: { $0.id == alerting.id }) {
                alertingHabit = AlertingHabit(reminderID: alerting.id, habitID: habit.id, habitName: habit.name)
                return
            }
        }
    }

    func complete() {
        guard let alertingHabit else { return }
        defer { self.alertingHabit = nil }

        if let modelContainer {
            let context = ModelContext(modelContainer)
            let habitID = alertingHabit.habitID
            let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.id == habitID })
            if let habit = try? context.fetch(descriptor).first {
                let completion = HabitCompletion(completedAt: Date(), habit: habit)
                context.insert(completion)
                habit.completions.append(completion)
                try? context.save()
            }
        }
        try? HabitAlarmScheduler.stopAlarm(for: alertingHabit.reminderID)
    }

    func dismiss() {
        alertingHabit = nil
    }
}
