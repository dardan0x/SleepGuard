import DesignSystem
import FactoryKit
import SwiftUI

@MainActor
struct ProfileChipSelector: View {
  let title: String
  let options: [String]
  @Binding var selection: String
  @Injected(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title.uppercased())
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.textTertiary)
        .lineLimit(1)

      FlowLayout(spacing: 8) {
        ForEach(options, id: \.self) { option in
          Button {
            selection = option
          } label: {
            Text(option)
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(selection == option ? theme.bgPrimary : theme.textPrimary)
              .padding(.horizontal, 14)
              .padding(.vertical, 8)
              .background(selection == option ? theme.accent : theme.bgElevated)
              .cornerRadius(theme.radiusSmall)
          }
        }
      }
    }
  }
}

// Reusing FlowLayout from BriefingSurveyCard
struct FlowLayout: Layout {
  var spacing: CGFloat = 8

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
    let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
    return result.size
  }

  func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
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
        if x + size.width > maxWidth, x > 0 {
          x = 0
          y += rowHeight + spacing
          rowHeight = 0
        }
        positions.append(CGPoint(x: x, y: y))
        rowHeight = max(rowHeight, size.height)
        x += size.width + spacing
      }

      size = CGSize(width: maxWidth, height: y + rowHeight)
    }
  }
}
