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
    .package(path: "../DesignSystem"),
  ],
  targets: [
    .target(
      name: "Recordings",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "DesignSystem", package: "DesignSystem"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
  ])
