// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Personalization",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Personalization", targets: ["Personalization"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(path: "../Env"),
    .package(path: "../DesignSystem"),
  ],
  targets: [
    .target(
      name: "Personalization",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "DesignSystem", package: "DesignSystem"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]
    ),
    .testTarget(
      name: "PersonalizationTests",
      dependencies: [
        "Personalization",
        .product(name: "Models", package: "Models"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]
    ),
  ]
)
