// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Runway",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Runway",
            path: "Sources/Runway",
            exclude: ["Info.plist", "Runway.entitlements"]
        )
    ]
)
