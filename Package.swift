// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MarkitdownUI",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/simibac/ConfettiSwiftUI.git", .upToNextMinor(from: "1.1.0")),
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            from: "2.9.1"
        )
    ],
    targets: [
        .executableTarget(
            name: "MarkitdownUI",
            dependencies: [
                .product(name: "ConfettiSwiftUI", package: "ConfettiSwiftUI"),
                "Sparkle",
            ],
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
            dependencies: ["MarkitdownUI"],
            resources: [
                .copy("Resources/markymarkdown_test.docx"),
                .copy("Resources/markymarkdown_test.docx.md")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
