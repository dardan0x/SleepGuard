import DesignSystem
import Env
import FactoryKit
import Models
import SwiftUI

/// Bottom sheet showing all snore events as a horizontally-scrolling list of compact cards.
/// Tapping a card’s Play button presents the full event player for that single recording
/// without dismissing the events sheet.
@MainActor
public struct EventsSheetView: View {
  let session: SleepSession
  let events: [SnoreEvent]
  let displayDurations: [UUID: TimeInterval]?
  let isClipSession: Bool
  let onPlayEvent: (SnoreEvent) -> Void

  @Injected(\.theme) private var theme
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
              displayDuration: displayDurations?[event.id],
              onPlay: {
                selectedEvent = event
                onPlayEvent(event)
              })
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
      }
      .background(theme.bgPrimary.ignoresSafeArea())
      .navigationTitle(Strings.recordingsDetailEventsLabel)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            dismiss()
          } label: {
            Label(Strings.actionClose, systemImage: "xmark.circle.fill").labelStyle(.iconOnly)
              .font(.system(size: 24))
              .foregroundStyle(theme.textTertiary)
          }
        }
      }
    }
    .sheet(item: $selectedEvent) { event in
      let episodeEvents = session.episodePlaybackEvents(for: event)
      PlayerSheetView(
        session: session,
        sortedEvents: episodeEvents,
        isClipSession: isClipSession,
        initialEvent: episodeEvents.first ?? event)
    }
  }
}
