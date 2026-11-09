import Foundation
import Testing
@testable import DesignSystem

/// Every key in `Localizable.xcstrings` has an English value, and that value is
/// what the compiled bundle returns at runtime. (`Strings.swift` staying in sync
/// with the catalog is checked by CI's `strings-sync` job.)
struct LocalizableCatalogTests {
  static func catalogEntries() throws -> [String: String?] {
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent()
      .appendingPathComponent("Sources/Resources/Localizable.xcstrings")
    let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
    let strings = try #require(json?["strings"] as? [String: [String: Any]])
    return strings.mapValues { entry in
      let en = (entry["localizations"] as? [String: Any])?["en"] as? [String: Any]
      return (en?["stringUnit"] as? [String: Any])?["value"] as? String
    }
  }

  @Test func everyKeyHasAnEnglishValue() throws {
    let missing = try Self.catalogEntries()
      .filter { ($0.value ?? "").isEmpty }
      .map(\.key)
    #expect(missing.isEmpty, "Keys without an English value: \(missing.sorted())")
  }

  @Test func runtimeValuesMatchTheCatalog() throws {
    let entries = try Self.catalogEntries()
    #expect(entries.count > 400)
    var mismatched: [String] = []
    for (key, value) in entries {
      let runtime = String(localized: String.LocalizationValue(key), bundle: .module)
      if runtime != value {
        mismatched.append(key)
      }
    }
    #expect(mismatched.isEmpty, "Keys resolving to something else at runtime: \(mismatched.sorted())")
  }
}
