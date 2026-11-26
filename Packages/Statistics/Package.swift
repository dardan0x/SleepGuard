// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Statistics",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Statistics", targets: ["Statistics"]),
  ],
  dependencies: [
    .package(path: "../Config"),
    .package(path: "../Models"),
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.37.0"),
    .package(path: "../Routing"),
    .package(path: "../DesignSystem"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Statistics",
      dependencies: [
        .product(name: "Config", package: "Config"),
        .product(name: "Models", package: "Models"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "Routing", package: "Routing"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "FactoryKit", package: "Factory"),
        .product(name: "SleepStore", package: "SleepGuardShared"),
        .product(name: "SleepStrings", package: "SleepGuardShared"),
        .product(name: "SleepGuardContentKit", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
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
        .product(name: "SleepStore", package: "SleepGuardShared"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .defaultIsolation(MainActor.self),
      ]),
  ])
