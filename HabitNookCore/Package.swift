// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HabitNookCore",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "HabitNookCore",
            targets: ["HabitNookCore"]
        )
    ],
    targets: [
        .target(
            name: "HabitNookCore",
            path: "Sources"
        ),
        .testTarget(
            name: "HabitNookCoreTests",
            dependencies: ["HabitNookCore"],
            path: "Tests/HabitNookCoreTests"
        )
    ]
)
