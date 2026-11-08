import DesignSystem
import SwiftUI
import WidgetKit

// F20-T1 placeholder: proves the extension builds against DesignSystem.
// Replaced by the snapshot-driven Last Night widget in F20-T5.

struct PlaceholderEntry: TimelineEntry {
  let date: Date
}

struct PlaceholderProvider: TimelineProvider {
  func placeholder(in _: Context) -> PlaceholderEntry {
    PlaceholderEntry(date: .now)
  }

  func getSnapshot(in _: Context, completion: @escaping (PlaceholderEntry) -> Void) {
    completion(PlaceholderEntry(date: .now))
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
    completion(Timeline(entries: [PlaceholderEntry(date: .now)], policy: .never))
  }
}

struct PlaceholderWidgetView: View {
  let theme = Theme.shared

  var body: some View {
    Text(Strings.widgetLastNightName)
      .font(.headline)
      .foregroundStyle(theme.textPrimary)
      .containerBackground(theme.bgCard, for: .widget)
  }
}

struct SleepGuardWidgets: Widget {
  let kind = "LastNightWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PlaceholderProvider()) { _ in
      PlaceholderWidgetView()
    }
    .configurationDisplayName(Strings.widgetLastNightName)
    .description(Strings.widgetLastNightDescription)
    .supportedFamilies([.systemSmall])
  }
}

#Preview(as: .systemSmall) {
  SleepGuardWidgets()
} timeline: {
  PlaceholderEntry(date: .now)
}
