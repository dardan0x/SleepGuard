// swift-tools-version: 6.2
import PackageDescription

/// The app's `os.Logger` categories and signposter. A leaf: it imports only
/// `os`, so any package can log without depending on the data model.
let package = Package(
  name: "Logging",
  platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
  products: [
    .library(name: "Logging", targets: ["Logging"]),
  ],
  targets: [
    .target(
      name: "Logging",
      path: "Sources",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("InternalImportsByDefault"),
      ]),
  ])
