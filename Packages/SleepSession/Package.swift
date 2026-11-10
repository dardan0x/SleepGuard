// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "SleepSession",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "SleepSession", targets: ["SleepSession"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(path: "../AudioEngine"),
    .package(path: "../Env"),
    .package(path: "../Routing"),
    .package(path: "../DesignSystem"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "SleepSession",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "AudioEngine", package: "AudioEngine"),
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
  ])
