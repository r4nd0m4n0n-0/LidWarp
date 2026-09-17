// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LidWarp",

    platforms: [
        .macOS(.v13)
    ],

    products: [
        .executable(
            name: "RetroPhosphor",
            targets: [
                "RetroPhosphor"
            ]
        )
    ],

    targets: [
        .executableTarget(
            name: "RetroPhosphor",
            path: "Sources/RetroPhosphor"
        ),

        .testTarget(
            name: "RetroPhosphorTests",
            dependencies: [
                "RetroPhosphor"
            ],
            path: "Tests/RetroPhosphorTests"
        )
    ]
)
