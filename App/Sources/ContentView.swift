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
                .tabItem { Label("Today", systemImage: HKSymbol.checkmark) }
                .tag(Tab.today)

            HabitsView()
                .tabItem { Label("Habits", systemImage: HKSymbol.list) }
                .tag(Tab.habits)

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: HKSymbol.chartBar) }
                .tag(Tab.analytics)

            LiveSessionView()
                .tabItem { Label("Live", systemImage: HKSymbol.timer) }
                .tag(Tab.live)

            SettingsView()
                .tabItem { Label("Settings", systemImage: HKSymbol.gear) }
                .tag(Tab.settings)
        }
        .tint(themes.current.primaryColor)
        .background(themes.current.baseColor)
    }
}
