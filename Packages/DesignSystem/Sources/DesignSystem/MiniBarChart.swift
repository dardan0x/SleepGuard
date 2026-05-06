import SwiftUI

@MainActor
public struct MiniBarChart: View {
  public struct DataPoint: Identifiable {
    public let id = UUID()
    public let label: String
    public let value: Double
    public let color: Color

    public init(label: String, value: Double, color: Color) {
      self.label = label
      self.value = value
      self.color = color
    }
  }

  let data: [DataPoint]
  let theme: Theme

  public init(data: [DataPoint], theme: Theme) {
    self.data = data
    self.theme = theme
  }

  public var body: some View {
    HStack(alignment: .bottom, spacing: 8) {
      ForEach(data) { point in
        VStack(spacing: 6) {
          RoundedRectangle(cornerRadius: 4)
            .fill(point.color)
            .frame(height: barHeight(for: point.value))

          Text(point.label)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
      }
    }
    .frame(height: 100)
  }

  private func barHeight(for value: Double) -> CGFloat {
    let maxValue = data.map(\.value).max() ?? 1
    let ratio = maxValue > 0 ? value / maxValue : 0
    return CGFloat(ratio) * 80
  }
}
