import Env
import FactoryKit
import Foundation
import Models
import Observation
import SleepCore
import SwiftData

/// A briefing ready to show; `id` is the night it's about.
public struct PresentedBriefing: Identifiable, Sendable {
  public let id: UUID
  let briefing: Briefing
  /// The night it's about, for the survey's answer.
  let night: NightSummary
}

/// The morning briefing: when it's due (SleepCore's `BriefingSchedule`), it
/// maps the nights, the profile and the survey answers to values for
/// SleepCore's `BriefingEngine`, and keeps a survey answer as a
/// `LifestyleLog`. Owns the presented briefing so the tab view stays a container.
@MainActor
@Observable
public final class BriefingController {
  public var current: PresentedBriefing?

  private let appConfig: any AppConfigProviding
  private let preferences: any UserPreferencesStoring

  public init(
    appConfig: any AppConfigProviding = Container.shared.appConfig(),
    preferences: any UserPreferencesStoring = Container.shared.userPreferences())
  {
    self.appConfig = appConfig
    self.preferences = preferences
  }

  /// Fills `current` when the briefing is on and a new night is waiting.
  public func prepareIfDue(modelContext: ModelContext, now: Date = Date()) {
    guard appConfig.isEnabled(.sleepBriefing), preferences.briefingEnabled else { return }
    let sessions = (try? modelContext.fetch(FetchDescriptor<SleepSession>())) ?? []
    let nights = sessions.filter(\.hasCachedScore).map(Self.summary)
    guard let latest = nights.max(by: { $0.start < $1.start }),
          BriefingSchedule.isDue(latest: latest, lastShown: preferences.lastBriefingShownDate, now: now) else { return }
    let logs = ((try? modelContext.fetch(FetchDescriptor<Models.LifestyleLog>())) ?? []).map(Self.log)
    let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()))?.first?.sleepProfile ?? SleepProfile()
    let briefing = BriefingEngine.make(nights: nights, profile: profile, logs: logs, now: now)
    current = PresentedBriefing(id: latest.id, briefing: briefing, night: latest)
  }

  /// A survey answer for the briefing's night.
  public func save(_ chip: LifestyleChip, for presented: PresentedBriefing, modelContext: ModelContext) {
    let answer = SleepCore.LifestyleLog(night: presented.night.start, chips: [chip])
    modelContext.insert(Models.LifestyleLog(
      date: answer.night, hadCaffeineLate: answer.hadCaffeineLate, hadAlcohol: answer.hadAlcohol,
      exercised: answer.exercised, stressfulDay: answer.stressfulDay, lateMeal: answer.lateMeal,
      screenBeforeBed: answer.screenBeforeBed, sessionID: presented.night.id))
  }

  /// The sheet closed: not again until the next night.
  public func markShown(now: Date = Date()) {
    preferences.lastBriefingShownDate = now
    current = nil
  }

  /// The cached numbers only: reading events here has crashed before.
  static func summary(_ session: SleepSession) -> NightSummary {
    NightSummary(
      id: session.id, start: session.startDate,
      end: session.endDate ?? session.startDate.addingTimeInterval(session.totalDuration),
      score: session.cachedSleepScore, snoringDuration: session.cachedSnoringDuration, eventCount: 0)
  }

  /// A stored answer. Flags only: the positive chips other than "exercised"
  /// have no field, so they come back as an answered night with no chips.
  static func log(_ log: Models.LifestyleLog) -> SleepCore.LifestyleLog {
    var chips: Set<LifestyleChip> = []
    if log.hadCaffeineLate { chips.insert(.lateCaffeine) }
    if log.hadAlcohol { chips.insert(.alcohol) }
    if log.exercised { chips.insert(.exercised) }
    if log.stressfulDay { chips.insert(.stressfulDay) }
    if log.lateMeal { chips.insert(.lateMeal) }
    if log.screenBeforeBed { chips.insert(.screensInBed) }
    return SleepCore.LifestyleLog(night: log.date, chips: chips)
  }
}
