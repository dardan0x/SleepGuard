import SwiftUI
import SwiftData
import Env
import DesignSystem
import Models

@MainActor
public struct SettingsView: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(WatchConnectivityManager.self) private var watchConnectivityManager
  @Environment(HealthKitSync.self) private var healthKitSync
  @Environment(\.modelContext) private var modelContext
  @Environment(\.openURL) private var openURL

  @State private var showDeleteConfirmation = false
  @State private var showThemePicker = false
  @State private var showClipLengthPicker = false
  @State private var showAlarmWindowPicker = false

  public init() {}

  public var body: some View {
    VStack(spacing: 0) {
      titleRow
        .padding(.horizontal, 20)
        .padding(.top, 10)

      ScrollView {
        VStack(spacing: 24) {
          SettingsDetectionSection()
          SettingsAlarmSection(onShowWindowPicker: { showAlarmWindowPicker = true })
          SettingsRecordingSection(onShowClipLengthPicker: { showClipLengthPicker = true })
          SettingsAppearanceSection(onShowThemePicker: { showThemePicker = true })
          SettingsWatchSection()
          SettingsDataSection(onShowDeleteConfirmation: { showDeleteConfirmation = true })
          SettingsAboutSection(onRateApp: rateApp)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 24)
      }
    }
    .background(theme.bgSecondary)
    #if !os(visionOS)
    .scrollContentBackground(.hidden)
    #endif
    .toolbar(.hidden, for: .navigationBar)
    .confirmationDialog("Choose Theme", isPresented: $showThemePicker, titleVisibility: .visible) {
      ForEach(UserPreferences.AppearanceSetting.allCases, id: \.self) { option in
        Button(option.displayName) {
          userPreferences.appearance = option
        }
      }
    }
    .confirmationDialog("Max Clip Length", isPresented: $showClipLengthPicker, titleVisibility: .visible) {
      ForEach([15.0, 30.0, 60.0], id: \.self) { length in
        Button("\(Int(length))s") {
          userPreferences.maxClipLength = length
        }
      }
    }
    .confirmationDialog("Smart Window", isPresented: $showAlarmWindowPicker, titleVisibility: .visible) {
      ForEach([15, 30, 45], id: \.self) { minutes in
        Button("\(minutes) min") {
          userPreferences.alarmWindowMinutes = minutes
        }
      }
    }
    .alert("Delete All Recordings?", isPresented: $showDeleteConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Delete All", role: .destructive) {
        deleteAllData()
      }
    } message: {
      Text("This will permanently delete all sleep sessions and snore events. This action cannot be undone.")
    }
  }

  // MARK: - Title

  private var titleRow: some View {
    HStack {
      Text("Settings")
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(theme.textPrimary)
      Spacer()
      ZStack {
        RoundedRectangle(cornerRadius: 15)
          .fill(theme.accent)
          .frame(width: 30, height: 30)
        Image(systemName: "gearshape.fill")
          .font(.system(size: 16))
          .foregroundStyle(.white)
      }
    }
  }

  // MARK: - Actions

  private func deleteAllData() {
    do {
      let sessionsDescriptor = FetchDescriptor<SleepSession>()
      let sessions = try modelContext.fetch(sessionsDescriptor)
      for session in sessions {
        modelContext.delete(session)
      }
      try modelContext.save()
    } catch {
      // Silent failure — no toast infrastructure in this app
    }
  }

  private func rateApp() {
    guard let writeReviewURL = URL(string: "https://apps.apple.com/app/id0?action=write-review") else { return }
    openURL(writeReviewURL)
  }
}

// MARK: - Display Helpers

extension UserPreferences.DetectionSensitivity {
  var displayName: String {
    switch self {
    case .low: "Low"
    case .medium: "Medium"
    case .high: "High"
    }
  }
}

extension UserPreferences.AppearanceSetting {
  var displayName: String {
    switch self {
    case .light: "Light"
    case .dark: "Dark"
    case .system: "System"
    }
  }
}

#Preview {
  SettingsView()
    .environment(Theme.shared)
    .environment(UserPreferences.shared)
    .environment(WatchConnectivityManager.shared)
    .environment(HealthKitSync.shared)
}
