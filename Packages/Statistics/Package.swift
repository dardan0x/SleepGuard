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
  ],
  targets: [
    .target(
      name: "Statistics",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "DesignSystem", package: "DesignSystem"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ],
      linkerSettings: [
        .linkedFramework("Charts"),
      ]
    ),
  ]
)
