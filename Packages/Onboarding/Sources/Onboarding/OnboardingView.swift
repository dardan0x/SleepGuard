import SwiftUI

public struct OnboardingView: View {
  @State private var currentPage = 0

  public init() {}

  public var body: some View {
    TabView(selection: $currentPage) {
      Text("Onboarding Page 1")
        .tag(0)
      Text("Onboarding Page 2")
        .tag(1)
      Text("Onboarding Page 3")
        .tag(2)
      Text("Onboarding Page 4")
        .tag(3)
      Text("Onboarding Page 5")
        .tag(4)
    }
    .tabViewStyle(.page(indexDisplayMode: .always))
  }
}
