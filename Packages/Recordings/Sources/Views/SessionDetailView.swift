import SwiftUI
import SwiftData
import Models
import Env
import DesignSystem

@MainActor
public struct SessionDetailView: View {
  let sessionID: UUID

  @Environment(Theme.self) private var theme
  @Environment(AppConfig.self) private var appConfig
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(\.modelContext) private var modelContext

  /// Created on first appearance — needs the environment-provided
  /// `AppConfig`/`UserPreferences`, so it cannot be a plain initializer.
  @State private var model: SessionDetailModel?
  @State private var shareCoordinator = SessionShareCoordinator()

  public init(sessionID: UUID) {
    self.sessionID = sessionID
  }

  public var body: some View {
    Group {
      if let model {
        switch model.viewState {
        case .loading:
          Color.clear
            .task {
              await model.load(modelContext: modelContext)
            }
        case .loaded(let session, _, let isClipSession):
          SessionDetailLoadedView(
            session: session,
            isClipSession: isClipSession,
            model: model,
            shareCoordinator: shareCoordinator
          )
        case .error:
          errorBody
        }
      } else {
        Color.clear
          .task {
            model = SessionDetailModel(
              sessionID: sessionID,
              appConfig: appConfig,
              userPreferences: userPreferences
            )
          }
      }
    }
    .background(theme.bgPrimary.ignoresSafeArea())
  }

  private var errorBody: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundStyle(theme.textTertiary)

      Text(Strings.recordingsErrorMessage)
        .font(.headline)
        .foregroundStyle(theme.textPrimary)
    }
  }

  // MARK: - Fake Player Placeholder
  //
  // NOTE: `fakePlayerSection` and the marker helpers below are only referenced
  // from the commented-out mini player call site in the loaded body. Kept
  // verbatim during the F18 split; safe to delete if the mini player is not
  // coming back.

  private func fakePlayerSection(session: SleepSession, sortedEvents: [SnoreEvent], isClipSession: Bool) -> some View {
    let totalDuration: TimeInterval = isClipSession
      ? sortedEvents.map { $0.snoreDuration }.reduce(0, +)
      : session.totalDuration
    let markers = isClipSession
      ? clipEventMarkers(events: sortedEvents, totalDuration: totalDuration)
      : legacyEventMarkers(session: session, sortedEvents: sortedEvents)
    let colors = eventMarkerColors(events: sortedEvents)

    return VStack(alignment: .leading, spacing: 8) {
      Text(Strings.recordingsDetailTimelineLabel)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1)

      SessionDetailMiniPlayerView(
        session: session,
        isPlaying: false,
        progress: 0,
        totalDuration: totalDuration,
        eventMarkers: markers,
        eventMarkerColors: colors,
        isExpandable: false,
        showsPlaybackButton: false,
        onTogglePlayback: {},
        onScrub: { _ in },
        onExpand: {}
      )
    }
  }

  private func clipEventMarkers(events: [SnoreEvent], totalDuration: TimeInterval) -> [Double] {
    guard totalDuration > 0 else { return [] }
    var accumulated: TimeInterval = 0
    var markers: [Double] = []
    for event in events {
      markers.append(accumulated / totalDuration)
      accumulated += event.snoreDuration
    }
    return markers
  }

  private func legacyEventMarkers(session: SleepSession, sortedEvents: [SnoreEvent]) -> [Double] {
    let total = session.totalDuration
    guard total > 0 else { return [] }
    return sortedEvents.map { $0.timestamp.timeIntervalSince(session.startDate) / total }
  }

  private func eventMarkerColors(events: [SnoreEvent]) -> [Color] {
    events.map { theme.intensityColor($0.intensity) }
  }
}
