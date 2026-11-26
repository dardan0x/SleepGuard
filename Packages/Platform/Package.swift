// swift-tools-version: 6.2
import PackageDescription

/// Device services: haptics, notification permission, the Watch link. The
/// UIKit-touching services, split from Env (now Services) (F27-T11, ADR 0008).
let package = Package(
  name: "Platform",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "Platform", targets: ["Platform"]),
    // Fakes and isolated stores for tests and previews.
    .library(name: "PlatformTestSupport", targets: ["PlatformTestSupport"]),
  ],
  dependencies: [
    .package(url: "https://github.com/hmlongco/Factory", from: "3.5.2"),
  ],
  targets: [
    .target(
      name: "Platform",
      dependencies: [
        .product(name: "FactoryKit", package: "Factory"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
      ],
      linkerSettings: [
        .linkedFramework("WatchConnectivity"),
      ]),
    .target(
      name: "PlatformTestSupport",
      dependencies: [
        "Platform",
      ],
      path: "TestSupport",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
      ]),
  ])
