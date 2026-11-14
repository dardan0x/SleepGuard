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
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.1.0"),
    .package(path: "../Env"),
    .package(path: "../Routing"),
    .package(path: "../DesignSystem"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Statistics",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "Env", package: "Env"),
        .product(name: "Routing", package: "Routing"),
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
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "ModelsTestSupport", package: "Models"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
  ])
