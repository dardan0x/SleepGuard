import DesignSystem
import Models
import SwiftUI
import WidgetKit

// Lock Screen accessories. These render in vibrant (monochrome) mode, so they
// rely on system styles and `widgetAccentable()` instead of Theme colors.

struct LastNightCircularView: View {
  let night: WidgetSnapshot.Night?

  var body: some View {
    if let night {
      Gauge(value: Double(night.score), in: 0...100) {
        Image(systemName: "moon.zzz.fill")
      } currentValueLabel: {
        Text("\(night.score)")
      }
      .gaugeStyle(.accessoryCircularCapacity)
      .widgetAccentable()
    } else {
      ZStack {
        AccessoryWidgetBackground()
        Image(systemName: "moon.zzz.fill")
          .font(.title2)
      }
    }
  }
}

struct LastNightRectangularView: View {
  let night: WidgetSnapshot.Night?

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(Strings.widgetLastNightName)
        .font(.headline)
        .widgetAccentable()

      if let night {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text("\(night.score)")
            .font(.title2.weight(.bold))
          Text(Strings.statsMiniChartSleepScoreLabel)
            .font(.caption2.weight(.semibold))
        }
        Text("\(Strings.widgetLastNightSnoring) \(night.snoringText)")
          .font(.caption)
      } else {
        Text(Strings.widgetLastNightEmptyTitle)
          .font(.caption)
        Text(Strings.widgetLastNightEmptyAction)
          .font(.caption)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct LastNightInlineView: View {
  let night: WidgetSnapshot.Night?

  var body: some View {
    if let night {
      Label(
        String(
          format: Strings.widgetLastNightInline,
          "\(night.score)",
          DurationFormatter.hoursAndMinutes(Int(night.snoringDuration / 60))),
        systemImage: "moon.zzz.fill")
    } else {
      Label(Strings.widgetLastNightEmptyTitle, systemImage: "moon.zzz.fill")
    }
  }
}
