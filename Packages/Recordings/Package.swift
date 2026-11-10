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
        .product(name: "ModelsTestSupport", package: "Models"),
        .product(name: "Env", package: "Env"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
  ])
