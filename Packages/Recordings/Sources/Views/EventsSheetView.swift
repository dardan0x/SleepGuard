import DesignSystem
import FactoryKit
import Models
import SleepCore
public import SwiftUI

/// Bottom sheet showing every row under the detail's filter as cards (the
/// shared `EventsGridContent`). Tapping a card's Play button presents the
/// player for that row's episode without dismissing the events sheet.
@MainActor
public struct EventsSheetView: View {
  let session: SleepSession
  let rows: [EventListRow]
  let isClipSession: Bool

  @Injected(\.theme) private var theme
  @Environment(\.dismiss) private var dismiss

  @State private var selectedEvent: SnoreEvent?

  public var body: some View {
    NavigationStack {
      ScrollView(showsIndicators: false) {
        EventsGridContent(rows: rows) { row in
          selectedEvent = session.events?.first { $0.id == row.id }
        }
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
