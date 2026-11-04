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
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
  ])
