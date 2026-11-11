import AudioEngine
import Env
import Foundation
import Models
import Observation
import SwiftData

/// In-memory `PendingSessionStoring`.
@MainActor
public final class FakePendingSessionStore: PendingSessionStoring {
  public private(set) var pendingSessionID: UUID?
  public private(set) var files: [String] = []
  public private(set) var cleanupCount = 0

  public init() {}

  public func setPending(sessionID: UUID, sessionAudioFilename: String?) {
    pendingSessionID = sessionID
    if let sessionAudioFilename { files.append(sessionAudioFilename) }
  }

  public func addFile(_ filename: String) { files.append(filename) }

  public func clearPending() {
    pendingSessionID = nil
    files = []
  }

  public func cleanupIfNeeded() { cleanupCount += 1 }
}

/// In-memory `SessionCheckpointStoring`.
@MainActor
public final class FakeSessionCheckpointStore: SessionCheckpointStoring {
  public private(set) var snapshot: SessionRecoverySnapshot?

  public init(snapshot: SessionRecoverySnapshot? = nil) {
    self.snapshot = snapshot
  }

  public func write(_ snapshot: SessionRecoverySnapshot) { self.snapshot = snapshot }
  public func loadIfPresent() -> SessionRecoverySnapshot? { snapshot }
  public func clear() { snapshot = nil }
}

/// In-memory `CustomMelodyStoring`. `saveRecording` stores a melody with no file.
@MainActor
@Observable
public final class FakeCustomMelodyStorage: CustomMelodyStoring {
  public private(set) var customMelodies: [Melody]

  public init(customMelodies: [Melody] = []) {
    self.customMelodies = customMelodies
  }

  public func allCustomMelodies() -> [Melody] { customMelodies }
  public func melody(id: Int) -> Melody? { customMelodies.first { $0.id == id } }
  public func melody(filename: String) -> Melody? { customMelodies.first { $0.filename == filename } }

  public func saveRecording(name: String, from tempURL: URL) -> Melody? {
    let id = (customMelodies.map(\.id).max() ?? 1000) + 1
    let melody = Melody(id: id, name: name, filename: tempURL.lastPathComponent, isCustom: true)
    customMelodies.append(melody)
    return melody
  }

  public func deleteMelody(id: Int) { customMelodies.removeAll { $0.id == id } }
  public func fileURL(for _: Melody) -> URL? { nil }
}

/// Never touches files; reports nothing removed. Counts calls.
public final class FakeStorageLimitEnforcer: StorageLimitEnforcing {
  @MainActor public private(set) var enforceCount = 0

  public init() {}

  @MainActor
  public func enforceLimits(modelContext _: ModelContext) async -> CleanupReport {
    enforceCount += 1
    return CleanupReport()
  }

  #if DEBUG
  @MainActor
  public func injectDummyAudioForTesting(modelContext _: ModelContext) -> Int { 0 }
  #endif
}

/// Collects raw-log samples in memory.
public actor FakeSessionRawLogWriter: SessionRawLogWriting {
  public private(set) var metadata: RawLogMetadata?
  public private(set) var appendCount = 0
  public private(set) var stopped = false

  public init() {}

  public func start(sessionID _: UUID, metadata: RawLogMetadata) { self.metadata = metadata }

  public func append(
    at _: Date, db _: Float, peakDB _: Float?, spectralScore _: Float,
    snoreConfidence _: Float, speechConfidence _: Float, state _: DetectionState)
  {
    appendCount += 1
  }

  public func stop() -> String? {
    stopped = true
    return nil
  }

  public func discard() { metadata = nil }
}
