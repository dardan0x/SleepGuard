// swift-tools-version: 6.2
import PackageDescription

/// Navigation contract between feature packages: route enums + the per-tab
/// `RouterPath`. A leaf package (SwiftUI only) so adding a screen doesn't
/// rebuild the service layer. See docs/adr/0001-routing-package.md.
let package = Package(
  name: "Routing",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "Routing", targets: ["Routing"]),
  ],
  targets: [
    .target(
      name: "Routing",
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
    .testTarget(
      name: "RoutingTests",
      dependencies: ["Routing"],
      path: "Tests",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
  ])
