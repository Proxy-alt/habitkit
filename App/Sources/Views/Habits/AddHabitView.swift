import SwiftUI
import SwiftData
import HabitKitCore
import HabitKitUI

struct AddHabitView: View {
    @Environment(HKThemeManager.self) private var themes
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedType: HabitType = .yesNo
    @State private var targetDuration: Int = 1800
    @State private var targetQuantity: Double = 1
    @State private var unit = ""
    @State private var steps: [String] = [""]
    @State private var selectedDays: Set<Int> = [0, 1, 2, 3, 4, 5, 6]
    @State private var selectedColorHex = ""

    enum HabitType: String, CaseIterable, Identifiable {
        case yesNo = "Yes/No"
        case timed = "Timed"
        case quantity = "Quantity"
        case checklist = "Checklist"
        case negative = "Negative"
        var id: String { rawValue }
    }

    private let iconOptions = [
        "star.fill", "heart.fill", "bolt.fill", "figure.run", "figure.walk",
        "drop.fill", "book.fill", "moon.fill", "sun.max.fill", "leaf.fill",
        "dumbbell.fill", "fork.knife", "pills.fill", "brain.head.profile",
        "music.note", "pencil", "laptopcomputer", "bicycle", "bed.double.fill"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                themes.current.baseColor.ignoresSafeArea()

                Form {
                    Section("Name") {
                        HKTextField("e.g. Morning Run", text: $name)
                    }

                    Section("Icon") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: HKSpacing.sm) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundStyle(
                                            selectedIcon == icon
                                            ? themes.current.primaryColor
                                            : themes.current.subtextColor
                                        )
                                        .frame(width: 44, height: 44)
                                        .background(
                                            selectedIcon == icon
                                            ? themes.current.primaryColor.opacity(0.15)
                                            : Color.clear,
                                            in: RoundedRectangle(cornerRadius: HKRadius.sm)
                                        )
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, HKSpacing.sm)
                    }

                    Section("Type") {
                        Picker("Type", selection: $selectedType) {
                            ForEach(HabitType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)

                        typeSpecificFields
                    }

                    Section("Schedule") {
                        scheduleFields
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(themes.current.subtextColor)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveHabit() }
                        .foregroundStyle(themes.current.primaryColor)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private var typeSpecificFields: some View {
        switch selectedType {
        case .timed:
            Stepper("Duration: \(targetDuration / 60) min", value: $targetDuration, in: 60...7200, step: 60)
                .foregroundStyle(themes.current.textColor)
        case .quantity:
            HStack {
                HKTextField("Unit (pages, glasses…)", text: $unit)
                Stepper("\(Int(targetQuantity))", value: $targetQuantity, in: 1...999)
            }
        case .checklist:
            ForEach(steps.indices, id: \.self) { i in
                HKTextField("Step \(i + 1)", text: $steps[i])
            }
            Button("Add Step") { steps.append("") }
                .foregroundStyle(themes.current.primaryColor)
                .font(.hkBody)
        case .yesNo, .negative:
            EmptyView()
        }
    }

    @ViewBuilder
    private var scheduleFields: some View {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        HStack(spacing: HKSpacing.xs) {
            ForEach(0..<7, id: \.self) { i in
                Button {
                    if selectedDays.contains(i) {
                        selectedDays.remove(i)
                    } else {
                        selectedDays.insert(i)
                    }
                } label: {
                    Text(days[i])
                        .font(.hkCaption)
                        .foregroundStyle(
                            selectedDays.contains(i)
                            ? themes.current.baseColor
                            : themes.current.subtextColor
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, HKSpacing.xs)
                        .background(
                            selectedDays.contains(i)
                            ? themes.current.primaryColor
                            : themes.current.surface1Color,
                            in: RoundedRectangle(cornerRadius: HKRadius.sm)
                        )
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private func saveHabit() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let schedule = HabitSchedule(
            frequency: .weekly(days: selectedDays),
            reminderTimes: [],
            habit: nil
        )

        let habit: Habit
        switch selectedType {
        case .yesNo:
            habit = Habit(name: trimmedName, icon: selectedIcon, colorHex: selectedColorHex, schedule: schedule)
        case .timed:
            habit = TimedHabit(
                name: trimmedName, icon: selectedIcon, colorHex: selectedColorHex,
                schedule: schedule, targetDurationSeconds: targetDuration
            )
        case .quantity:
            habit = QuantityHabit(
                name: trimmedName, icon: selectedIcon, colorHex: selectedColorHex,
                schedule: schedule, targetQuantity: targetQuantity, unit: unit
            )
        case .checklist:
            habit = ChecklistHabit(
                name: trimmedName, icon: selectedIcon, colorHex: selectedColorHex,
                schedule: schedule, steps: steps.filter { !$0.isEmpty }
            )
        case .negative:
            habit = NegativeHabit(
                name: trimmedName, icon: selectedIcon, colorHex: selectedColorHex,
                schedule: schedule, avoidTarget: trimmedName
            )
        }

        schedule.habit = habit
        modelContext.insert(habit)
        dismiss()
    }
}
