import Config
import DesignSystem
import FactoryKit
import Models
import SleepCore
import SwiftData
import SwiftUI

/// Loaded state of the session detail screen: session header, timeline,
/// banners, event filter + list, share/delete toolbar, sheets, and the
/// export progress overlay. Data comes from `SessionDetailModel`; sharing
/// goes through `SessionShareCoordinator`.
@MainActor
struct SessionDetailLoadedView: View {
  @Environment(\.theme) private var theme
  @Injected(\.appConfig) private var appConfig
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  let session: NightRecord
  let isClipSession: Bool
  @Bindable var model: SessionDetailModel
  let shareCoordinator: SessionShareCoordinator

  @State private var activeSheet: SessionDetailSheet?
  @State private var deleteFailed = false

  /// The report's title and footer name the app, as SleepGuard's did.
  static var appName: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
      ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "SleepGuard"
  }

  var body: some View {
    ScrollView {
      // The shared content (ADR 0006); sleep stages and the short-events
      // button go in its slots.
      if let night = model.night {
        NightDetailContent(
          night: night,
          summary: night.summary(using: appConfig.sleepScoreConfig),
          filters: model.filters,
          filter: $model.selectedFilter,
          onPlay: { row in activeSheet = .player(initialEvent: model.event(for: row)) },
          onShowAll: { _ in activeSheet = .events },
          onShare: { row in
            if let event = model.event(for: row) { shareCoordinator.shareEvent(event, in: session) }
          },
          stages: { SleepStagesSection(session: session, scoreConfig: appConfig.sleepScoreConfig) },
          footer: { ShortEventsButton(count: model.shortEvents.count) { activeSheet = .shortEventsPlayer } })
      }
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text(DateFormatters.dayOfWeekAndDate.string(from: session.start))
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(theme.palette.textPrimary)
      }
      ToolbarItem(placement: .topBarTrailing) {
        HStack(spacing: 16) {
          if appConfig.isEnabled(.pdfReport) {
            Button {
              guard let night = model.night else { return }
              let report = NightReport(night: night, config: appConfig.sleepScoreConfig)
              shareCoordinator.exportReport {
                try NightReportPDF.write(report, appName: Self.appName, to: FileManager.default.temporaryDirectory)
              }
            } label: {
              Label(shareCoordinator.isGeneratingPDF ? Strings.a11yGeneratingReport : Strings.a11yExportReport, systemImage: shareCoordinator.isGeneratingPDF ? "clock" : "doc.text").labelStyle(.iconOnly)
                .font(.system(size: 17))
                .foregroundStyle(shareCoordinator.isGeneratingPDF ? theme.palette.textTertiary : theme.palette.accent)
            }
            .disabled(shareCoordinator.isGeneratingPDF)
          }
          if !isClipSession, session.rawAudioFileName != nil {
            Button {
              shareCoordinator.shareFullSession(session)
            } label: {
              Label(Strings.a11yShare, systemImage: "square.and.arrow.up").labelStyle(.iconOnly)
                .font(.system(size: 17))
                .foregroundStyle(theme.palette.accent)
            }
          }
          Button {
            if model.delete(modelContext: modelContext) {
              dismiss()
            } else {
              deleteFailed = true
            }
          } label: {
            Label(Strings.actionDelete, systemImage: "trash").labelStyle(.iconOnly)
              .font(.system(size: 17))
              .foregroundStyle(theme.palette.destructive)
          }
        }
      }
    }
    .alert(Strings.sessionDeleteFailedTitle, isPresented: $deleteFailed) {
      Button(Strings.actionOk, role: .cancel) {}
    } message: {
      Text(Strings.sessionDeleteFailedMessage)
    }
    .sheet(item: $activeSheet) { sheet in
      switch sheet {
      case let .player(initialEvent):
        let episodeEvents = initialEvent.map { session.episodePlaybackEvents(for: $0) } ?? []
        PlayerSheetView(
          session: session,
          sortedEvents: episodeEvents,
          isClipSession: isClipSession,
          initialEvent: episodeEvents.first ?? initialEvent)
      case .events:
        EventsSheetView(
          session: session,
          rows: model.rows,
          isClipSession: isClipSession)
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
          theme.palette.bgPrimary.opacity(0.7)
            .ignoresSafeArea()
          ProgressView()
            .scaleEffect(1.5)
            .tint(theme.palette.accent)
        }
      }
    }
  }
}

enum SessionDetailSheet: Identifiable {
  case player(initialEvent: NightEventRecord?)
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
