import Foundation
public import Observation
public import SleepCore

/// The person's profile: SleepGuardShared's `SleepProfile`, kept in the
/// shared `ProfileFile` (the same file SleepGuardUIKitWay keeps). Observable,
/// so the editor and the prompt card follow it. Fake: `FakeProfileStore`.
@MainActor
public protocol ProfileStoring: AnyObject, Observable {
  var profile: SleepProfile { get }
  /// Reads the file (at launch).
  func load() async
  /// The new profile now; written to disk right after.
  func update(_ profile: SleepProfile)
}

/// The briefing survey's answers: SleepGuardShared's `LifestyleLog`, kept in
/// the shared `LifestyleLogFile`. Fake: `FakeLifestyleLogStore`.
@MainActor
public protocol LifestyleLogStoring: AnyObject {
  var logs: [LifestyleLog] { get }
  /// Reads the file (at launch).
  func load() async
  /// Keeps an answer (a new one for a night replaces the old one).
  func save(_ log: LifestyleLog) async
  /// Every answer at once (sample data).
  func replaceAll(with logs: [LifestyleLog]) async
}
