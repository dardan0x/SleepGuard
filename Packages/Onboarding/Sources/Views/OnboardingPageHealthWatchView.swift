import DesignSystem
import Env
import SwiftUI

struct OnboardingPageHealthWatchView: View {
  let onContinue: () -> Void
  @Environment(HealthKitSync.self) private var healthKitSync
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(Theme.self) private var theme
  @State private var isRequesting = false
  @State private var showGranted = false

  var body: some View {
    VStack(spacing: 0) {
      Spacer().frame(height: 60)

      ZStack {
        Circle()
          .stroke(theme.scoreGreen.opacity(0.2), lineWidth: 1)
          .frame(width: 160, height: 160)

        Circle()
          .fill(Color(hex: "#0A2818"))
          .stroke(theme.scoreGreen.opacity(0.33), lineWidth: 1)
          .frame(width: 130, height: 130)

        Circle()
          .fill(Color(hex: "#133D20"))
          .frame(width: 80, height: 80)

        Image(systemName: "bed.double.fill")
          .font(.system(size: 36))
          .foregroundStyle(theme.scoreGreen)

        Image(systemName: "heart.fill")
          .font(.system(size: 20))
          .foregroundStyle(theme.scoreGreen)
          .offset(x: 55, y: -55)

        Circle()
          .fill(theme.accent)
          .frame(width: 14, height: 14)
          .offset(x: 52, y: 52)
      }
      .frame(width: 180, height: 180)

      VStack(spacing: 16) {
        Text(Strings.onboardingHealthWatchTitle)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.textPrimary)
          .multilineTextAlignment(.center)

        Text(Strings.onboardingHealthWatchBody)
          .font(.system(size: 15))
          .foregroundStyle(theme.textSecondary)
          .multilineTextAlignment(.center)

        HStack(spacing: 6) {
          Image(systemName: "shield.fill")
            .font(.system(size: 13))
            .foregroundStyle(theme.textSecondary)

          Text(Strings.onboardingHealthWatchBadge)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(theme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
          Capsule()
            .fill(theme.bgElevated)
        )
      }
      .padding(.top, 32)

      Spacer()

      VStack(spacing: 16) {
        Button {
          Task {
            isRequesting = true
            let granted = await healthKitSync.requestAuthorization()
            isRequesting = false
            if granted {
              showGranted = true
              if !userPreferences.hasExplicitlySetSyncToHealthKit {
                userPreferences.syncToHealthKit = true
              }
              if !userPreferences.hasExplicitlySetEnhancedSleepTracking {
                userPreferences.enhancedSleepTracking = true
              }
              try? await Task.sleep(for: .seconds(0.8))
            }
            onContinue()
          }
        } label: {
          HStack(spacing: 8) {
            if showGranted {
              Circle()
                .fill(.white)
                .frame(width: 10, height: 10)
            }
            if isRequesting {
              ProgressView()
                .tint(.white)
            }
            Text(showGranted ? Strings.onboardingHealthWatchGranted : Strings.onboardingHealthWatchButtonPrimary)
              .font(.system(size: 17, weight: .semibold))
          }
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 56)
          .background(showGranted ? theme.scoreGreen : theme.accent)
          .clipShape(Capsule())
        }
        .disabled(isRequesting)
        .buttonStyle(ScaleButtonStyle())

        Button(action: { onContinue() }) {
          Text(Strings.onboardingHealthWatchButtonSecondary)
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(theme.textSecondary)
        }
        .buttonStyle(ScaleButtonStyle())
      }
      .padding(.horizontal, 24)
    }
    .padding(.horizontal, 32)
    .padding(.bottom, 40)
    .onAppear {
      healthKitSync.checkAuthorizationStatus()
      if healthKitSync.isAuthorized {
        showGranted = true
      }
    }
  }
}
