// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HabitKitUI",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "HabitKitUI",
            targets: ["HabitKitUI"]
        ),
    ],
    targets: [
        .target(
            name: "HabitKitUI",
            path: "Sources",
            resources: [
                .process("Themes/"),
            ]
        ),
    ]
)
