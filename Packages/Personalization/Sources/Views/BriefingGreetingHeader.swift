import DesignSystem
import SwiftUI

@MainActor
public struct BriefingGreetingHeader: View {
  let greeting: String
  @Environment(Theme.self) private var theme

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
