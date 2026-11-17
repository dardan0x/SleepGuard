import DesignSystem
import Env
import FactoryKit
import Models
import SleepCore
import SwiftData
import SwiftUI

/// The profile prompt on Statistics: the shared `ProfilePromptCard`, shown by
/// SleepCore's `ProfilePrompt` rule. Its chance is drawn once per appearance
/// (SleepGuard's card redrew it on every update, so it could flicker).
public struct ProfilePromptSection: View {
  @Injected(\.userPreferences) private var userPreferences
  @Injected(\.hapticManager) private var hapticManager
  @Query private var sessions: [SleepSession]
  @Query private var profiles: [UserProfile]
  let onOpen: () -> Void
  @State private var roll = Double.random(in: 0..<1)
  @State private var coin = Bool.random()
  @State private var isDismissed = false

  public init(onOpen: @escaping () -> Void) {
    self.onOpen = onOpen
  }

  public var body: some View {
    if !isDismissed, shouldShow {
      ProfilePromptCard(
        onOpen: {
          hapticManager.tap()
          onOpen()
        },
        onDismiss: {
          hapticManager.tap()
          userPreferences.profilePromptDismissCount += 1
          isDismissed = true
        })
    }
  }

  private var shouldShow: Bool {
    ProfilePrompt.shouldShow(
      fullNights: sessions.filter { $0.totalDuration >= SleepSession.minimumSaveDuration }.count,
      completion: profiles.first?.completionPercentage ?? 0,
      dismissCount: userPreferences.profilePromptDismissCount, roll: roll, coin: coin)
  }
}
