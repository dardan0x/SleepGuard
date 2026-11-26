public import Foundation
import Models
public import Observation
public import SleepCore
import SleepFiles

/// `ProfileStoring` over the shared `ProfileFile`. Writes are serial and the
/// latest wins, so editing (one write per change) never reorders.
@MainActor
@Observable
public final class ProfileStore: ProfileStoring {
  public static let shared = ProfileStore()

  public private(set) var profile = SleepProfile()
  @ObservationIgnored private let file: ProfileFile
  @ObservationIgnored private var writing: Task<Void, Never>?

  /// `nil`: the app's profile file (`SleepGuardStorage`); tests pass their own.
  public init(url: URL? = nil) {
    file = ProfileFile(url: url ?? SleepGuardStorage.location.profileURL)
  }

  public func load() async {
    profile = await file.load()
  }

  public func update(_ profile: SleepProfile) {
    self.profile = profile
    let previous = writing
    let file = file
    writing = Task {
      await previous?.value
      do {
        try await file.save(profile)
      } catch {
        Log.storage.error("Profile not saved: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  /// Waits for the writes so far (tests).
  func flush() async {
    await writing?.value
  }
}

/// `LifestyleLogStoring` over the shared `LifestyleLogFile`.
@MainActor
public final class LifestyleLogStore: LifestyleLogStoring {
  public static let shared = LifestyleLogStore()

  public private(set) var logs: [LifestyleLog] = []
  private let file: LifestyleLogFile

  /// `nil`: the app's survey file (`SleepGuardStorage`); tests pass their own.
  public init(url: URL? = nil) {
    file = LifestyleLogFile(url: url ?? SleepGuardStorage.location.lifestyleLogURL)
  }

  public func load() async {
    logs = await file.logs()
  }

  public func save(_ log: LifestyleLog) async {
    do {
      try await file.save(log)
      logs = await file.logs()
    } catch {
      Log.storage.error("Survey answer not saved: \(error.localizedDescription, privacy: .public)")
    }
  }

  public func replaceAll(with logs: [LifestyleLog]) async {
    do {
      try await file.save(logs)
      self.logs = logs
    } catch {
      Log.storage.error("Survey answers not saved: \(error.localizedDescription, privacy: .public)")
    }
  }
}
