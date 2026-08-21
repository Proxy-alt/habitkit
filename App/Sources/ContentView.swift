import SwiftUI
import HabitNookUI

struct ContentView: View {
    @Environment(NookThemeManager.self) private var themes
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppNavigator.self) private var navigator
    @Environment(InAppAlarmMonitor.self) private var alarmMonitor

    var body: some View {
        @Bindable var navigator = navigator

        TabView(selection: $navigator.selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: NookSymbol.checkmark) }
                .tag(AppTab.today)

            HabitsView()
                .tabItem { Label("Habits", systemImage: NookSymbol.list) }
                .tag(AppTab.habits)

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: NookSymbol.chartBar) }
                .tag(AppTab.analytics)

            LiveSessionView()
                .tabItem { Label("Live", systemImage: NookSymbol.timer) }
                .tag(AppTab.live)

            SettingsView()
                .tabItem { Label("Settings", systemImage: NookSymbol.gear) }
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
