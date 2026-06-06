// swift-tools-version: 5.9
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
      path: "Sources"
    ),
    .testTarget(
      name: "PersonalizationTests",
      dependencies: [
        "Personalization",
        .product(name: "Models", package: "Models"),
      ],
      path: "Tests"
    ),
  ]
)
