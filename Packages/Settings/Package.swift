// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Settings",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Settings", targets: ["Settings"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(path: "../Env"),
    .package(path: "../Routing"),
    .package(path: "../DesignSystem"),
    .package(path: "../Personalization"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Settings",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "Routing", package: "Routing"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "Personalization", package: "Personalization"),
        .product(name: "FactoryKit", package: "Factory"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
  ])
