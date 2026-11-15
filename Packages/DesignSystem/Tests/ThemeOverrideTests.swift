import FactoryKit
import FactoryTesting
import SwiftUI
import Testing
@testable import DesignSystem

/// `ThemeProviding`'s double is a separate `AppTheme()` with tokens changed:
/// a preview or test can restyle without touching `AppTheme.shared`.
@Suite(.container)
struct ThemeOverrideTests {
  @Test func registeredThemeReplacesTheSharedOne() {
    let custom = AppTheme()
    custom.accent = .pink
    Container.shared.theme.register { custom }

    #expect(Container.shared.theme() === custom)
    #expect(Container.shared.theme().accent == .pink)
    #expect(AppTheme.shared.accent != .pink)
  }

  @Test func helpersReadTheInstanceTokens() {
    let custom = AppTheme()
    custom.scoreGreen = .mint
    let theme: any ThemeProviding = custom

    #expect(theme.scoreColor(90) == .mint)
  }

  /// Every token starts from the shared design kit's SleepGuard theme, so the
  /// kit's components and SleepGuard's own views use the same colours.
  @Test func defaultsAreTheDesignKitsSleepGuardTheme() {
    #expect(AppTheme().designKitTheme == Theme.sleepGuard)
  }

  @Test func overridesReachTheDesignKitTheme() {
    let custom = AppTheme()
    custom.accent = .pink
    custom.radiusCard = 24
    #expect(custom.designKitTheme.palette.accent == .pink)
    #expect(custom.designKitTheme.radii.card == 24)
  }
}
