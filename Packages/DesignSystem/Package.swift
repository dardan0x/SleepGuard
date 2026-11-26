// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "DesignSystem",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "DesignSystem", targets: ["DesignSystem"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.37.0"),
  ],
  targets: [
    .target(
      name: "DesignSystem",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepStrings", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
        .product(name: "SleepGuardContentKit", package: "SleepGuardShared"),
        .product(name: "SleepStore", package: "SleepGuardShared"),
      ],
      path: "Sources",
      exclude: [],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .defaultIsolation(MainActor.self),
      ]),
    .testTarget(
      name: "DesignSystemTests",
      dependencies: [
        "DesignSystem",
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepStrings", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .defaultIsolation(MainActor.self),
      ]),
  ])
