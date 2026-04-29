// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MarkitdownUI",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "MarkitdownUI",
            exclude: [
                "Resources/AppIcon.iconset"
            ],
            resources: [
                .copy("Resources/markitdown"),
                .copy("Resources/AppIcon.icns")
            ]
        ),
        .testTarget(
            name: "MarkitdownUITests",
            dependencies: ["MarkitdownUI"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
