import SwiftUI
import HabitKitUI

struct ContentView: View {
    @Environment(HKThemeManager.self) private var themes
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppNavigator.self) private var navigator
    @Environment(InAppAlarmMonitor.self) private var alarmMonitor

    var body: some View {
        @Bindable var navigator = navigator

        TabView(selection: $navigator.selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: HKSymbol.checkmark) }
                .tag(AppTab.today)

            HabitsView()
                .tabItem { Label("Habits", systemImage: HKSymbol.list) }
                .tag(AppTab.habits)

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: HKSymbol.chartBar) }
                .tag(AppTab.analytics)

            LiveSessionView()
                .tabItem { Label("Live", systemImage: HKSymbol.timer) }
                .tag(AppTab.live)

            SettingsView()
                .tabItem { Label("Settings", systemImage: HKSymbol.gear) }
                .tag(AppTab.settings)
        }
        .tint(themes.current.primaryColor)
        .background(themes.current.baseColor)
        .alert(
            alarmMonitor.alertingHabit?.habitName ?? "",
            isPresented: Binding(
                get: { alarmMonitor.alertingHabit != nil },
                set: { if !$0 { alarmMonitor.dismiss() } }
            )
        ) {
            Button("Complete") { alarmMonitor.complete() }
            Button("Not Now", role: .cancel) { alarmMonitor.dismiss() }
        } message: {
            Text("Time for your habit reminder.")
        }
    }
}
