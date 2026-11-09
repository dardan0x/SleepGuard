// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Statistics",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Statistics", targets: ["Statistics"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(path: "../Env"),
    .package(path: "../DesignSystem"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Statistics",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "FactoryKit", package: "Factory"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ],
      linkerSettings: [
        .linkedFramework("Charts"),
      ]),
    .testTarget(
      name: "StatisticsTests",
      dependencies: [
        "Statistics",
        .product(name: "Models", package: "Models"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
  ])
