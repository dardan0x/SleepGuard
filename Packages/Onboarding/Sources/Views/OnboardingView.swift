import DesignSystem
import Env
import FactoryKit
import SwiftUI

public struct OnboardingView: View {
  @Injected(\.userPreferences) private var userPreferences
  @Injected(\.theme) private var theme
  @Injected(\.hapticManager) private var hapticManager
  @State private var currentPage = 0
  private let totalPages = 6

  public init() {}

  public var body: some View {
    ZStack {
      theme.bgPrimary.ignoresSafeArea()

      VStack(spacing: 0) {
        topBar

        TabView(selection: $currentPage) {
          OnboardingPage1View(onContinue: { advance() })
            .tag(0)
          OnboardingPage2View(onContinue: { advance() })
            .tag(1)
          OnboardingPage3View(onContinue: { advance() })
            .tag(2)
          OnboardingPageHealthWatchView(onContinue: { advance() })
            .tag(3)
          OnboardingPage4View(onContinue: { advance() })
            .tag(4)
          OnboardingPage5View(onContinue: { finishOnboarding() })
            .tag(5)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))

        bottomControls
      }
    }
  }

  private func advance() {
    hapticManager.tap()
    withAnimation {
      currentPage = min(currentPage + 1, totalPages - 1)
    }
  }

  private func finishOnboarding() {
    hapticManager.tap()
    userPreferences.hasCompletedOnboarding = true
  }

  private var topBar: some View {
    HStack {
      Spacer()
      if currentPage < totalPages - 1 {
        Button(action: {
          hapticManager.tap()
          withAnimation {
            currentPage = totalPages - 1
          }
        }) {
          Text(Strings.actionSkip)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(theme.textSecondary)
            .padding(.trailing, 20)
        }
        .buttonStyle(ScaleButtonStyle())
      }
    }
    .frame(height: 44)
  }

  private var bottomControls: some View {
    VStack(spacing: 16) {
      progressDots

      Button(action: {
        hapticManager.tap()
        withAnimation {
          currentPage -= 1
        }
      }) {
        Text(Strings.actionBack)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(theme.textSecondary)
      }
      .buttonStyle(ScaleButtonStyle())
      .opacity(currentPage > 0 && currentPage < totalPages - 1 ? 1 : 0)
    }
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
