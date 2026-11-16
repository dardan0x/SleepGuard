import Env
import FactoryKit
import Foundation
import Models
import SleepCore
import SwiftData

/// State owner for the session detail screen: loads the session (with the
/// defensive cached-score refresh), owns the event category filter and its
/// derived event lists, and performs deletion. Created by the view once the
/// environment dependencies are available.
@MainActor
@Observable
final class SessionDetailModel {
  enum ViewState {
    case loading
    case loaded(session: SleepSession, sortedEvents: [SnoreEvent], isClipSession: Bool)
    case error
  }

  private(set) var viewState: ViewState = .loading
  /// The event list's filter (SleepCore's `EventFilter`).
  var selectedFilter: EventFilter = .all

  private let sessionID: UUID
  private let appConfig: any AppConfigProviding
  private let userPreferences: any UserPreferencesStoring
  private let healthKitSync: any HealthKitSyncing

  init(sessionID: UUID, appConfig: any AppConfigProviding, userPreferences: any UserPreferencesStoring) {
    self.sessionID = sessionID
    self.appConfig = appConfig
    self.userPreferences = userPreferences
    // @Observable can't use @Injected (macro collision): resolve in init.
    healthKitSync = Container.shared.healthKitSync()
  }

  func load(modelContext: ModelContext) async {
    do {
      let descriptor = FetchDescriptor<SleepSession>(
        predicate: #Predicate { $0.id == sessionID }
      )
      if let session = try modelContext.fetch(descriptor).first {
        let stagesEmptyAndOld = (session.sleepStageSegments?.isEmpty == true)
          && (session.endDate?.timeIntervalSinceNow ?? 0) < -3600
        if appConfig.isEnabled(.enhancedSleepTracking),
           userPreferences.enhancedSleepTracking,
           session.sleepStageSegments == nil || stagesEmptyAndOld
        {
          let stages = await healthKitSync.fetchSleepStages(for: session)
          session.sleepStageSegments = stages.isEmpty ? [] : stages
        }

        // Recalculate cached score and snoring duration to pick up scoring
        // formula changes (e.g. episode merging, gap inclusion, remote config
        // penalty updates) while the session relationship is hot.
        session.refreshCachedScore(using: appConfig.sleepScoreConfig)
        try modelContext.save()

        let sortedEvents = session.events?.sorted(by: { $0.timestamp < $1.timestamp }) ?? []
        let isClipSession = sortedEvents.contains(where: { AudioFileURLResolver.resolve($0.audioFileURL) != nil })
        viewState = .loaded(session: session, sortedEvents: sortedEvents, isClipSession: isClipSession)
      } else {
        viewState = .error
      }
    } catch {
      viewState = .error
    }
  }

  /// Deletes the session and its audio files. Returns true when the deletion
  /// completed (the caller dismisses the screen in that case).
  @discardableResult
  func delete(modelContext: ModelContext) -> Bool {
    do {
      let descriptor = FetchDescriptor<SleepSession>(
        predicate: #Predicate { $0.id == sessionID }
      )
      if let session = try modelContext.fetch(descriptor).first {
        // Delete files while `session.events` still lists the event clips.
        deleteSessionFiles(session)

        // Delete events first with intermediate save to avoid SwiftData
        // faulting crash during cascade delete.
        if let events = session.events {
          for event in events {
            modelContext.delete(event)
          }
          try modelContext.save()
        }

        // Resolve transformable faults before deletion
        _ = session.sleepStageSegments
        _ = session.recordingGaps
        modelContext.delete(session)
        try modelContext.save()
        return true
      }
      return false
    } catch {
      // Deletion failed; fail silently
      return false
    }
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
  func event(for row: EventListRow) -> SnoreEvent? {
    guard case let .loaded(_, sortedEvents, _) = viewState else { return nil }
    return sortedEvents.first { $0.id == row.id }
  }

  /// Short snoring episodes (under 3 sec) shown in the dedicated player.
  var shortEvents: [SnoreEvent] {
    guard case let .loaded(session, _, _) = viewState else { return [] }
    let shortEpisodes = session.snoringEpisodes.filter { $0.snoreDuration < 3 }
    return shortEpisodes.compactMap(\.representativeEvent)
      .sorted(by: { $0.timestamp < $1.timestamp })
  }
}
