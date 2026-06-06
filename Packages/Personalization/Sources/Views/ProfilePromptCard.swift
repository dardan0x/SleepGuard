import SwiftData
import SwiftUI
import Env
import Models
import DesignSystem

@MainActor
public struct ProfilePromptCard: View {
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(Theme.self) private var theme
  @Query(sort: \SleepSession.startDate, order: .reverse) private var sessions: [SleepSession]
  let onSetupProfile: () -> Void

  public init(onSetupProfile: @escaping () -> Void) {
    self.onSetupProfile = onSetupProfile
  }

  public var body: some View {
    if shouldShow {
      HStack(spacing: 14) {
        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Text(Strings.profilePromptTitle)
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(theme.textPrimary)

            Spacer()

            Button {
              HapticManager.shared.tap()
              userPreferences.profilePromptDismissCount += 1
            } label: {
              Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(theme.textTertiary)
            }
            .buttonStyle(ScaleButtonStyle())
          }

          Text(Strings.profilePromptSubtitle)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(theme.textSecondary)
            .lineSpacing(2)

          Button {
            HapticManager.shared.tap()
            onSetupProfile()
          } label: {
            Text(Strings.profilePromptAction)
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(theme.accent)
          }
          .padding(.top, 4)
        }
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(theme.radiusCard)
    }
  }

  private var shouldShow: Bool {
    let completedCount = sessions.filter { $0.totalDuration >= SleepSession.minimumSaveDuration }.count
    return completedCount >= 3
      && !userPreferences.hasCompletedProfile
      && userPreferences.profilePromptDismissCount < 3
  }
}
