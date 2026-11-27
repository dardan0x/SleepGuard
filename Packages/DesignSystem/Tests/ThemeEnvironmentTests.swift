import SleepCore
import SleepGuardDesignKit
import SwiftUI
import Testing
@testable import DesignSystem

/// One theme system (F27-T13): every view reads the kit's `Theme` from the
/// SwiftUI environment, so a preview or test restyles everything by setting it.
@MainActor
struct ThemeEnvironmentTests {
  @Test func theEnvironmentDefaultsToSleepGuard() {
    #expect(EnvironmentValues().theme == .sleepGuard)
  }

  @Test func aCustomThemeIsWhatTheEnvironmentCarries() {
    var custom = Theme.sleepGuard
    custom.palette.accent = .pink
    var values = EnvironmentValues()
    values.theme = custom
    #expect(values.theme.palette.accent == .pink)
  }
}
