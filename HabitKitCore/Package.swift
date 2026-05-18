// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HabitKitCore",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "HabitKitCore",
            targets: ["HabitKitCore"]
        )
    ],
    targets: [
        .target(
            name: "HabitKitCore",
            path: "Sources"
        ),
        .testTarget(
            name: "HabitKitCoreTests",
            dependencies: ["HabitKitCore"],
            path: "Tests/HabitKitCoreTests"
        )
    ]
)
