// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Onboarding",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Onboarding", targets: ["Onboarding"]),
  ],
  dependencies: [
    .package(path: "../Platform"),
    .package(path: "../Health"),
    .package(path: "../Config"),
    .package(path: "../Models"),
    .package(path: "../AudioEngine"),
    .package(path: "../Services"),
    .package(path: "../DesignSystem"),
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.36.0"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Onboarding",
      dependencies: [
        .product(name: "Platform", package: "Platform"),
        .product(name: "Health", package: "Health"),
        .product(name: "Config", package: "Config"),
        .product(name: "Models", package: "Models"),
        .product(name: "AudioEngine", package: "AudioEngine"),
        .product(name: "Services", package: "Services"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
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
