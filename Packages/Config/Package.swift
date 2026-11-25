// swift-tools-version: 6.2
import PackageDescription

/// Remote config (feature flags, tabs, update gate, score config) and user
/// preferences: what the app is set to, read by every layer. Split from Env
/// (F27-T11, ADR 0008).
let package = Package(
  name: "Config",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "Config", targets: ["Config"]),
    // Fakes and isolated stores for tests and previews.
    .library(name: "ConfigTestSupport", targets: ["ConfigTestSupport"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.30.0"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Config",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "FactoryKit", package: "Factory"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
    .target(
      name: "ConfigTestSupport",
      dependencies: [
        "Config",
      ],
      path: "TestSupport",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
    .testTarget(
      name: "ConfigTests",
      dependencies: [
        "Config",
        "ConfigTestSupport",
        .product(name: "Models", package: "Models"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
  ])
