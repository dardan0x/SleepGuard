import SwiftUI
import SwiftData
import AVFoundation
import AudioEngine
import Models
import Env
import DesignSystem

@MainActor
public struct SessionDetailView: View {
  let sessionID: UUID

  @Environment(Theme.self) private var theme
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var viewState: ViewState = .loading

  // MARK: - Audio Playback
  @State private var audioPlayer: AVAudioPlayer?
  @State private var isPlaying = false
  @State private var currentPlaybackTime: TimeInterval = 0

  // MARK: - Share
  @State private var isSharePresented = false
  @State private var shareItems: [Any] = []
  @State private var showAllEvents = false

  public init(sessionID: UUID) {
    self.sessionID = sessionID
  }

  public var body: some View {
    Group {
      switch viewState {
      case .loading:
        Color.clear
          .task {
            await loadSession()
          }
      case .loaded(let session):
        loadedBody(session: session)
      case .error:
        errorBody
      }
    }
    .background(theme.bgSecondary.ignoresSafeArea())
  }

  private func loadedBody(session: SleepSession) -> some View {
    ScrollView {
      VStack(spacing: 24) {
        SessionDetailHeaderView(session: session)

        SessionDetailTimelineView(session: session)

        SessionDetailEventsView(
          session: session,
          showAllEvents: showAllEvents,
          onToggleShowAll: { showAllEvents.toggle() },
          onPlayEvent: { event in seekToEvent(event, in: session) },
          onShareEvent: { event in
            Task {
              await exportAndShare(event: event, in: session)
            }
          }
        )

        if session.audioFileURL != nil {
          SessionDetailMiniPlayerView(
            session: session,
            isPlaying: isPlaying,
            progress: audioProgress,
            totalDuration: audioPlayer?.duration ?? session.totalDuration,
            onTogglePlayback: togglePlayback,
            onScrub: { relative in scrubTo(relative: relative, in: session) }
          )
        }
      }
      .padding(20)
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text(navigationTitle(for: session.startDate))
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(theme.textPrimary)
      }
      ToolbarItem(placement: .topBarTrailing) {
        HStack(spacing: 16) {
          Button {
            exportReport(session: session)
          } label: {
            Image(systemName: "doc.text")
              .font(.system(size: 17))
              .foregroundStyle(theme.accent)
          }
          if session.audioFileURL != nil {
            Button {
              shareFullSession(session: session)
            } label: {
              Image(systemName: "square.and.arrow.up")
                .font(.system(size: 17))
                .foregroundStyle(theme.accent)
            }
          }
          Button {
            deleteSession()
          } label: {
            Image(systemName: "trash")
              .font(.system(size: 17))
              .foregroundStyle(theme.destructive)
          }
        }
      }
    }
    .task {
      setupAudioPlayer(for: session)
    }
    .task(id: isPlaying) {
      await trackPlaybackProgress()
    }
    .sheet(isPresented: $isSharePresented) {
      ActivityView(activityItems: shareItems)
    }
  }

  // MARK: - Audio Playback Controls

  private var audioProgress: Double {
    let total = audioPlayer?.duration ?? 0
    return total > 0 ? currentPlaybackTime / total : 0
  }

  private func setupAudioPlayer(for session: SleepSession) {
    guard let urlString = session.audioFileURL,
          let url = URL(string: urlString),
          FileManager.default.fileExists(atPath: url.path) else { return }
    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.prepareToPlay()
      audioPlayer = player
    } catch {
      // Audio playback is optional; fail silently
    }
  }

  private func trackPlaybackProgress() async {
    guard isPlaying else { return }
    while !Task.isCancelled {
      try? await Task.sleep(for: .milliseconds(100))
      if let player = audioPlayer {
        currentPlaybackTime = player.currentTime
        if !player.isPlaying {
          isPlaying = false
        }
      }
    }
  }

  private func togglePlayback() {
    guard let player = audioPlayer else { return }
    if player.isPlaying {
      player.pause()
      isPlaying = false
    } else {
      player.play()
      isPlaying = true
    }
  }

  private func seekToEvent(_ event: SnoreEvent, in session: SleepSession) {
    guard let player = audioPlayer else { return }
    let eventTime = event.timestamp.timeIntervalSince(session.startDate)
    player.currentTime = max(0, min(eventTime, player.duration))
    if !player.isPlaying {
      player.play()
      isPlaying = true
    }
  }

  private func scrubTo(relative: Double, in session: SleepSession) {
    guard let player = audioPlayer else { return }
    let time = relative * player.duration
    player.currentTime = max(0, min(time, player.duration))
    currentPlaybackTime = player.currentTime
  }

  private var errorBody: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundStyle(theme.textTertiary)

      Text("Unable to load session")
        .font(.headline)
        .foregroundStyle(theme.textPrimary)
    }
  }

  // MARK: - Data Loading

  private func loadSession() async {
    do {
      let descriptor = FetchDescriptor<SleepSession>(
        predicate: #Predicate { $0.id == sessionID }
      )
      if let session = try modelContext.fetch(descriptor).first {
        viewState = .loaded(session: session)
      } else {
        viewState = .error
      }
    } catch {
      viewState = .error
    }
  }

  // MARK: - Formatting

  private func navigationTitle(for date: Date) -> String {
    DateFormatters.dayOfWeekAndDate.string(from: date)
  }

  private func exportReport(session: SleepSession) {
    Task {
      if let url = SleepReportPDFGenerator().generatePDF(for: session) {
        shareItems = [url]
        isSharePresented = true
      }
    }
  }

  private func shareFullSession(session: SleepSession) {
    guard let urlString = session.audioFileURL,
          let url = URL(string: urlString),
          FileManager.default.fileExists(atPath: url.path) else { return }
    shareItems = [url]
    isSharePresented = true
  }

  private func exportAndShare(event: SnoreEvent, in session: SleepSession) async {
    guard let urlString = session.audioFileURL,
          let sourceURL = URL(string: urlString),
          FileManager.default.fileExists(atPath: sourceURL.path) else { return }

    let asset = AVURLAsset(url: sourceURL)
    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else { return }

    let eventTime = event.timestamp.timeIntervalSince(session.startDate)
    let startTime = max(0, eventTime - 2)
    let endTime = min(asset.duration.seconds, eventTime + event.duration + 2)
    guard endTime > startTime else { return }

    exportSession.timeRange = CMTimeRange(
      start: CMTime(seconds: startTime, preferredTimescale: 600),
      duration: CMTime(seconds: endTime - startTime, preferredTimescale: 600)
    )

    let tempDir = FileManager.default.temporaryDirectory
    let clipURL = tempDir.appendingPathComponent("snore_event_\(event.id.uuidString).m4a")
    if FileManager.default.fileExists(atPath: clipURL.path) {
      try? FileManager.default.removeItem(at: clipURL)
    }
    exportSession.outputURL = clipURL
    exportSession.outputFileType = .m4a

    await exportSession.export()
    guard exportSession.status == .completed else { return }

    shareItems = [clipURL]
    isSharePresented = true
  }

  private func deleteSession() {
    do {
      let descriptor = FetchDescriptor<SleepSession>(
        predicate: #Predicate { $0.id == sessionID }
      )
      if let session = try modelContext.fetch(descriptor).first {
        modelContext.delete(session)
        try modelContext.save()
        dismiss()
      }
    } catch {
      // Deletion failed; fail silently
    }
  }

  private enum ViewState {
    case loading
    case loaded(session: SleepSession)
    case error
  }
}
