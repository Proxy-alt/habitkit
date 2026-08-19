// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HabitKitIntents",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "HabitKitIntents",
            targets: ["HabitKitIntents"]
        ),
    ],
    dependencies: [
        .package(path: "../HabitKitCore"),
    ],
    targets: [
        .target(
            name: "HabitKitIntents",
            dependencies: ["HabitKitCore"],
            path: "Sources"
        ),
    ]
)
