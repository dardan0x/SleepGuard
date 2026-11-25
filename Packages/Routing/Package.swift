// swift-tools-version: 6.2
import PackageDescription

/// Navigation contract between feature packages: route enums, the per-tab
/// `RouterPath`, the root presentation policy and app-wide tab state
/// (`TabCoordinator`, moved from Env in F27-T11). See
/// docs/adr/0001-routing-package.md and 0008.
let package = Package(
  name: "Routing",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "Routing", targets: ["Routing"]),
    .library(name: "RoutingTestSupport", targets: ["RoutingTestSupport"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(path: "../Config"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Routing",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Config", package: "Config"),
        .product(name: "FactoryKit", package: "Factory"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
    .target(
      name: "RoutingTestSupport",
      dependencies: [
        "Routing",
        .product(name: "Models", package: "Models"),
      ],
      path: "TestSupport",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
    .testTarget(
      name: "RoutingTests",
      dependencies: [
        "Routing",
        "RoutingTestSupport",
        .product(name: "Models", package: "Models"),
        .product(name: "Config", package: "Config"),
        .product(name: "ConfigTestSupport", package: "Config"),
        .product(name: "FactoryKit", package: "Factory"),
        .product(name: "FactoryTesting", package: "Factory"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
  ])
