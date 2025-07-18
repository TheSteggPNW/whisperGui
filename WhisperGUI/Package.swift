// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "WhisperGUI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WhisperGUI", targets: ["WhisperGUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.5.0")
    ],
    targets: [
        .executableTarget(
            name: "WhisperGUI",
            dependencies: ["WhisperKit"],
            path: "Sources"
        )
    ]
)
