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
  @Query private var profiles: [UserProfile]
  let onSetupProfile: () -> Void
  @State private var dragOffset: CGFloat = 0
  @State private var isDismissed = false

  public init(onSetupProfile: @escaping () -> Void) {
    self.onSetupProfile = onSetupProfile
  }

  public var body: some View {
    if shouldShow && !isDismissed {
      HStack(spacing: 14) {
        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Text(Strings.profilePromptTitle)
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(theme.textPrimary)

            Spacer()

            Button {
              HapticManager.shared.tap()
              dismiss()
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
      .offset(y: dragOffset)
      .opacity(1.0 - (abs(dragOffset) / 120.0))
      .gesture(
        DragGesture()
          .onChanged { value in
            if value.translation.height < 0 {
              dragOffset = value.translation.height
            }
          }
          .onEnded { value in
            if value.translation.height < -80 {
              withAnimation(.easeOut(duration: 0.2)) {
                dragOffset = -200
              }
              dismiss()
            } else {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                dragOffset = 0
              }
            }
          }
      )
    }
  }

  private func dismiss() {
    HapticManager.shared.tap()
    userPreferences.profilePromptDismissCount += 1
    isDismissed = true
  }

  private var shouldShow: Bool {
    let completedCount = sessions.filter { $0.totalDuration >= SleepSession.minimumSaveDuration }.count
    let profileCompletion = profiles.first?.completionPercentage ?? 0
    return completedCount >= 3
      && profileCompletion < 0.5
      && !userPreferences.hasCompletedProfile
      && userPreferences.profilePromptDismissCount < 3
  }
}
