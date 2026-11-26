import DesignSystem
import Models
import SwiftUI
import WidgetKit

struct LastNightWidgetView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.theme) private var theme
  let night: WidgetSnapshot.Night?

  var body: some View {
    Group {
      switch family {
      case .accessoryCircular: LastNightCircularView(night: night)
      case .accessoryRectangular: LastNightRectangularView(night: night)
      case .accessoryInline: LastNightInlineView(night: night)
      default:
        if let night {
          if family == .systemMedium {
            LastNightMediumView(night: night)
          } else {
            LastNightSmallView(night: night)
          }
        } else {
          WidgetEmptyView()
        }
      }
    }
    .containerBackground(theme.palette.bgSecondary, for: .widget)
    .widgetURL((night.map { WidgetDeepLink.session($0.id) } ?? .startTracking).url)
  }
}

/// "LAST NIGHT" caption shared by the small and medium layouts.
struct LastNightLabel: View {
  @Environment(\.theme) private var theme

  var body: some View {
    Text(Strings.widgetLastNightLabel)
      .font(.caption2.weight(.semibold))
      .tracking(1)
      .foregroundStyle(theme.palette.textTertiary)
  }
}

extension WidgetSnapshot.Night {
  var sleptText: String {
    DurationText.hoursAndMinutes(totalDuration)
  }

  var snoringText: String {
    "\(DurationText.hoursAndMinutes(snoringDuration)) · \(Int(snoringPercentage.rounded()))%"
  }
}
