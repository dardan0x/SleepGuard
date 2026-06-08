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

