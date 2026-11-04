// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Onboarding",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Onboarding", targets: ["Onboarding"]),
  ],
  dependencies: [
    .package(path: "../Models"),
    .package(path: "../AudioEngine"),
    .package(path: "../Env"),
    .package(path: "../DesignSystem"),
  ],
  targets: [
    .target(
      name: "Onboarding",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "AudioEngine", package: "AudioEngine"),
        .product(name: "Env", package: "Env"),
        .product(name: "DesignSystem", package: "DesignSystem"),
      ],
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
  ])
