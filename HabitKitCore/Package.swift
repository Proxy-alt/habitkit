// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HabitKitCore",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v15),
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
