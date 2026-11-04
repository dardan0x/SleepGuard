import Foundation
import SwiftData

/// Per-night lifestyle deviation log.
/// Records what changed on a given night so the app can correlate
/// habits with sleep quality over time.
@Model
public final class LifestyleLog {
  @Attribute(.unique) public var id: UUID

  /// The night this log refers to (typically the start of the sleep session).
  public var date: Date

  /// Deviations from baseline
  public var hadCaffeineLate: Bool
  public var hadAlcohol: Bool
  public var exercised: Bool
  public var stressfulDay: Bool
  public var lateMeal: Bool
  public var screenBeforeBed: Bool

  /// Optional free-text note
  public var note: String?

  /// Link to the SleepSession this log explains, if any.
  public var sessionID: UUID?

  public init(
    id: UUID = UUID(),
    date: Date,
    hadCaffeineLate: Bool = false,
    hadAlcohol: Bool = false,
    exercised: Bool = false,
    stressfulDay: Bool = false,
    lateMeal: Bool = false,
    screenBeforeBed: Bool = false,
    note: String? = nil,
    sessionID: UUID? = nil)
  {
    self.id = id
    self.date = date
    self.hadCaffeineLate = hadCaffeineLate
    self.hadAlcohol = hadAlcohol
    self.exercised = exercised
    self.stressfulDay = stressfulDay
    self.lateMeal = lateMeal
    self.screenBeforeBed = screenBeforeBed
    self.note = note
    self.sessionID = sessionID
  }
}
