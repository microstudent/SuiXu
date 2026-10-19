// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Suixu",
    platforms: [.macOS("26.0")],
    products: [.executable(name: "Suixu", targets: ["Suixu"])],
    targets: [
        .target(name: "SuixuCore", resources: [.process("Resources")]),
        .executableTarget(name: "Suixu", dependencies: ["SuixuCore"]),
        .testTarget(name: "SuixuCoreTests", dependencies: ["SuixuCore"]),
        .testTarget(name: "SuixuTests", dependencies: ["Suixu", "SuixuCore"])
    ]
)
