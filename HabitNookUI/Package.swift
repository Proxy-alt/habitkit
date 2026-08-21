// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HabitNookUI",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "HabitNookUI",
            targets: ["HabitNookUI"]
        ),
    ],
    targets: [
        .target(
            name: "HabitNookUI",
            path: "Sources",
            resources: [
                .process("Themes/Built-in/"),
                .process("Themes/Community/"),
            ]
        ),
    ]
)
