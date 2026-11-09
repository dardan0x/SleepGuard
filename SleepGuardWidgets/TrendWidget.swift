import DesignSystem
import Models
import SwiftUI
import WidgetKit

struct TrendWidget: Widget {
  let kind = "TrendWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: WidgetSnapshotProvider()) { entry in
      TrendWidgetView(days: entry.snapshot.recentDays)
    }
    .configurationDisplayName(Strings.widgetTrendName)
    .description(Strings.widgetTrendDescription)
    .supportedFamilies([.systemMedium])
  }
}

#Preview(as: .systemMedium) {
  TrendWidget()
} timeline: {
  SnapshotEntry(date: .now, snapshot: .sample)
  SnapshotEntry(date: .now, snapshot: .empty)
}
