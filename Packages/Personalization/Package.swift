// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Personalization",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Personalization", targets: ["Personalization"]),
  ],
  dependencies: [
    .package(path: "../Platform"),
    .package(path: "../Config"),
    .package(path: "../Models"),
    .package(path: "../DesignSystem"),
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.32.0"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Personalization",
      dependencies: [
        .product(name: "Platform", package: "Platform"),
        .product(name: "Config", package: "Config"),
        .product(name: "Models", package: "Models"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "FactoryKit", package: "Factory"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .defaultIsolation(MainActor.self),
      ]),
  ])
