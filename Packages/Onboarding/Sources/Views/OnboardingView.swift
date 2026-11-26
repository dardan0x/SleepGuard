import AudioEngine
import Config
import DesignSystem
import FactoryKit
import Health
import Models
import Platform
import Services
import SleepCore
public import SwiftUI
import SleepGuardContentKit

/// First launch, hosting the shared onboarding content: asks for Apple Health
/// (when the `healthSync` flag is on) and the microphone, then finishes.
/// "Start recording" opens a night once the tabs are up.
public struct OnboardingView: View {
  /// How long "granted" shows before the next page.
  static let grantedPause: Duration = .seconds(0.8)

  @Injected(\.userPreferences) private var userPreferences
  @Injected(\.hapticManager) private var hapticManager
  @Injected(\.audioRecorder) private var audioRecorder
  @Injected(\.healthKitSync) private var healthKitSync
  @Injected(\.appConfig) private var appConfig
  @State private var page = OnboardingPage.welcome
  @State private var microphone = OnboardingPermission.notAsked
  @State private var health = OnboardingPermission.notAsked

  public init() {}

  public var body: some View {
    OnboardingContent(
      pages: pages, current: $page, microphone: microphone, health: health,
      onRequestMicrophone: requestMicrophone, onRequestHealth: requestHealth,
      onStartRecording: {
        userPreferences.presentRecordingAfterOnboarding = true
        finish()
      },
      onBrowse: finish)
      .onChange(of: page) { hapticManager.tap() }
      .onAppear {
        if audioRecorder.hasPermission { microphone = .granted }
        healthKitSync.checkAuthorizationStatus()
        if healthKitSync.isAuthorized { health = .granted }
      }
  }

  private var pages: OnboardingPages {
    OnboardingPages(hasHealth: appConfig.isEnabled(.healthSync))
  }

  private func requestMicrophone() {
    Task {
      microphone = .requesting
      let granted = await audioRecorder.requestPermission()
      microphone = granted ? .granted : .notAsked
      await moveOn(from: .microphone, granted: granted)
    }
  }

  private func requestHealth() {
    Task {
      health = .requesting
      let granted = await healthKitSync.requestAuthorization()
      health = granted ? .granted : .notAsked
      if granted {
        if !userPreferences.hasExplicitlySetSyncToHealthKit { userPreferences.syncToHealthKit = true }
        if !userPreferences.hasExplicitlySetEnhancedSleepTracking { userPreferences.enhancedSleepTracking = true }
      }
      await moveOn(from: .health, granted: granted)
    }
  }

  /// Shows "granted" for a moment, then the next page (denied moves on at once).
  private func moveOn(from current: OnboardingPage, granted: Bool) async {
    if granted { try? await Task.sleep(for: Self.grantedPause) }
    withAnimation { page = pages.next(after: current) }
  }

  private func finish() {
    hapticManager.tap()
    userPreferences.hasCompletedOnboarding = true
  }
}
