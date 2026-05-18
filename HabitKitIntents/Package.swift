// swift-tools-version: 6.0

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
    targets: [
        .target(
            name: "HabitKitIntents",
            path: "Sources"
        ),
    ]
)
