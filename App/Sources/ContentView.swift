import SwiftUI
import HabitKitUI

struct ContentView: View {
    @Environment(HKThemeManager.self) private var themes
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: Tab = .today

    enum Tab { case today, habits, analytics, live, settings }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "checkmark.circle.fill") }
                .tag(Tab.today)

            HabitsView()
                .tabItem { Label("Habits", systemImage: "list.bullet") }
                .tag(Tab.habits)

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }
                .tag(Tab.analytics)

            LiveSessionView()
                .tabItem { Label("Live", systemImage: "timer") }
                .tag(Tab.live)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(Tab.settings)
        }
        .tint(themes.current.primaryColor)
        .background(themes.current.baseColor)
    }
}
