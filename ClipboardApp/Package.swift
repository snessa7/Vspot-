// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClipboardApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClipboardApp",
            targets: ["ClipboardApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ClipboardApp",
            path: "ClipboardApp",
            resources: [
                .process("Resources")
            ]
        )
    ]
)