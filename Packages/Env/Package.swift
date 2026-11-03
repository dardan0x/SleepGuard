// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Env",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "Env", targets: ["Env"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(path: "../AudioEngine"),
  ],
  targets: [
    .target(
      name: "Env",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "AudioEngine", package: "AudioEngine"),
      ],
      path: "Sources/Services",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ],
      linkerSettings: [
        .linkedFramework("HealthKit"),
        .linkedFramework("WatchConnectivity"),
      ]
    ),
  ]
)
