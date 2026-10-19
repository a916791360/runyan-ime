// swift-tools-version: 6.2
import PackageDescription

let strictSwift: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
]

let package = Package(
    name: "RunyanKit",
    defaultLocalization: "zh-Hans",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "RimeKit", targets: ["RimeKit"]),
        .library(name: "RunyanCore", targets: ["RunyanCore"]),
        .library(name: "RunyanPanel", targets: ["RunyanPanel"]),
        .library(name: "RunyanAI", targets: ["RunyanAI"]),
        .executable(name: "runyan", targets: ["runyan"]),
    ],
    dependencies: [
        // 依赖以源码形式固定放在仓库根目录 deps/ 下，用本地路径引用：
        // 构建不联网、版本可审计，CI 与离线机器行为一致。
        .package(path: "../../deps/Yams"),
        .package(path: "../../deps/swift-argument-parser"),
    ],
    targets: [
        // librime 1.17 prebuilt, assembled by scripts/fetch-librime.sh.
        .binaryTarget(name: "CRime", path: "Frameworks/CRime.xcframework"),

        // Thin, typed Swift wrapper over the librime C API.
        .target(name: "RimeKit", dependencies: ["CRime"], swiftSettings: strictSwift),

        // Configuration model, patch writer, importer, dictionary packages.
        .target(
            name: "RunyanCore",
            dependencies: [.product(name: "Yams", package: "Yams")],
            resources: [.copy("Resources/catalog.json"), .copy("Resources/registry.json")],
            swiftSettings: strictSwift
        ),

        // AppKit candidate panel shared by the input method and the settings preview.
        .target(name: "RunyanPanel", dependencies: ["RunyanCore"], swiftSettings: strictSwift),

        // Optional AI assistant. Never touches composition buffers or user dictionaries.
        .target(name: "RunyanAI", dependencies: ["RunyanCore"], swiftSettings: strictSwift),

        .executableTarget(
            name: "runyan",
            dependencies: [
                "RimeKit", "RunyanCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: strictSwift
        ),

        .testTarget(name: "RimeKitTests", dependencies: ["RimeKit"]),
        .testTarget(name: "RunyanCoreTests", dependencies: ["RunyanCore", "RimeKit"], exclude: ["Fixtures"]),
        .testTarget(name: "RunyanPanelTests", dependencies: ["RunyanPanel"]),
        .testTarget(name: "RunyanAITests", dependencies: ["RunyanAI"]),
    ]
)
