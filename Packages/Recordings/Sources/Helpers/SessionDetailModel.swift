import Env
import Foundation
import Models
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

  enum EventCategoryFilter: String, CaseIterable {
    case all
    case snoring
    case sleepTalking
    case noise

    func includes(event: SnoreEvent) -> Bool {
      switch self {
      case .all: true
      case .snoring: event.category == .snoring
      case .sleepTalking: event.category == .sleepTalking
      case .noise: event.category == .noise || event.category == .coughing || event.category == .other
      }
    }
  }

  private(set) var viewState: ViewState = .loading
  var selectedFilter: EventCategoryFilter = .all

  private let sessionID: UUID
  private let appConfig: AppConfig
  private let userPreferences: UserPreferences

  init(sessionID: UUID, appConfig: AppConfig, userPreferences: UserPreferences) {
    self.sessionID = sessionID
    self.appConfig = appConfig
    self.userPreferences = userPreferences
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
          let stages = await HealthKitSync.shared.fetchSleepStages(for: session)
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

  var availableFilters: [EventCategoryFilter] {
    if appConfig.isEnabled(.sleepTalkingDetection) {
      return EventCategoryFilter.allCases
    }
    return EventCategoryFilter.allCases.filter { $0 != .sleepTalking }
  }

  var shouldShowFilter: Bool {
    guard case let .loaded(_, sortedEvents, _) = viewState else { return false }
    let relevantCategories = sortedEvents.compactMap { event -> EventCategoryFilter? in
      switch event.category {
      case .snoring: return .snoring
      case .sleepTalking: return appConfig.isEnabled(.sleepTalkingDetection) ? .sleepTalking : nil
      case .noise, .coughing, .other: return .noise
      }
    }
    return Set(relevantCategories).count > 1
  }

  /// Display duration overrides for episode representatives.
  /// Uses the episode's full snoring span so melody gaps where snoring
  /// resumed are included, matching the stat calculation.
  var displayDurations: [UUID: TimeInterval] {
    guard case let .loaded(session, _, _) = viewState else { return [:] }
    var map: [UUID: TimeInterval] = [:]
    for episode in session.displayableSnoringEpisodes {
      if let rep = episode.representativeEvent {
        map[rep.id] = episode.snoreDuration
      }
    }
    return map
  }

  /// Short snoring episodes (under 3 sec) shown in the dedicated player.
  var shortEvents: [SnoreEvent] {
    guard case let .loaded(session, _, _) = viewState else { return [] }
    let shortEpisodes = session.snoringEpisodes.filter { $0.snoreDuration < 3 }
    return shortEpisodes.compactMap(\.representativeEvent)
      .sorted(by: { $0.timestamp < $1.timestamp })
  }

  /// Events for display: displayable snoring episodes + non-snoring events.
  var filteredEvents: [SnoreEvent] {
    guard case let .loaded(session, sortedEvents, _) = viewState else { return [] }

    switch selectedFilter {
    case .snoring:
      return session.displayableSnoringEpisodes.compactMap(\.representativeEvent)
    case .sleepTalking, .noise:
      return sortedEvents.filter { selectedFilter.includes(event: $0) }
    case .all:
      let reps = session.displayableSnoringEpisodes.compactMap(\.representativeEvent)
      let others = sortedEvents.filter { $0.category != .snoring }
      return (reps + others).sorted(by: { $0.timestamp < $1.timestamp })
    }
  }
}
