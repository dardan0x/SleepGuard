// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Recordings",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Recordings", targets: ["Recordings"]),
  ],
  dependencies: [
    .package(path: "../Health"),
    .package(path: "../Config"),
    .package(path: "../Models"),
    .package(path: "../AudioEngine"),
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.33.0"),
    .package(path: "../Services"),
    .package(path: "../Routing"),
    .package(path: "../DesignSystem"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Recordings",
      dependencies: [
        .product(name: "Health", package: "Health"),
        .product(name: "Config", package: "Config"),
        .product(name: "Models", package: "Models"),
        .product(name: "AudioEngine", package: "AudioEngine"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "Services", package: "Services"),
        .product(name: "Routing", package: "Routing"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "FactoryKit", package: "Factory"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .defaultIsolation(MainActor.self),
      ]),
    .testTarget(
      name: "RecordingsTests",
      dependencies: [
        .product(name: "HealthTestSupport", package: "Health"),
        .product(name: "ConfigTestSupport", package: "Config"),
        .product(name: "Config", package: "Config"),
        "Recordings",
        .product(name: "Models", package: "Models"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "ModelsTestSupport", package: "Models"),
        .product(name: "Services", package: "Services"),
        .product(name: "FactoryKit", package: "Factory"),
        .product(name: "FactoryTesting", package: "Factory"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .defaultIsolation(MainActor.self),
      ]),
  ])
