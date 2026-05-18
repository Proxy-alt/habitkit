// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HabitKitIntents",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "HabitKitIntents",
            targets: ["HabitKitIntents"]
        ),
    ],
    targets: [
        .target(
            name: "HabitKitIntents",
            path: "Sources"
        ),
    ]
)
