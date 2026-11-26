// swift-tools-version: 6.2
import PackageDescription

/// HealthKit: sleep stages in, nights out. Split from Env (now Services) (F27-T11, ADR 0008).
let package = Package(
  name: "Health",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "Health", targets: ["Health"]),
    // Fakes and isolated stores for tests and previews.
    .library(name: "HealthTestSupport", targets: ["HealthTestSupport"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.36.0"),
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Health",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepHealthKit", package: "SleepGuardShared"),
        .product(name: "FactoryKit", package: "Factory"),
        .product(name: "SleepLogging", package: "SleepGuardShared"),
        .product(name: "SleepStore", package: "SleepGuardShared"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
      ],
      linkerSettings: [
        .linkedFramework("HealthKit"),
      ]),
    .target(
      name: "HealthTestSupport",
      dependencies: [
        "Health",
        .product(name: "Models", package: "Models"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepStore", package: "SleepGuardShared"),
      ],
      path: "TestSupport",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
      ]),
  ])
