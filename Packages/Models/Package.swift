// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Models",
  platforms: [.iOS(.v17), .watchOS(.v10)],
  products: [
    .library(name: "Models", targets: ["Models"]),
  ],
  targets: [
    .target(
      name: "Models",
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
    .testTarget(
      name: "ModelsTests",
      dependencies: ["Models"],
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
  ])
