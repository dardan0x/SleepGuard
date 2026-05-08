// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Models",
  platforms: [.iOS(.v17), .watchOS(.v10)],
  products: [
    .library(name: "Models", targets: ["Models"]),
  ],
  targets: [
    .target(
      name: "Models"
    ),
  ]
)
