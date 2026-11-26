public import Config
public import FactoryKit
public import Foundation
import Models
public import Services
public import Observation
public import SleepCore
public import SwiftData

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
  private let profiles: any ProfileStoring
  private let lifestyleLogs: any LifestyleLogStoring

  public init(
    appConfig: any AppConfigProviding = Container.shared.appConfig(),
    preferences: any UserPreferencesStoring = Container.shared.userPreferences(),
    profiles: any ProfileStoring = Container.shared.profileStore(),
    lifestyleLogs: any LifestyleLogStoring = Container.shared.lifestyleLogStore())
  {
    self.appConfig = appConfig
    self.preferences = preferences
    self.profiles = profiles
    self.lifestyleLogs = lifestyleLogs
  }

  /// Fills `current` when the briefing is on and a new night is waiting.
  public func prepareIfDue(modelContext: ModelContext, now: Date = Date()) {
    guard appConfig.isEnabled(.sleepBriefing), preferences.briefingEnabled else { return }
    let sessions = (try? modelContext.fetch(FetchDescriptor<NightRecord>())) ?? []
    let nights = sessions.filter(\.hasSummary).map(Self.summary)
    guard let latest = nights.max(by: { $0.start < $1.start }),
          BriefingSchedule.isDue(latest: latest, lastShown: preferences.lastBriefingShownDate, now: now) else { return }
    let briefing = BriefingEngine.make(nights: nights, profile: profiles.profile, logs: lifestyleLogs.logs, now: now)
    current = PresentedBriefing(id: latest.id, briefing: briefing, night: latest)
  }

  /// A survey answer for the briefing's night.
  /// Every chip is kept now (the old model had fields for six of the ten).
  public func save(_ chip: LifestyleChip, for presented: PresentedBriefing) {
    let answer = LifestyleLog(night: presented.night.start, chips: [chip])
    let logs = lifestyleLogs
    Task { await logs.save(answer) }
  }

  /// The sheet closed: not again until the next night.
  public func markShown(now: Date = Date()) {
    preferences.lastBriefingShownDate = now
    current = nil
  }

  /// The cached numbers only: reading events here has crashed before.
  static func summary(_ session: NightRecord) -> NightSummary {
    NightSummary(
      id: session.id, start: session.start,
      end: session.end,
      score: session.score, snoringDuration: session.snoringDuration, eventCount: 0)
  }
}
