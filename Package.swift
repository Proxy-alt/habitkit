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
            path: "HabitNookCore/Sources"
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
