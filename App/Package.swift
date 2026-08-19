// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HabitKitApp",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "HabitKitApp", targets: ["HabitKitApp"]),
    ],
    dependencies: [
        .package(path: ".."),
    ],
    targets: [
        .target(
            name: "HabitKitApp",
            dependencies: [
                .product(name: "HabitKitCore", package: "HabitKit"),
                .product(name: "HabitKitUI", package: "HabitKit"),
                .product(name: "HabitKitIntents", package: "HabitKit"),
            ],
            path: "Sources"
        ),
    ]
)
