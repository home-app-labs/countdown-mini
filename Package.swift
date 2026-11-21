// swift-tools-version:5.9
// The app and its widget are built from CountdownMini.xcodeproj (see build.sh): a widget with
// settings needs Xcode's App Intents build step. This package exists so `swift test` can
// check the shared model.
import PackageDescription

let package = Package(
    name: "CountdownMini",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "CountdownShared", path: "Shared"),
        .testTarget(name: "CountdownMiniTests", dependencies: ["CountdownShared"], path: "Tests/CountdownMiniTests"),
    ]
)
