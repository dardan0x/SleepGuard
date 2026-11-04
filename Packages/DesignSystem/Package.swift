// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "DesignSystem",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "DesignSystem", targets: ["DesignSystem"]),
  ],
  dependencies: [
    .package(path: "../Env"),
    .package(path: "../Models"),
  ],
  targets: [
    .target(
      name: "DesignSystem",
      dependencies: [
        .product(name: "Env", package: "Env"),
        .product(name: "Models", package: "Models"),
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
  ])
