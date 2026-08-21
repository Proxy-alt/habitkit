// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HabitNookApp",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "HabitNookApp", targets: ["HabitNookApp"]),
    ],
    dependencies: [
        .package(path: ".."),
    ],
    targets: [
        .target(
            name: "HabitNookApp",
            dependencies: [
                .product(name: "HabitNookCore", package: "HabitNook"),
                .product(name: "HabitNookUI", package: "HabitNook"),
                .product(name: "HabitNookIntents", package: "HabitNook"),
            ],
            path: "Sources"
        ),
    ]
)
