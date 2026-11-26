// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Services",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "Services", targets: ["Services"]),
    // Fakes for the session service protocols, for tests and previews. Config,
    // Health, Platform and Routing ship their own TestSupport.
    .library(name: "ServicesTestSupport", targets: ["ServicesTestSupport"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.34.0"),
    .package(path: "../AudioEngine"),
    .package(path: "../Config"),
    .package(path: "../Health"),
    .package(path: "../Platform"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Services",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepFiles", package: "SleepGuardShared"),
        .product(name: "SleepNotifications", package: "SleepGuardShared"),
        .product(name: "SleepMelodies", package: "SleepGuardShared"),
        .product(name: "AudioEngine", package: "AudioEngine"),
        .product(name: "Config", package: "Config"),
        .product(name: "Health", package: "Health"),
        .product(name: "Platform", package: "Platform"),
        .product(name: "FactoryKit", package: "Factory"),
      ],
      path: "Sources/Services",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
      ]),
    .target(
      name: "ServicesTestSupport",
      dependencies: [
        "Services",
        .product(name: "Config", package: "Config"),
        .product(name: "Models", package: "Models"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "AudioEngine", package: "AudioEngine"),
      ],
      path: "TestSupport",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
      ]),
    .testTarget(
      name: "ServicesTests",
      dependencies: [
        "Services",
        "ServicesTestSupport",
        .product(name: "Config", package: "Config"),
        .product(name: "ConfigTestSupport", package: "Config"),
        .product(name: "Health", package: "Health"),
        .product(name: "HealthTestSupport", package: "Health"),
        .product(name: "Platform", package: "Platform"),
        .product(name: "PlatformTestSupport", package: "Platform"),
        .product(name: "Models", package: "Models"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "ModelsTestSupport", package: "Models"),
        .product(name: "AudioEngine", package: "AudioEngine"),
        .product(name: "FactoryKit", package: "Factory"),
        .product(name: "FactoryTesting", package: "Factory"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
      ]),
  ])
