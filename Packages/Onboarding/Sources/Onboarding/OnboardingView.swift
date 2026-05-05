import SwiftUI
import Env
import DesignSystem

public struct OnboardingView: View {
  @Environment(UserPreferences.self) private var userPreferences
  @State private var currentPage = 0
  private let totalPages = 5

  public init() {}

  public var body: some View {
    ZStack {
      Theme.shared.backgroundColor
        .ignoresSafeArea()

      VStack(spacing: 0) {
        topBar

        TabView(selection: $currentPage) {
          OnboardingPage1View(onContinue: { advance() })
            .tag(0)
          OnboardingPage2View(onContinue: { advance() })
            .tag(1)
          OnboardingPage3View(onContinue: { advance() })
            .tag(2)
          OnboardingPage4View(onContinue: { advance() })
            .tag(3)
          OnboardingPage5View(onContinue: { finishOnboarding() })
            .tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))

        bottomControls
      }
    }
  }

  private func advance() {
    withAnimation {
      currentPage = min(currentPage + 1, totalPages - 1)
    }
  }

  private func finishOnboarding() {
    userPreferences.hasCompletedOnboarding = true
  }

  private var topBar: some View {
    HStack {
      Spacer()
      if currentPage < totalPages - 1 {
        Button("Skip") {
          withAnimation {
            currentPage = totalPages - 1
          }
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(Theme.shared.secondaryLabelColor)
        .padding(.trailing, 20)
      }
    }
    .frame(height: 44)
  }

  private var bottomControls: some View {
    VStack(spacing: 16) {
      progressDots

      if currentPage > 0 && currentPage < totalPages - 1 {
        Button("Back") {
          withAnimation {
            currentPage -= 1
          }
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(Theme.shared.secondaryLabelColor)
      }
    }
    .padding(.bottom, 32)
  }

  private var progressDots: some View {
    HStack(spacing: 8) {
      ForEach(0..<totalPages, id: \.self) { index in
        RoundedRectangle(cornerRadius: 4)
          .fill(index == currentPage ? Theme.shared.primaryColor : Theme.shared.surfaceColor)
          .frame(width: index == currentPage ? 24 : 8, height: 8)
          .animation(.spring(duration: 0.35), value: currentPage)
      }
    }
  }
}
