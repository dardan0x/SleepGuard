import DesignSystem
import Models
import SleepGuardDesignKit
import SleepStrings
import SwiftUI
import WidgetKit

/// One-tap tile that opens the live session screen. It shows no data, so it
/// shares the snapshot provider instead of defining its own.
struct StartTrackingWidget: Widget {
  let kind = "StartTrackingWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: WidgetSnapshotProvider()) { _ in
      StartTrackingWidgetView()
    }
    .configurationDisplayName(Strings.widgetStartName)
    .description(Strings.widgetStartDescription)
    .supportedFamilies([.systemSmall])
  }
}

/// Mirrors `StartRecordingButton`: red record dot, label, red top glow.
struct StartTrackingWidgetView: View {
  @Environment(\.theme) private var theme
  var body: some View {
    VStack(spacing: 14) {
      ZStack {
        Circle()
          .fill(theme.palette.scoreRed.opacity(0.25))
          .frame(width: 44, height: 44)
        Circle()
          .fill(theme.palette.scoreRed)
          .frame(width: 22, height: 22)
      }

      Text(Strings.actionStartRecording)
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(theme.palette.textPrimary)
        .multilineTextAlignment(.center)
    }
    .containerBackground(for: .widget) {
      ZStack {
        theme.palette.bgSecondary
        LinearGradient(
          colors: [theme.palette.scoreRed.opacity(0.35), theme.palette.scoreRed.opacity(0)],
          startPoint: .top,
          endPoint: .center)
      }
    }
    .widgetURL(WidgetDeepLink.startTracking.url)
  }
}

#Preview(as: .systemSmall) {
  StartTrackingWidget()
} timeline: {
  SnapshotEntry(date: .now, snapshot: .empty)
}
