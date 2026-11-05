import DesignSystem
import FactoryKit
import SwiftUI

@MainActor
public struct BriefingGreetingHeader: View {
  let greeting: String
  @Injected(\.theme) private var theme

  public init(greeting: String) {
    self.greeting = greeting
  }

  public var body: some View {
    Text(greeting)
      .font(.system(size: 28, weight: .bold))
      .foregroundStyle(theme.textPrimary)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
