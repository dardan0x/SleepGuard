import SwiftUI
import SwiftData
import AVFoundation
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
        headerSection(session: session)

        timelineSection(session: session)

        eventsSection(session: session)

        if session.audioFileURL != nil {
          miniPlayerSection(session: session)
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
            // Share
          } label: {
            Image(systemName: "square.and.arrow.up")
              .font(.system(size: 17))
              .foregroundStyle(theme.accent)
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
  }

  // MARK: - Audio Playback Controls

  private func setupAudioPlayer(for session: SleepSession) {
    guard let urlString = session.audioFileURL,
          FileManager.default.fileExists(atPath: urlString) else { return }
    let url = URL(fileURLWithPath: urlString)
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

  // MARK: - Sections

  private func headerSection(session: SleepSession) -> some View {
    HStack(spacing: 16) {
      SleepScoreGauge(score: session.sleepScore, theme: theme, size: 120)

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        StatCard(
          icon: "clock",
          title: "Duration",
          value: durationString(session.totalDuration),
          theme: theme,
          iconColor: theme.accent
        )
        StatCard(
          icon: "percent",
          title: "Snoring",
          value: String(format: "%.0f%%", session.snoringPercentage),
          theme: theme,
          iconColor: theme.scoreAmber
        )
        StatCard(
          icon: "bolt.fill",
          title: "Events",
          value: "\(session.eventsCount)",
          theme: theme,
          iconColor: theme.scoreAmber
        )
        StatCard(
          icon: "speaker.wave.3.fill",
          title: "Peak",
          value: String(format: "%.0fdB", session.peakDB),
          theme: theme,
          iconColor: theme.accent
        )
      }
    }
  }

  private func timelineSection(session: SleepSession) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("SNORING TIMELINE")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1)

      SnoringTimelineView(session: session, theme: theme)

      HStack {
        Text(timeString(session.startDate))
          .font(.caption2)
          .foregroundStyle(theme.textTertiary)

        Spacer()

        if let endDate = session.endDate {
          Text(timeString(endDate))
            .font(.caption2)
            .foregroundStyle(theme.textTertiary)
        }
      }
    }
  }

  private func eventsSection(session: SleepSession) -> some View {
    let events = session.events?.sorted { $0.timestamp < $1.timestamp } ?? []

    return VStack(alignment: .leading, spacing: 16) {
      Text("EVENTS · \(events.count)")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
        .tracking(1)

      VStack(spacing: 8) {
        ForEach(events.prefix(4), id: \.id) { event in
          EventRow(event: event, theme: theme) {
            seekToEvent(event, in: session)
          }
        }
      }

      if events.count > 4 {
        Button {
          // Show all events
        } label: {
          Text("Show all \(events.count)")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(theme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .center)
      }
    }
  }

  private func miniPlayerSection(session: SleepSession) -> some View {
    let totalDuration = audioPlayer?.duration ?? session.totalDuration
    let progress = totalDuration > 0 ? currentPlaybackTime / totalDuration : 0

    return VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 12) {
        Button {
          togglePlayback()
        } label: {
          Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(theme.accent)
            .clipShape(Circle())
        }

        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
              .fill(theme.bgElevated)
              .frame(height: 4)

            RoundedRectangle(cornerRadius: 2)
              .fill(theme.accent)
              .frame(width: max(CGFloat(progress) * geometry.size.width, 0), height: 4)

            // Event markers
            if let events = session.events?.sorted(by: { $0.timestamp < $1.timestamp }) {
              ForEach(events, id: \.id) { event in
                let eventProgress = session.totalDuration > 0
                  ? event.timestamp.timeIntervalSince(session.startDate) / session.totalDuration
                  : 0
                Circle()
                  .fill(theme.intensityColor(event.intensity))
                  .frame(width: 6, height: 6)
                  .position(
                    x: CGFloat(eventProgress) * geometry.size.width,
                    y: 2
                  )
              }
            }
          }
          .contentShape(Rectangle())
          .onTapGesture { location in
            let relative = Double(location.x / geometry.size.width)
            scrubTo(relative: relative, in: session)
          }
        }
        .frame(height: 4)

        Text(timeString(totalDuration))
          .font(.system(size: 11, weight: .medium, design: .monospaced))
          .foregroundStyle(theme.textTertiary)
          .monospacedDigit()
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 12)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusSmall)
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

  private func durationString(_ total: TimeInterval) -> String {
    let seconds = Int(total)
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    return String(format: "%d:%02d", hours, minutes)
  }

  private func timeString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
  }

  private func timeString(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%d:%02d", minutes, seconds)
  }

  private func navigationTitle(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE, MMM d"
    return formatter.string(from: date)
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

// MARK: - Snoring Timeline

@MainActor
private struct SnoringTimelineView: View {
  let session: SleepSession
  let theme: Theme

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 8)
          .fill(theme.bgCard)
          .frame(height: 32)

        ForEach(timelineSegments(in: geometry.size.width), id: \.id) { segment in
          segmentView(segment)
        }
      }
      .frame(height: 32)
    }
    .frame(height: 32)
  }

  private var events: [SnoreEvent] {
    session.events?.sorted { $0.timestamp < $1.timestamp } ?? []
  }

  private func timelineSegments(in totalWidth: CGFloat) -> [TimelineSegment] {
    let sessionStart = session.startDate.timeIntervalSinceReferenceDate
    let sessionEnd = session.endDate?.timeIntervalSinceReferenceDate ?? (sessionStart + session.totalDuration)
    let totalDuration = max(sessionEnd - sessionStart, 1)

    return events.map { event in
      let eventStart = event.timestamp.timeIntervalSinceReferenceDate
      let relativeStart = (eventStart - sessionStart) / totalDuration
      let relativeDuration = max(event.duration / totalDuration, 0.002)
      return TimelineSegment(
        id: event.id,
        x: CGFloat(relativeStart) * totalWidth,
        width: max(CGFloat(relativeDuration) * totalWidth, 2),
        color: theme.intensityColor(event.intensity)
      )
    }
  }

  private func segmentView(_ segment: TimelineSegment) -> some View {
    RoundedRectangle(cornerRadius: 2)
      .fill(segment.color)
      .frame(width: segment.width, height: 20)
      .position(x: segment.x + segment.width / 2, y: 16)
  }

  private struct TimelineSegment: Identifiable {
    let id: UUID
    let x: CGFloat
    let width: CGFloat
    let color: Color
  }
}

// MARK: - Event Row

@MainActor
private struct EventRow: View {
  let event: SnoreEvent
  let theme: Theme
  let onPlay: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Circle()
        .fill(theme.intensityColor(event.intensity))
        .frame(width: 10, height: 10)

      Text(timeString(event.timestamp))
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundStyle(theme.textPrimary)
        .monospacedDigit()

      Text(durationString(event.duration))
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(theme.textSecondary)
        .monospacedDigit()

      Spacer()

      Button {
        onPlay()
      } label: {
        Image(systemName: "play.fill")
          .font(.system(size: 14))
          .foregroundStyle(theme.accent)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  private func timeString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm a"
    return formatter.string(from: date)
  }

  private func durationString(_ total: TimeInterval) -> String {
    let minutes = Int(total) / 60
    let seconds = Int(total) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }
}
