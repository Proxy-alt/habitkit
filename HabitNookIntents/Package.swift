// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HabitNookIntents",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "HabitNookIntents",
            targets: ["HabitNookIntents"]
        ),
    ],
    dependencies: [
        .package(path: "../HabitNookCore"),
    ],
    targets: [
        .target(
            name: "HabitNookIntents",
            dependencies: ["HabitNookCore"],
            path: "Sources"
        ),
    ]
)
