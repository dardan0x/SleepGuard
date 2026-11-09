// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Env",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "Env", targets: ["Env"]),
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
    .testTarget(
      name: "EnvTests",
      dependencies: [
        "Env",
        .product(name: "Models", package: "Models"),
        .product(name: "ModelsTestSupport", package: "Models"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
  ])
