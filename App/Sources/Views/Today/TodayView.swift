import SwiftUI
import SwiftData
import HabitKitCore
import HabitKitUI

struct TodayView: View {
    @Environment(HKThemeManager.self) private var themes
    @Query private var habits: [Habit]
    @State private var showAddHabit = false
    @State private var viewModel = TodayViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                themes.current.baseColor.ignoresSafeArea()

                if viewModel.todayHabits.isEmpty {
                    EmptyTodayView(showAddHabit: $showAddHabit)
                } else if viewModel.isAllComplete {
                    AllCompleteView()
                } else {
                    habitList
                }
            }
            .navigationTitle(viewModel.todayTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddHabit = true
                    } label: {
                        Image(systemName: HKSymbol.plus)
                            .foregroundStyle(themes.current.primaryColor)
                    }
                    .accessibilityLabel("Add habit")
                }
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitView()
            }
            .onAppear {
                viewModel.load(from: habits)
            }
            .onChange(of: habits) { _, newHabits in
                viewModel.load(from: newHabits)
            }
        }
    }

    private var habitList: some View {
        List {
            if !viewModel.incompleteHabits.isEmpty {
                Section("Remaining") {
                    ForEach(viewModel.incompleteHabits) { habit in
                        HabitRow(habit: habit)
                    }
                }
            }
            if !viewModel.completeHabits.isEmpty {
                Section("Completed") {
                    ForEach(viewModel.completeHabits) { habit in
                        HabitRow(habit: habit, muted: true)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }
}

private struct EmptyTodayView: View {
    @Environment(HKThemeManager.self) private var themes
    @Binding var showAddHabit: Bool

    var body: some View {
        VStack(spacing: HKSpacing.lg) {
            Image(systemName: HKSymbol.sparkles)
                .font(.system(size: 64))
                .foregroundStyle(themes.current.primaryColor)

            Text("No habits yet")
                .font(.hkTitle)
                .foregroundStyle(themes.current.textColor)

            Text("Add your first habit to get started.")
                .font(.hkBody)
                .foregroundStyle(themes.current.subtextColor)
                .multilineTextAlignment(.center)

            HKButton("Add a Habit", variant: .primary) {
                showAddHabit = true
            }
        }
        .padding(HKSpacing.xl)
    }
}

private struct AllCompleteView: View {
    @Environment(HKThemeManager.self) private var themes
    @State private var animating = false

    var body: some View {
        VStack(spacing: HKSpacing.lg) {
            Image(systemName: HKSymbol.checkmarkSeal)
                .font(.system(size: 72))
                .foregroundStyle(themes.current.successColor)
                .scaleEffect(animating ? 1.05 : 1.0)
                .onAppear {
                    withAnimation(HKAnimation.slow.repeatForever(autoreverses: true)) {
                        animating = true
                    }
                }

            Text("All done!")
                .font(.hkLargeTitle)
                .foregroundStyle(themes.current.textColor)

            Text("Every habit complete for today. Come back tomorrow.")
                .font(.hkBody)
                .foregroundStyle(themes.current.subtextColor)
                .multilineTextAlignment(.center)
        }
        .padding(HKSpacing.xl)
    }
}
