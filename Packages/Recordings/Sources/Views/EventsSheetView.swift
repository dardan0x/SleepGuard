import SwiftUI
import Models
import Env
import DesignSystem

/// Bottom sheet showing all snore events as a horizontally-scrolling list of compact cards.
/// Tapping a card’s Play button presents the full event player for that single recording
/// without dismissing the events sheet.
@MainActor
public struct EventsSheetView: View {
  let session: SleepSession
  let events: [SnoreEvent]
  let isClipSession: Bool
  let onPlayEvent: (SnoreEvent) -> Void

  @Environment(Theme.self) private var theme
  @Environment(\.dismiss) private var dismiss

  @State private var selectedEvent: SnoreEvent?

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

  public var body: some View {
    NavigationStack {
      ScrollView(showsIndicators: false) {
        LazyVGrid(columns: columns, spacing: 12) {
          ForEach(events, id: \.id) { event in
            EventCard(
              event: event,
              session: session,
              theme: theme,
              onPlay: {
                selectedEvent = event
                onPlayEvent(event)
              }
            )
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
      }
      .background(theme.bgSecondary.ignoresSafeArea())
      .navigationTitle(Strings.recordingsDetailEventsLabel)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 24))
              .foregroundStyle(theme.textTertiary)
          }
        }
      }
    }
    .sheet(item: $selectedEvent) { event in
      PlayerSheetView(
        session: session,
        sortedEvents: [event],
        isClipSession: isClipSession,
        initialEvent: event
      )
    }
  }
}

// MARK: - Event Card

@MainActor
private struct EventCard: View {
  let event: SnoreEvent
  let session: SleepSession
  let theme: Theme
  let onPlay: () -> Void

  var body: some View {
    VStack(spacing: 10) {
      // Intensity indicator + time
      HStack(spacing: 2) {
        Text(Strings.startTimeEventCard)
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(theme.textSecondary)
          .lineLimit(1)

        Text(eventTime)
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(theme.textSecondary)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }

      Spacer()

      HStack(spacing: 6) {
        Circle()
          .fill(theme.intensityColor(event.intensity))
          .frame(width: 8, height: 8)
        // Duration
        Text(durationString(event.snoreDuration))
          .font(.system(size: 22, weight: .bold, design: .rounded))
          .foregroundStyle(theme.intensityColor(event.intensity))
      }

      // Play button
      Button {
        onPlay()
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "play.fill")
            .font(.system(size: 12, weight: .semibold))
          Text(Strings.actionPlay)
            .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(theme.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(theme.accent.opacity(0.12))
        .cornerRadius(8)
      }
    }
    .padding(12)
    .frame(width: 120, height: 140)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  private var eventTime: String {
    DateFormatters.timeWithPeriod.string(from: event.timestamp)
  }

  private func durationString(_ total: TimeInterval) -> String {
    let seconds = Int(total)
    return String(format: "%d:%02d", seconds / 60, seconds % 60)
  }
}
