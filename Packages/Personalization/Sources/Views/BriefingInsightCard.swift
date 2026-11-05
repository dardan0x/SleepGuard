import DesignSystem
import FactoryKit
import SwiftUI

@MainActor
public struct BriefingInsightCard: View {
  let insight: String
  @Injected(\.theme) private var theme

  public init(insight: String) {
    self.insight = insight
  }

  public var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "sparkles")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(theme.accent)

      Text(insight)
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(theme.textSecondary)
        .lineSpacing(3)
    }
    .padding(16)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }
}
