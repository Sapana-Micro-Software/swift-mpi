// swift-tools-version: 5.9
// Copyright (C) 2025, Shyamal Suhana Chandra
// SwiftMPI Framework - Dynamic Swift framework for Message Passing Interface
import PackageDescription

let package = Package(
    name: "SwiftMPI",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "SwiftMPI",
            type: .dynamic,
            targets: ["SwiftMPI"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftMPI",
            dependencies: [],
            path: "Sources/SwiftMPI"
        ),
        .testTarget(
            name: "SwiftMPITests",
            dependencies: ["SwiftMPI"],
            path: "Tests/SwiftMPITests"
        ),
    ]
)
