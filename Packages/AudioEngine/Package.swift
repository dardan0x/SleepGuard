// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "AudioEngine",
  platforms: [.iOS(.v17), .watchOS(.v10)],
  products: [
    .library(name: "AudioEngine", targets: ["AudioEngine"]),
  ],
  dependencies: [
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.35.0"),
  ],
  targets: [
    .target(
      name: "AudioEngine",
      dependencies: [
        .product(name: "SleepLogging", package: "SleepGuardShared"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepAudioKit", package: "SleepGuardShared"),
      ],
      path: "Sources/Engine",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
      ]),
    .testTarget(
      name: "AudioEngineTests",
      dependencies: [
        "AudioEngine",
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
      ]),
  ])
