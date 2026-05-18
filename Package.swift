// swift-tools-version: 6.0
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
            path: "HabitKitCore/Sources"
        ),
        .target(
            name: "HabitKitUI",
            dependencies: ["HabitKitCore"],
            path: "HabitKitUI/Sources",
            resources: [.process("Themes")]
        ),
        .target(
            name: "HabitKitIntents",
            dependencies: ["HabitKitCore"],
            path: "HabitKitIntents/Sources"
        ),
    ]
)
