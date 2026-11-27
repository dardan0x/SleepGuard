// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Learn",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Learn", targets: ["Learn"]),
  ],
  dependencies: [
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.37.0"),
    .package(path: "../Config"),
    .package(path: "../Models"),
    .package(path: "../Routing"),
    .package(path: "../DesignSystem"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Learn",
      dependencies: [
        .product(name: "Config", package: "Config"),
        .product(name: "Models", package: "Models"),
        .product(name: "Routing", package: "Routing"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "FactoryKit", package: "Factory"),
        .product(name: "SleepGuardContentKit", package: "SleepGuardShared"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .defaultIsolation(MainActor.self),
      ]),
  ])
