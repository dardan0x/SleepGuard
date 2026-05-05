// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "DesignSystem",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "DesignSystem", targets: ["DesignSystem"]),
  ],
  dependencies: [
    .package(path: "../Env"),
  ],
  targets: [
    .target(
      name: "DesignSystem",
      dependencies: [
        .product(name: "Env", package: "Env"),
      ]
    ),
  ]
)
