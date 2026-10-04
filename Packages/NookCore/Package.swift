// swift-tools-version: 6.2
import PackageDescription

// NookCore holds platform-agnostic primitives shared by every Nook app.
// It must not import SwiftUI, UIKit, or AppKit (ARCHITECTURE.md 2.2).
// The deployment floor is set by the lowest support tier in the suite
// (Org-5), not by the Rolling tier.
let package = Package(
    name: "NookCore",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9),
        .macOS(.v13),
        .tvOS(.v16),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NookCore", targets: ["NookCore"]),
    ],
    targets: [
        .target(name: "NookCore"),
        .testTarget(name: "NookCoreTests", dependencies: ["NookCore"]),
    ]
)
