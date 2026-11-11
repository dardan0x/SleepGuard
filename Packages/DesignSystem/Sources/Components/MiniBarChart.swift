import FactoryKit
import SwiftUI

@MainActor
public struct MiniBarChart: View {
  public struct DataPoint: Identifiable {
    public let id = UUID()
    public let label: String
    public let value: Double
    public let color: Color
    /// What VoiceOver says for the bar; the visible label may be one letter.
    public let accessibilityLabel: String
    public let accessibilityValue: String

    public init(
      label: String,
      value: Double,
      color: Color,
      accessibilityLabel: String? = nil,
      accessibilityValue: String? = nil)
    {
      self.label = label
      self.value = value
      self.color = color
      self.accessibilityLabel = accessibilityLabel ?? label
      self.accessibilityValue = accessibilityValue ?? "\(Int(value.rounded()))"
    }
  }

  let data: [DataPoint]
  @Injected(\.theme) private var theme

  public init(data: [DataPoint]) {
    self.data = data
  }

  public var body: some View {
    HStack(alignment: .bottom, spacing: 8) {
      ForEach(data) { point in
        VStack(spacing: 6) {
          RoundedRectangle(cornerRadius: 4)
            .fill(point.color)
            .frame(height: barHeight(for: point.value))

          Text(point.label)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(point.accessibilityLabel)
        .accessibilityValue(point.accessibilityValue)
      }
    }
    .frame(height: 55)
  }

  private func barHeight(for value: Double) -> CGFloat {
    let maxValue = data.map(\.value).max() ?? 1
    let ratio = maxValue > 0 ? value / maxValue : 0
    return CGFloat(ratio) * 42
  }
}
