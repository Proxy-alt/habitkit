import SwiftUI
import SwiftData
import HabitNookCore
import HabitNookUI
import NookCore
import NookUI

struct TodayView: View {
    @Query private var habits: [Habit]
    @State private var showAddHabit = false
    @State private var viewModel = TodayViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(.nook(.base)).ignoresSafeArea()

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
                        Image(nookSymbol: .plus)
                            .foregroundStyle(.nook(.primary))
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
    @Binding var showAddHabit: Bool

    var body: some View {
        VStack(spacing: NookSpacing.lg.value) {
            Image(nookSymbol: .sparkles)
                .nookIconSize(.xxl)
                .foregroundStyle(.nook(.primary))

            Text("No habits yet")
                .font(.nook(.title))
                .foregroundStyle(.nook(.text))

            Text("Add your first habit to get started.")
                .font(.nook(.body))
                .foregroundStyle(.nook(.subtext))
                .multilineTextAlignment(.center)

            NookButton("Add a Habit", variant: .primary) {
                showAddHabit = true
            }
        }
        .padding(.xl)
    }
}

private struct AllCompleteView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animating = false

    var body: some View {
        VStack(spacing: NookSpacing.lg.value) {
            Image(nookSymbol: .checkmarkSeal)
                .nookIconSize(.hero)
                .foregroundStyle(.nook(.success))
                .scaleEffect(animating ? 1.05 : 1.0)
                .onAppear {
                    // A looping pulse is decorative motion; skip it entirely
                    // under Reduce Motion rather than crossfading forever.
                    guard !reduceMotion else { return }
                    let pulse = NookAnimation.slow.swiftUIAnimation(reduceMotion: false)
                    withAnimation(pulse.repeatForever(autoreverses: true)) {
                        animating = true
                    }
                }

            Text("All done!")
                .font(.nook(.largeTitle))
                .foregroundStyle(.nook(.text))

            Text("Every habit complete for today. Come back tomorrow.")
                .font(.nook(.body))
                .foregroundStyle(.nook(.subtext))
                .multilineTextAlignment(.center)
        }
        .padding(.xl)
    }
}
