import DesignSystem
import Models
import SwiftUI
import WidgetKit

struct LastNightWidgetView: View {
  @Environment(\.widgetFamily) private var family
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
    .containerBackground(Theme.shared.bgSecondary, for: .widget)
    .widgetURL((night.map { WidgetDeepLink.session($0.id) } ?? .startTracking).url)
  }
}

/// "LAST NIGHT" caption shared by the small and medium layouts.
struct LastNightLabel: View {
  var body: some View {
    Text(Strings.widgetLastNightLabel)
      .font(.caption2.weight(.semibold))
      .tracking(1)
      .foregroundStyle(Theme.shared.textTertiary)
  }
}

extension WidgetSnapshot.Night {
  var sleptText: String {
    DurationFormatter.hoursAndMinutes(Int(totalDuration / 60))
  }

  var snoringText: String {
    "\(DurationFormatter.hoursAndMinutes(Int(snoringDuration / 60))) · \(Int(snoringPercentage.rounded()))%"
  }
}
