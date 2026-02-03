// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EmailScraper",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "EmailScraper", targets: ["EmailScraper"])
    ],
    dependencies: [
        // No external dependencies for now to keep it simple and native
    ],
    targets: [
        .executableTarget(
            name: "EmailScraper",
            dependencies: [],
            path: "Sources",
            resources: [.process("Resources")]
        )
    ]
)
