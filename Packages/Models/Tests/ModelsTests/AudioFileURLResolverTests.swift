import Foundation
import Testing
@testable import Models

/// Stored audio references are resolved against the *current* Documents
/// folder, because its absolute path changes between app launches.
struct AudioFileURLResolverTests {
  /// Creates a uniquely named file in Documents and removes it afterwards.
  private func withTempFile(_ body: (String) throws -> Void) throws {
    let name = "resolver-test-\(UUID().uuidString).m4a"
    let url = AudioFileURLResolver.url(for: name)
    try Data([0]).write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    try body(name)
  }

  @Test func filenameOnlyResolvesInDocuments() throws {
    try withTempFile { name in
      let url = AudioFileURLResolver.resolve(name)
      #expect(url == AudioFileURLResolver.documentsDirectory.appendingPathComponent(name))
    }
  }

  @Test func legacyAbsolutePathFromAnOldContainerResolvesToCurrentDocuments() throws {
    try withTempFile { name in
      let stale = "/var/mobile/Containers/Data/Application/OLD-UUID/Documents/\(name)"
      #expect(AudioFileURLResolver.resolve(stale) == AudioFileURLResolver.url(for: name))
    }
  }

  @Test(arguments: [nil, "", "missing-\(UUID().uuidString).m4a"])
  func unresolvableValuesReturnNil(stored: String?) {
    #expect(AudioFileURLResolver.resolve(stored) == nil)
  }

  @Test func filenameStripsTheDirectory() {
    let url = URL(fileURLWithPath: "/some/where/clip.m4a")
    #expect(AudioFileURLResolver.filename(from: url) == "clip.m4a")
  }
}
