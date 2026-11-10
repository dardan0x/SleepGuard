// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "DesignSystem",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "DesignSystem", targets: ["DesignSystem"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "DesignSystem",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "FactoryKit", package: "Factory"),
      ],
      path: "Sources",
      exclude: [],
      resources: [
        .process("Resources"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .testTarget(
      name: "DesignSystemTests",
      dependencies: [
        "DesignSystem",
        .product(name: "FactoryKit", package: "Factory"),
        .product(name: "FactoryTesting", package: "Factory"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
  ])
