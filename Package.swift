// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CameraRelayKit",
    platforms: [ .macOS( .v14 ) ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CameraRelayKit",
            targets: ["CameraRelayKit"]),
    ],
    dependencies:[ .package(url: "https://github.com/apple/swift-async-algorithms", from:"1.0.0-beta") ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CameraRelayKit", dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ]),
        .testTarget(
            name: "CameraRelayKitTests",
            dependencies: ["CameraRelayKit"]),
    ]
)
