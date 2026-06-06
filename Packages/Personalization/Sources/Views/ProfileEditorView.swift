import SwiftUI
import Env
import Models
import DesignSystem

@MainActor
public struct ProfileEditorView: View {
  @Bindable var profile: UserProfile
  let onComplete: () -> Void
  @Environment(Theme.self) private var theme
  @State private var currentPage = 0
  private let totalPages = 4

  public init(profile: UserProfile, onComplete: @escaping () -> Void) {
    self.profile = profile
    self.onComplete = onComplete
  }

  public var body: some View {
    ZStack {
      theme.bgPrimary.ignoresSafeArea()

      VStack(spacing: 0) {
        topBar

        TabView(selection: $currentPage) {
          ProfileStepIdentityView(profile: profile).tag(0)
          ProfileStepGoalsView(profile: profile).tag(1)
          ProfileStepHabitsView(profile: profile).tag(2)
          ProfileStepPersonalView(profile: profile).tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))

        bottomControls
      }
    }
  }

  private var topBar: some View {
    HStack {
      privacyBanner
      Spacer()
      if currentPage < totalPages - 1 {
        Button {
          HapticManager.shared.tap()
          withAnimation { currentPage += 1 }
        } label: {
          Text(Strings.actionSkip)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(theme.textSecondary)
        }
        .buttonStyle(ScaleButtonStyle())
      }
    }
    .padding(.horizontal, 20)
    .frame(height: 56)
  }

  private var privacyBanner: some View {
    HStack(spacing: 6) {
      Image(systemName: "lock.shield")
        .font(.system(size: 12))
        .foregroundStyle(theme.scoreGreen)
      Text(Strings.profileEditorPrivacyNotice)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(theme.scoreGreen)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(
      Capsule()
        .stroke(theme.scoreGreen.opacity(0.4), lineWidth: 1)
    )
  }

  private var bottomControls: some View {
    VStack(spacing: 16) {
      progressDots

      if currentPage == totalPages - 1 {
        Button {
          HapticManager.shared.tap()
          profile.updatedAt = Date()
          onComplete()
        } label: {
          Text(Strings.profileActionSaveProfile)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(theme.bgPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(theme.textPrimary)
            .cornerRadius(theme.radiusCard)
        }
      } else {
        Button {
          HapticManager.shared.tap()
          withAnimation { currentPage += 1 }
        } label: {
          Text(Strings.actionContinue)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(theme.bgPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(theme.accent)
            .cornerRadius(theme.radiusCard)
        }
      }

      if currentPage > 0 {
        Button {
          HapticManager.shared.tap()
          withAnimation { currentPage -= 1 }
        } label: {
          Text(Strings.actionBack)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(theme.textSecondary)
        }
        .buttonStyle(ScaleButtonStyle())
      }
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 32)
  }

  private var progressDots: some View {
    HStack(spacing: 8) {
      ForEach(0..<totalPages, id: \.self) { index in
        RoundedRectangle(cornerRadius: 4)
          .fill(index == currentPage ? theme.accent : theme.bgCard)
          .frame(width: index == currentPage ? 24 : 8, height: 8)
          .animation(.spring(duration: 0.35), value: currentPage)
      }
    }
  }
}
