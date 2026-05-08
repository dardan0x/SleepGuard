import SwiftUI
import Charts
import Models
import DesignSystem

struct TrendsChartSection: View {
  let data: [TrendBarData]
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack(spacing: 8) {
      Chart(data) { item in
        BarMark(
          x: .value("Day", item.label),
          y: .value("Minutes", item.minutes)
        )
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
  }
}

struct TrendBarData: Identifiable {
  let id: UUID
  let label: String
  let minutes: Int
  let color: Color
}
