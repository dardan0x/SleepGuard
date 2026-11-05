import Charts
import DesignSystem
import FactoryKit
import Models
import SwiftUI

struct TrendsChartSection: View {
  let data: [TrendBarData]
  @Injected(\.theme) private var theme

  var body: some View {
    VStack(spacing: 8) {
      Chart(data) { item in
        BarMark(
          x: .value("Day", item.label),
          y: .value("Minutes", item.minutes))
          .foregroundStyle(item.color)
          .cornerRadius(4)
      }
      .frame(height: 120)
      .chartYAxis(.hidden)
      .chartXAxis {
        AxisMarks(values: .automatic) { value in
          AxisValueLabel {
            if let label = value.as(String.self) {
              Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.textTertiary)
            }
          }
        }
      }
    }
    .padding(16)
    .overlay(
      RoundedRectangle(cornerRadius: theme.radiusCard)
        .stroke(theme.bgCard, lineWidth: 1)
    )
  }
}

struct TrendBarData: Identifiable {
  let id: UUID
  let label: String
  let minutes: Int
  let color: Color
}
