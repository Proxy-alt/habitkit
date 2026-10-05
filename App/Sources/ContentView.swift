import SwiftUI
import HabitNookUI
import NookCore
import NookUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppNavigator.self) private var navigator
    @Environment(InAppAlarmMonitor.self) private var alarmMonitor

    var body: some View {
        @Bindable var navigator = navigator

        TabView(selection: $navigator.selectedTab) {
            TodayView()
                .tabItem { Label("Today", nookSymbol: .checkmark) }
                .tag(AppTab.today)

            HabitsView()
                .tabItem { Label("Habits", nookSymbol: .list) }
                .tag(AppTab.habits)

            AnalyticsView()
                .tabItem { Label("Analytics", nookSymbol: .chartBar) }
                .tag(AppTab.analytics)

            LiveSessionView()
                .tabItem { Label("Live", nookSymbol: .timer) }
                .tag(AppTab.live)

            SettingsView()
                .tabItem { Label("Settings", nookSymbol: .gear) }
                .tag(AppTab.settings)
        }
        .tint(NookColourStyle(.primary))
        .background(.nook(.base))
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
