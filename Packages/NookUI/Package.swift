// swift-tools-version: 6.2
import PackageDescription

// NookUI interprets NookCore primitives as SwiftUI types and hosts the shared
// components (ARCHITECTURE.md 13). It may import SwiftUI and NookCore only.
// iOS 17 is the floor: custom ShapeStyle resolution needs it.
let package = Package(
    name: "NookUI",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NookUI", targets: ["NookUI"]),
    ],
    dependencies: [
        .package(path: "../NookCore"),
    ],
    targets: [
        .target(name: "NookUI", dependencies: ["NookCore"]),
        .testTarget(name: "NookUITests", dependencies: ["NookUI"]),
    ]
)
