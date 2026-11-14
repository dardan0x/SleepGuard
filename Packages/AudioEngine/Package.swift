// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "AudioEngine",
  platforms: [.iOS(.v17), .watchOS(.v10)],
  products: [
    .library(name: "AudioEngine", targets: ["AudioEngine"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(path: "../../../SleepGuardShared"),
  ],
  targets: [
    .target(
      name: "AudioEngine",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      path: "Sources/Engine",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ],
      linkerSettings: [
        .linkedFramework("Accelerate"),
        .linkedFramework("SoundAnalysis"),
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
      ]),
  ])
