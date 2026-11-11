// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Env",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "Env", targets: ["Env"]),
    // Fakes for every `Env` service protocol, for tests and previews.
    .library(name: "EnvTestSupport", targets: ["EnvTestSupport"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(path: "../AudioEngine"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Env",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "AudioEngine", package: "AudioEngine"),
        .product(name: "FactoryKit", package: "Factory"),
      ],
      path: "Sources/Services",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ],
      linkerSettings: [
        .linkedFramework("HealthKit"),
        .linkedFramework("WatchConnectivity"),
      ]),
    .target(
      name: "EnvTestSupport",
      dependencies: [
        "Env",
        .product(name: "Models", package: "Models"),
        .product(name: "AudioEngine", package: "AudioEngine"),
      ],
      path: "TestSupport",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
    .testTarget(
      name: "EnvTests",
      dependencies: [
        "Env",
        "EnvTestSupport",
        .product(name: "Models", package: "Models"),
        .product(name: "ModelsTestSupport", package: "Models"),
        .product(name: "AudioEngine", package: "AudioEngine"),
        .product(name: "FactoryKit", package: "Factory"),
        .product(name: "FactoryTesting", package: "Factory"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
  ])
