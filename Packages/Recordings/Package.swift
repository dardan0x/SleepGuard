// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Recordings",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Recordings", targets: ["Recordings"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.1.0"),
    .package(path: "../Env"),
    .package(path: "../Routing"),
    .package(path: "../DesignSystem"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Recordings",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "Env", package: "Env"),
        .product(name: "Routing", package: "Routing"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "FactoryKit", package: "Factory"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .testTarget(
      name: "RecordingsTests",
      dependencies: [
        "Recordings",
        .product(name: "Models", package: "Models"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "ModelsTestSupport", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "EnvTestSupport", package: "Env"),
        .product(name: "FactoryKit", package: "Factory"),
        .product(name: "FactoryTesting", package: "Factory"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
  ])
