import DesignSystem
import FactoryKit
import SwiftUI

@MainActor
public struct SleepBriefingView: View {
  let briefing: Briefing
  let onDismiss: () -> Void
  let onChipTap: ((String) -> Void)?
  @Injected(\.theme) private var theme

  public init(
    briefing: Briefing,
    onDismiss: @escaping () -> Void,
    onChipTap: ((String) -> Void)? = nil)
  {
    self.briefing = briefing
    self.onDismiss = onDismiss
    self.onChipTap = onChipTap
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 12) {
        HStack {
          Spacer()
          Button {
            onDismiss()
          } label: {
            Label(Strings.actionClose, systemImage: "xmark.circle.fill").labelStyle(.iconOnly)
              .font(.system(size: 24))
              .foregroundStyle(theme.textSecondary)
          }
        }

        BriefingGreetingHeader(greeting: briefing.greeting)

        BriefingRecapCard(
          headline: briefing.headline,
          stats: briefing.stats)

        if let insight = briefing.insight {
          BriefingInsightCard(insight: insight)
        }

        if let profileNudge = briefing.profileNudge {
          Text(profileNudge)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(theme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
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
            onSkip: onDismiss)
        }

        Spacer(minLength: 8)

        Button {
          onDismiss()
        } label: {
          Text(Strings.actionClose)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(theme.bgPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(theme.textPrimary)
            .cornerRadius(theme.radiusCard)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 24)
      .padding(.bottom, 20)
    }
    .background(theme.bgPrimary)
  }
}
