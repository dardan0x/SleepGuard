// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Models",
  platforms: [.iOS(.v17), .watchOS(.v10)],
  products: [
    .library(name: "Models", targets: ["Models"]),
    // Test-only helpers (in-memory store, fixtures). Only test targets depend on it.
    .library(name: "ModelsTestSupport", targets: ["ModelsTestSupport"]),
  ],
  dependencies: [
    .package(path: "../../../SleepGuardShared"),
  ],
  targets: [
    .target(
      name: "Models",
      dependencies: [
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
    .target(
      name: "ModelsTestSupport",
      dependencies: ["Models", .product(name: "SleepCore", package: "SleepGuardShared")],
      path: "TestSupport",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
    .testTarget(
      name: "ModelsTests",
      dependencies: ["Models", "ModelsTestSupport", .product(name: "SleepCore", package: "SleepGuardShared")],
      resources: [
        .copy("Fixtures"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
  ])
