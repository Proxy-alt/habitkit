// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HabitNook",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "HabitNookCore", targets: ["HabitNookCore"]),
        .library(name: "HabitNookUI", targets: ["HabitNookUI"]),
        .library(name: "HabitNookIntents", targets: ["HabitNookIntents"]),
    ],
    targets: [
        .target(
            name: "HabitNookCore",
            path: "HabitNookCore/Sources",
            exclude: [
                // Coded against a speculative EnergyKit API shape (ElectricityGuidance.shared,
                // .lowCarbonWindows, .currentCarbonIntensity) that does not match the real,
                // venue/query-based ElectricityGuidance.Service AsyncSequence API.
                // Needs a rewrite before re-enabling.
                "EnergyKit/EnergyScheduler.swift",
            ]
        ),
        .target(
            name: "HabitNookUI",
            dependencies: ["HabitNookCore"],
            path: "HabitNookUI/Sources",
            resources: [
                .process("Themes/Built-in"),
                .process("Themes/Community"),
            ]
        ),
        .target(
            name: "HabitNookIntents",
            dependencies: ["HabitNookCore"],
            path: "HabitNookIntents/Sources"
        ),
    ]
)
