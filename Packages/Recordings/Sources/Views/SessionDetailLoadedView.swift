import DesignSystem
import Env
import Models
import SwiftData
import SwiftUI

/// Loaded state of the session detail screen: session header, timeline,
/// banners, event filter + list, share/delete toolbar, sheets, and the
/// export progress overlay. Data comes from `SessionDetailModel`; sharing
/// goes through `SessionShareCoordinator`.
@MainActor
struct SessionDetailLoadedView: View {
  @Environment(Theme.self) private var theme
  @Environment(AppConfig.self) private var appConfig
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  let session: SleepSession
  let isClipSession: Bool
  @Bindable var model: SessionDetailModel
  let shareCoordinator: SessionShareCoordinator

  @State private var activeSheet: SessionDetailSheet?

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        SessionDetailHeaderView(session: session, score: session.sleepScore(using: appConfig.sleepScoreConfig))

        SessionDetailTimelineView(session: session)

        MelodyGapsBannerView(session: session)

        LowBatteryBannerView(session: session)

        if model.shouldShowFilter {
          Picker("", selection: $model.selectedFilter) {
            ForEach(model.availableFilters, id: \.self) { filter in
              Text(filter.displayName).tag(filter)
            }
          }
          .pickerStyle(.segmented)
        }

        SessionDetailEventsView(
          events: model.filteredEvents,
          displayDurations: model.displayDurations,
          title: eventsTitle,
          onShowAll: { activeSheet = .events },
          onPlayEvent: { event in
            activeSheet = .player(initialEvent: event)
          },
          onShareEvent: { event in
            shareCoordinator.shareEvent(event, in: session)
          })

        if !model.shortEvents.isEmpty {
          Button {
            activeSheet = .shortEventsPlayer
          } label: {
            HStack(spacing: 8) {
              Image(systemName: "waveform")
                .font(.system(size: 14, weight: .semibold))
              Text(String(format: Strings.sessionDetailHiddenEventsFormat, model.shortEvents.count))
                .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(theme.accent.opacity(0.12))
            .cornerRadius(theme.radiusCard)
          }
        }
      }
      .padding(20)
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text(DateFormatters.dayOfWeekAndDate.string(from: session.startDate))
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(theme.textPrimary)
      }
      ToolbarItem(placement: .topBarTrailing) {
        HStack(spacing: 16) {
          if appConfig.isEnabled(.pdfReport) {
            Button {
              shareCoordinator.exportReport(for: session)
            } label: {
              Image(systemName: shareCoordinator.isGeneratingPDF ? "clock" : "doc.text")
                .font(.system(size: 17))
                .foregroundStyle(shareCoordinator.isGeneratingPDF ? theme.textTertiary : theme.accent)
            }
            .disabled(shareCoordinator.isGeneratingPDF)
          }
          if !isClipSession, session.audioFileURL != nil {
            Button {
              shareCoordinator.shareFullSession(session)
            } label: {
              Image(systemName: "square.and.arrow.up")
                .font(.system(size: 17))
                .foregroundStyle(theme.accent)
            }
          }
          Button {
            if model.delete(modelContext: modelContext) {
              dismiss()
            }
          } label: {
            Image(systemName: "trash")
              .font(.system(size: 17))
              .foregroundStyle(theme.destructive)
          }
        }
      }
    }
    .sheet(item: $activeSheet) { sheet in
      switch sheet {
      case let .player(initialEvent):
        let episodeEvents = initialEvent.map { session.episodePlaybackEvents(for: $0) } ?? model.filteredEvents
        PlayerSheetView(
          session: session,
          sortedEvents: episodeEvents,
          isClipSession: isClipSession,
          initialEvent: episodeEvents.first ?? initialEvent)
      case .events:
        EventsSheetView(
          session: session,
          events: model.filteredEvents,
          displayDurations: model.displayDurations,
          isClipSession: isClipSession,
          onPlayEvent: { _ in })
      case .shortEventsPlayer:
        PlayerSheetView(
          session: session,
          sortedEvents: model.shortEvents,
          isClipSession: isClipSession,
          initialEvent: nil)
      }
    }
    .overlay {
      if shareCoordinator.isExportingEvent {
        ZStack {
          theme.bgPrimary.opacity(0.7)
            .ignoresSafeArea()
          ProgressView()
            .scaleEffect(1.5)
            .tint(theme.accent)
        }
      }
    }
  }

  /// Localized events-section header — view-layer mapping of the model's
  /// selected filter (see the MARK note at the bottom of this file).
  private var eventsTitle: String {
    switch model.selectedFilter {
    case .all: Strings.sessionRecordingEventsFormatAll
    case .snoring: Strings.sessionRecordingEventsFormatSnoring
    case .sleepTalking: Strings.sessionRecordingEventsFormatSleepTalking
    case .noise: Strings.sessionRecordingEventsFormatNoise
    }
  }
}

enum SessionDetailSheet: Identifiable {
  case player(initialEvent: SnoreEvent?)
  case events
  case shortEventsPlayer

  var id: String {
    switch self {
    case let .player(event):
      event.map { "player-\($0.id.uuidString)" } ?? "player"
    case .events:
      "events"
    case .shortEventsPlayer:
      "short-events-player"
    }
  }
}

// MARK: - Presentation mappings

//
// Label text lives in the view layer (see AGENTS.md "UI Dependencies in
// Non-View Code"): the filter enum and its selection logic stay in
// SessionDetailModel; only the display strings are mapped here.

extension SessionDetailModel.EventCategoryFilter {
  var displayName: String {
    switch self {
    case .all: Strings.filterAll
    case .snoring: Strings.filterSnoring
    case .sleepTalking: Strings.filterSleepTalking
    case .noise: Strings.filterNoise
    }
  }
}
