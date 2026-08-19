// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HabitKit",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "HabitKitCore", targets: ["HabitKitCore"]),
        .library(name: "HabitKitUI", targets: ["HabitKitUI"]),
        .library(name: "HabitKitIntents", targets: ["HabitKitIntents"]),
    ],
    targets: [
        .target(
            name: "HabitKitCore",
            path: "HabitKitCore/Sources",
            exclude: [
                // Coded against a speculative AlarmKit API shape that does not
                // match the real framework (Alarm/AlarmManager/AlarmConfiguration<Metadata>).
                // Needs a rewrite against the actual API before re-enabling.
                "Alarms/AlarmManager.swift",
                // Coded against a speculative EnergyKit API shape (ElectricityGuidance.shared,
                // .lowCarbonWindows, .currentCarbonIntensity) that does not match the real,
                // venue/query-based ElectricityGuidance.Service AsyncSequence API.
                // Needs a rewrite before re-enabling.
                "EnergyKit/EnergyScheduler.swift",
            ]
        ),
        .target(
            name: "HabitKitUI",
            dependencies: ["HabitKitCore"],
            path: "HabitKitUI/Sources",
            resources: [
                .process("Themes/Built-in"),
                .process("Themes/Community"),
            ]
        ),
        .target(
            name: "HabitKitIntents",
            dependencies: ["HabitKitCore"],
            path: "HabitKitIntents/Sources"
        ),
    ]
)
