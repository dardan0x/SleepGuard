import SwiftUI
import DesignSystem

@MainActor
public struct SleepBriefingView: View {
  let briefing: Briefing
  let onDismiss: () -> Void
  let onChipTap: ((String) -> Void)?
  @Environment(Theme.self) private var theme

  public init(
    briefing: Briefing,
    onDismiss: @escaping () -> Void,
    onChipTap: ((String) -> Void)? = nil
  ) {
    self.briefing = briefing
    self.onDismiss = onDismiss
    self.onChipTap = onChipTap
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        BriefingGreetingHeader(greeting: briefing.greeting)

        BriefingRecapCard(
          headline: briefing.headline,
          stats: briefing.stats
        )

        if let insight = briefing.insight {
          BriefingInsightCard(insight: insight)
        }

        Text(briefing.nudge)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(theme.textSecondary)
          .lineSpacing(3)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 4)

        if let survey = briefing.survey {
          BriefingSurveyCard(
            survey: survey,
            onChipTap: { chip in
              onChipTap?(chip)
              onDismiss()
            },
            onSkip: onDismiss
          )
        }

        Spacer(minLength: 20)

        Button {
          onDismiss()
        } label: {
          Text(Strings.actionClose)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(theme.bgPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(theme.textPrimary)
            .cornerRadius(theme.radiusCard)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 60)
      .padding(.bottom, 32)
    }
    .background(theme.bgPrimary)
  }
}
