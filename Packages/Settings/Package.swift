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
    .package(path: "../DesignSystem"),
    .package(path: "../Personalization"),
  ],
  targets: [
    .target(
      name: "Settings",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "Personalization", package: "Personalization"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]
    ),
  ]
)
