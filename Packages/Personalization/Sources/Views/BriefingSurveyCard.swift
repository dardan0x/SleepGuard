import SwiftUI
import DesignSystem

@MainActor
public struct BriefingSurveyCard: View {
  let survey: SurveyPrompt
  let onChipTap: (String) -> Void
  let onSkip: () -> Void
  @Environment(Theme.self) private var theme

  public init(
    survey: SurveyPrompt,
    onChipTap: @escaping (String) -> Void,
    onSkip: @escaping () -> Void
  ) {
    self.survey = survey
    self.onChipTap = onChipTap
    self.onSkip = onSkip
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(survey.title)
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(theme.textPrimary)

      FlowLayout(spacing: 8) {
        ForEach(survey.chips, id: \.self) { chip in
          Button {
            onChipTap(chip)
          } label: {
            Text(chip)
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(theme.textPrimary)
              .padding(.horizontal, 14)
              .padding(.vertical, 8)
              .background(theme.bgElevated)
              .cornerRadius(theme.radiusSmall)
          }
        }
      }

      Button {
        onSkip()
      } label: {
        Text(Strings.actionSkip)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(theme.textTertiary)
      }
      .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .padding(16)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }
}

// MARK: - FlowLayout

private struct FlowLayout: Layout {
  var spacing: CGFloat = 8

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
    return result.size
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
    for (index, subview) in subviews.enumerated() {
      subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                y: bounds.minY + result.positions[index].y),
                    proposal: .unspecified)
    }
  }

  struct FlowResult {
    var size: CGSize = .zero
    var positions: [CGPoint] = []

    init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
      var x: CGFloat = 0
      var y: CGFloat = 0
      var rowHeight: CGFloat = 0

      for subview in subviews {
        let size = subview.sizeThatFits(.unspecified)
        if x + size.width > maxWidth && x > 0 {
          x = 0
          y += rowHeight + spacing
          rowHeight = 0
        }
        positions.append(CGPoint(x: x, y: y))
        rowHeight = max(rowHeight, size.height)
        x += size.width + spacing
      }

      self.size = CGSize(width: maxWidth, height: y + rowHeight)
    }
  }
}
