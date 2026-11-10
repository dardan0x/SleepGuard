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
  targets: [
    .target(
      name: "Models",
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
    .target(
      name: "ModelsTestSupport",
      dependencies: ["Models"],
      path: "TestSupport",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
    .testTarget(
      name: "ModelsTests",
      dependencies: ["Models", "ModelsTestSupport"],
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
  ])
