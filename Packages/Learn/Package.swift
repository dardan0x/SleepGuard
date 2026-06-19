// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Learn",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Learn", targets: ["Learn"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(path: "../Env"),
    .package(path: "../DesignSystem"),
  ],
  targets: [
    .target(
      name: "Learn",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "DesignSystem", package: "DesignSystem"),
      ],
      path: "Sources"
    ),
  ]
)
