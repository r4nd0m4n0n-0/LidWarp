// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RetroPhosphor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "RetroPhosphor", targets: ["RetroPhosphor"])
    ],
    targets: [
        .executableTarget(
            name: "RetroPhosphor",
            resources: [.process("Resources")]
        )
    ]
)
