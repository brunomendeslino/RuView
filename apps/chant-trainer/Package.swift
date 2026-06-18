// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChantTrainer",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    targets: [
        .executableTarget(
            name: "ChantTrainer",
            path: "Sources/ChantTrainer",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
