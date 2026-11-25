import Foundation
import SwiftData
import Testing
@testable import Models

@MainActor
struct SleepGuardStoreTests {
  private func makeDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("SleepGuardStoreTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }

  private func configuration(_ url: URL) -> ModelConfiguration {
    ModelConfiguration(schema: SleepGuardSchema.schema, url: url)
  }

  @Test func aStoreThatFailsToOpenIsKeptAndTheAppRunsInMemory() throws {
    let directory = try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("default.store")
    let corrupt = Data("not a sqlite store".utf8)
    try corrupt.write(to: url)

    let opening = SleepGuardStore.open(configuration(url), allowDestructiveReset: false)

    #expect(opening.failure != nil)
    let kept = try Data(contentsOf: url)
    #expect(kept == corrupt)
    let inMemory = opening.container.configurations.allSatisfy(\.isStoredInMemoryOnly)
    #expect(inMemory)
  }

  @Test func debugResetReplacesAStoreThatFailsToOpen() throws {
    let directory = try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("default.store")
    try Data("not a sqlite store".utf8).write(to: url)

    let opening = SleepGuardStore.open(configuration(url), allowDestructiveReset: true)

    #expect(opening.failure == nil)
    let onDisk = opening.container.configurations.allSatisfy { !$0.isStoredInMemoryOnly }
    #expect(onDisk)
  }

  @Test func aHealthyStoreOpensOnDisk() throws {
    let directory = try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("default.store")

    let opening = SleepGuardStore.open(configuration(url), allowDestructiveReset: false)

    #expect(opening.failure == nil)
    #expect(FileManager.default.fileExists(atPath: url.path))
  }

  @Test func backupCopiesTheStoreOncePerAppVersion() throws {
    let directory = try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("default.store")
    let backup = url.appendingPathExtension("bak")
    try Data("v1".utf8).write(to: url)

    SleepGuardStore.backUpIfNeeded(storeURL: url, appVersion: "1.0")
    let first = try Data(contentsOf: backup)
    #expect(first == Data("v1".utf8))

    try Data("v1 later".utf8).write(to: url)
    SleepGuardStore.backUpIfNeeded(storeURL: url, appVersion: "1.0")
    let sameVersion = try Data(contentsOf: backup)
    #expect(sameVersion == Data("v1".utf8))

    SleepGuardStore.backUpIfNeeded(storeURL: url, appVersion: "1.1")
    let newVersion = try Data(contentsOf: backup)
    #expect(newVersion == Data("v1 later".utf8))
  }

  @Test func backupDoesNothingWithoutAStore() throws {
    let directory = try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("default.store")

    SleepGuardStore.backUpIfNeeded(storeURL: url, appVersion: "1.0")

    #expect(!FileManager.default.fileExists(atPath: url.appendingPathExtension("bak").path))
  }
}
