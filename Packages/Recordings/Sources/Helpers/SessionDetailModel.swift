import Config
import FactoryKit
import Foundation
import Health
import Models
import os
import Services
import SleepCore
import SwiftData

/// State owner for the session detail screen: loads the session (read only),
/// then enriches it (late HealthKit stages, a stale cached score) as a separate
/// command, owns the event category filter and its derived event lists, and
/// performs deletion. Created by the view once the
/// environment dependencies are available.
@MainActor
@Observable
final class SessionDetailModel {
  enum ViewState {
    case loading
    case loaded(session: NightRecord, sortedEvents: [NightEventRecord], isClipSession: Bool)
    case error
  }

  private(set) var viewState: ViewState = .loading
  /// The event list's filter (SleepCore's `EventFilter`).
  var selectedFilter: EventFilter = .all

  private let sessionID: UUID
  private let appConfig: any AppConfigProviding
  private let userPreferences: any UserPreferencesStoring
  private let healthKitSync: any HealthKitSyncing

  /// Collaborators are parameters defaulting to the container, like every
  /// non-view type: tests pass fakes directly or register them.
  init(
    sessionID: UUID,
    appConfig: any AppConfigProviding,
    userPreferences: any UserPreferencesStoring,
    healthKitSync: any HealthKitSyncing = Container.shared.healthKitSync())
  {
    self.sessionID = sessionID
    self.appConfig = appConfig
    self.userPreferences = userPreferences
    self.healthKitSync = healthKitSync
  }

  /// Reads the night. Never writes: opening a screen doesn't change storage.
  func load(modelContext: ModelContext) {
    do {
      guard let session = try fetchSession(in: modelContext) else {
        viewState = .error
        return
      }
      let sortedEvents = session.events.sorted(by: { $0.start < $1.start })
      let isClipSession = sortedEvents.contains(where: { AudioFileURLResolver.resolve($0.clipFileName) != nil })
      viewState = .loaded(session: session, sortedEvents: sortedEvents, isClipSession: isClipSession)
    } catch {
      viewState = .error
    }
  }

  /// The one write the screen may cause: sleep stages that arrived from
  /// HealthKit after the night was saved, or a score cached by an older
  /// formula. Saves only when something changed. A failure is logged and the
  /// loaded night stays on screen.
  func enrichIfNeeded(modelContext: ModelContext) async {
    guard case let .loaded(session, _, _) = viewState else { return }
    var changed = false
    // A night without stages asks Health each time it opens: the Watch's
    // data can arrive hours later.
    if appConfig.isEnabled(.enhancedSleepTracking),
       userPreferences.enhancedSleepTracking,
       session.sleepStages.isEmpty
    {
      let stages = await healthKitSync.fetchSleepStages(for: session)
      if !stages.isEmpty {
        session.sleepStages = stages
        changed = true
      }
    }
    let config = appConfig.sleepScoreConfig
    guard changed || session.hasStaleSummary(for: config) else { return }
    session.refreshSummary(using: config)
    do {
      try modelContext.save()
    } catch {
      Log.storage.error("Saving the night's stages/score failed: \(String(describing: error), privacy: .public)")
    }
  }

  /// Deletes the night: its rows first, then (once that is saved) its audio
  /// files. A failure leaves files without a row, never a row without its
  /// files; storage limits clean up orphans. Returns false when the delete
  /// failed and the night is still there.
  func delete(modelContext: ModelContext) -> Bool {
    do {
      guard let session = try fetchSession(in: modelContext) else { return true }
      let files = sessionFileURLs(session)
      // Events first with an intermediate save: deleting a faulted
      // relationship in one cascade has crashed SwiftData.
      if !session.events.isEmpty {
        for event in session.events {
          modelContext.delete(event)
        }
        try modelContext.save()
      }
      // Resolve transformable faults before deletion.
      _ = session.sleepStages
      _ = session.recordingGaps
      modelContext.delete(session)
      try modelContext.save()
      removeFiles(files)
      return true
    } catch {
      modelContext.rollback()
      Log.storage.error("Deleting a night failed: \(String(describing: error), privacy: .public)")
      return false
    }
  }

  private func fetchSession(in modelContext: ModelContext) throws -> NightRecord? {
    let descriptor = FetchDescriptor<NightRecord>(predicate: #Predicate { $0.id == sessionID })
    return try modelContext.fetch(descriptor).first
  }

  // MARK: - Filter & derived events

  /// The loaded night as SleepCore's value: what the shared detail content and
  /// the event-list rules read.
  var night: Night? {
    guard case let .loaded(session, _, _) = viewState else { return nil }
    return session.night
  }

  /// SleepCore's rule: every filter once the night has two kinds of event;
  /// sleep talking only while that detection is on.
  var filters: [EventFilter] {
    guard let night else { return [] }
    return EventFilter.options(for: night.events, includeSleepTalking: appConfig.isEnabled(.sleepTalkingDetection))
  }

  /// The event list under the filter (SleepCore's `EventListRow`).
  var rows: [EventListRow] {
    guard let night else { return [] }
    return EventListRow.rows(for: night, filter: selectedFilter)
  }

  /// The stored event a row plays or shares.
  func event(for row: EventListRow) -> NightEventRecord? {
    guard case let .loaded(_, sortedEvents, _) = viewState else { return nil }
    return sortedEvents.first { $0.id == row.id }
  }

  /// Short snoring episodes (under 3 sec) shown in the dedicated player.
  var shortEvents: [NightEventRecord] {
    guard case let .loaded(session, _, _) = viewState else { return [] }
    let shortEpisodes = session.snoringEpisodes.filter { $0.snoreDuration < 3 }
    return shortEpisodes.compactMap(\.representativeEvent)
      .sorted(by: { $0.start < $1.start })
  }
}
