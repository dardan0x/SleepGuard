import DesignSystem
import Models
import SwiftUI
import WidgetKit

struct LastNightWidget: Widget {
  let kind = "LastNightWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: WidgetSnapshotProvider()) { entry in
      LastNightWidgetView(night: entry.snapshot.lastNight)
    }
    .configurationDisplayName(Strings.widgetLastNightName)
    .description(Strings.widgetLastNightDescription)
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
  }
}

#Preview(as: .systemSmall) {
  LastNightWidget()
} timeline: {
  SnapshotEntry(date: .now, snapshot: .sample)
  SnapshotEntry(date: .now, snapshot: .empty)
}

#Preview(as: .systemMedium) {
  LastNightWidget()
} timeline: {
  SnapshotEntry(date: .now, snapshot: .sample)
  SnapshotEntry(date: .now, snapshot: .empty)
}

#Preview(as: .accessoryRectangular) {
  LastNightWidget()
} timeline: {
  SnapshotEntry(date: .now, snapshot: .sample)
  SnapshotEntry(date: .now, snapshot: .empty)
}
