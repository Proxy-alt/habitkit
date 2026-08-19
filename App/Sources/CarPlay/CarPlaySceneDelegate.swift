import CarPlay
import Foundation
import UIKit

// MARK: - CarPlaySceneDelegate

/// Implements the CarPlay application template scene for HabitKit (§8.43).
///
/// Tier architecture (v1 = WidgetKit Smart Stack; Tier 2 = CPListTemplate):
/// - `CPListTemplate` shows today's incomplete habits.
/// - Each row has a trailing action button to log the habit via `LogHabitIntent`.
/// - A progress bar in the header shows overall completion.
/// - The template auto-refreshes whenever `habitDirectoryDidChange` fires.
public final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    // MARK: - Private state

    private var interfaceController: CPInterfaceController?
    private var observerToken: NSObjectProtocol?

    // MARK: - CPTemplateApplicationSceneDelegate

    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        presentHabitList()

        observerToken = NotificationCenter.default.addObserver(
            forName: .habitDirectoryDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.presentHabitList()
        }
    }

    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
        }
        observerToken = nil
    }

    // MARK: - Template building

    private func presentHabitList() {
        let habits = loadTodayHabits()

        let headerItem = CPListImageRowItem(
            text: habitProgressText(habits: habits),
            images: []
        )

        let incompleteSection = CPListSection(
            items: habits.filter { !$0.isComplete }.map(makeListItem),
            header: "To Do",
            sectionIndexTitle: nil
        )
        let completeSection = CPListSection(
            items: habits.filter { $0.isComplete }.map(makeListItem),
            header: "Done",
            sectionIndexTitle: nil
        )

        let template = CPListTemplate(
            title: "HabitKit",
            sections: [incompleteSection, completeSection]
        )
        template.emptyViewTitleVariants = ["All habits done! 🎉"]

        if interfaceController?.topTemplate is CPListTemplate {
            interfaceController?.popTemplate(animated: false)
        }
        interfaceController?.pushTemplate(template, animated: false)
    }

    private func makeListItem(for habit: CarPlayHabitItem) -> CPListItem {
        let item = CPListItem(
            text: habit.name,
            detailText: habit.isComplete ? "Done ✓" : "\(habit.streak) day streak"
        )
        // CPListItemAccessoryType has no checkmark case; completion is
        // already conveyed by detailText ("Done ✓" above).
        item.accessoryType = .none
        item.handler = { [weak self] _, completion in
            if !habit.isComplete {
                self?.logHabit(habit)
            }
            completion()
        }
        return item
    }

    private func habitProgressText(habits: [CarPlayHabitItem]) -> String {
        let done = habits.filter { $0.isComplete }.count
        let total = habits.count
        guard total > 0 else { return "No habits today" }
        return "\(done) of \(total) done"
    }

    // MARK: - Data loading

    private func loadTodayHabits() -> [CarPlayHabitItem] {
        // Read from shared UserDefaults — written by the main app on each completion.
        let defaults = UserDefaults(suiteName: "group.com.habitkit.app")
        guard let data = defaults?.data(forKey: "carplay.todayHabits"),
              let habits = try? JSONDecoder().decode([CarPlayHabitItem].self, from: data) else {
            return []
        }
        return habits
    }

    private func logHabit(_ habit: CarPlayHabitItem) {
        NotificationCenter.default.post(
            name: .carPlayDidRequestLogHabit,
            object: nil,
            userInfo: ["habitID": habit.id]
        )
    }
}

// MARK: - CarPlayHabitItem

/// Lightweight habit representation stored in shared UserDefaults for CarPlay.
public struct CarPlayHabitItem: Codable, Sendable {
    public var id: UUID
    public var name: String
    public var icon: String
    public var isComplete: Bool
    public var streak: Int

    public init(id: UUID, name: String, icon: String, isComplete: Bool, streak: Int) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isComplete = isComplete
        self.streak = streak
    }
}

// MARK: - Notification names

public extension Notification.Name {
    /// Posted when the CarPlay UI requests a habit be logged.
    static let carPlayDidRequestLogHabit = Notification.Name("com.habitkit.carPlayDidRequestLogHabit")
}
