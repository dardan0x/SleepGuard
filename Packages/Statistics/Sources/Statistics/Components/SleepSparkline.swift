import SwiftUI
import Charts
import DesignSystem
import Models

@MainActor
public struct SleepSparkline: View {
  public struct DataPoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let score: Int

    public init(date: Date, score: Int) {
      self.date = date
      self.score = score
    }
  }

  let data: [DataPoint]
  let theme: Theme

  public init(data: [DataPoint], theme: Theme) {
    self.data = data
    self.theme = theme
  }

  public var body: some View {
    Chart(data) { point in
      LineMark(
        x: .value("Date", point.date, unit: .day),
        y: .value("Score", point.score)
      )
      .foregroundStyle(theme.primaryColor)
      .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

      AreaMark(
        x: .value("Date", point.date, unit: .day),
        y: .value("Score", point.score)
      )
      .foregroundStyle(
        LinearGradient(
          colors: [theme.primaryColor.opacity(0.25), theme.primaryColor.opacity(0.0)],
          startPoint: .top,
          endPoint: .bottom
        )
      )

      if data.count == 1 {
        PointMark(
          x: .value("Date", point.date, unit: .day),
          y: .value("Score", point.score)
        )
        .foregroundStyle(theme.primaryColor)
        .symbolSize(50)
      }
    }
    .chartYScale(domain: 0 ... 100)
    .chartXAxis {
      AxisMarks(values: .stride(by: .day)) { _ in
        AxisValueLabel(format: .dateTime.weekday(.narrow))
          .foregroundStyle(theme.secondaryLabelColor)
      }
    }
    .chartYAxis {
      AxisMarks(position: .leading) { _ in
        AxisGridLine()
          .foregroundStyle(theme.secondaryLabelColor.opacity(0.15))
        AxisValueLabel("100")
          .foregroundStyle(theme.secondaryLabelColor.opacity(0.5))
      }
    }
    .frame(height: 100)
  }
}
