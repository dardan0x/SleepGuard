import DesignSystem
import FactoryKit
import SwiftUI

@MainActor
public struct BriefingRecapCard: View {
  let headline: String
  let stats: [BriefingStat]
  @Injected(\.theme) private var theme

  public init(headline: String, stats: [BriefingStat]) {
    self.headline = headline
    self.stats = stats
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(headline)
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(theme.textPrimary)
        .lineSpacing(4)

      if !stats.isEmpty {
        HStack(spacing: 12) {
          ForEach(stats, id: \.label) { stat in
            StatCard(
              icon: iconForLabel(stat.label),
              title: stat.label,
              value: stat.value,
              theme: theme)
          }
        }
      }
    }
    .padding(16)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  private func iconForLabel(_ label: String) -> String {
    switch label {
    case Strings.briefingStatSleep: "bed.double.fill"
    case Strings.briefingStatSnoring: "waveform"
    case Strings.briefingStatScore: "star.fill"
    default: "chart.bar.fill"
    }
  }
}
