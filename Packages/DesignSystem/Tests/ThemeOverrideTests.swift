import FactoryKit
import FactoryTesting
import SwiftUI
import Testing
@testable import DesignSystem

/// `ThemeProviding`'s double is a separate `Theme()` with tokens changed:
/// a preview or test can restyle without touching `Theme.shared`.
@Suite(.container)
struct ThemeOverrideTests {
  @Test func registeredThemeReplacesTheSharedOne() {
    let custom = Theme()
    custom.accent = .pink
    Container.shared.theme.register { custom }

    #expect(Container.shared.theme() === custom)
    #expect(Container.shared.theme().accent == .pink)
    #expect(Theme.shared.accent != .pink)
  }

  @Test func helpersReadTheInstanceTokens() {
    let custom = Theme()
    custom.scoreGreen = .mint
    let theme: any ThemeProviding = custom

    #expect(theme.scoreColor(90) == .mint)
  }
}
