// swift-tools-version: 5.9
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
    .package(path: "../DesignSystem"),
  ],
  targets: [
    .target(
      name: "SleepSession",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "AudioEngine", package: "AudioEngine"),
        .product(name: "Env", package: "Env"),
        .product(name: "DesignSystem", package: "DesignSystem"),
      ],
      path: "Sources/Views"
    ),
  ]
)
