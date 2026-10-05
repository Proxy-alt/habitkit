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
    dependencies: [
        .package(path: "../Packages/NookCore"),
        .package(path: "../Packages/NookUI"),
    ],
    targets: [
        .target(
            name: "HabitNookUI",
            dependencies: [
                .product(name: "NookCore", package: "NookCore"),
                .product(name: "NookUI", package: "NookUI"),
            ],
            path: "Sources",
            resources: [
                .process("Themes/Built-in/"),
                .process("Themes/Community/"),
            ]
        ),
    ]
)
