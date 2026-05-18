// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HabitKitUI",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v15),
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
