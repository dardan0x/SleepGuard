import SwiftUI
import SwiftData
import Env
import DesignSystem
import Models

@MainActor
public struct SettingsView: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(\.modelContext) private var modelContext
  @Environment(\.openURL) private var openURL

  @State private var showDeleteConfirmation = false
  @State private var showThemePicker = false
  @State private var showClipLengthPicker = false

  private var sensitivityValue: Binding<Double> {
    Binding {
      switch userPreferences.detectionSensitivity {
      case .low: 0
      case .medium: 1
      case .high: 2
      }
    } set: { newValue in
      switch Int(newValue) {
      case 0: userPreferences.detectionSensitivity = .low
      case 2: userPreferences.detectionSensitivity = .high
      default: userPreferences.detectionSensitivity = .medium
      }
    }
  }

  public init() {}

  public var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        titleRow

        detectionSection
        recordingSection
        appearanceSection
        dataSection
        aboutSection
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 24)
    }
    .background(theme.bgSecondary)
    #if !os(visionOS)
    .scrollContentBackground(.hidden)
    #endif
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

  // MARK: - Detection

  private var detectionSection: some View {
    VStack(alignment: .leading, spacing: 2) {
      sectionTitle("DETECTION")
      VStack(spacing: 16) {
        HStack {
          Text("Sensitivity")
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          Text(userPreferences.detectionSensitivity.displayName)
            .font(.system(size: 15))
            .foregroundStyle(theme.accent)
        }

        HStack(spacing: 8) {
          Text("Low")
            .font(.system(size: 12))
            .foregroundStyle(theme.textTertiary)
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              RoundedRectangle(cornerRadius: 2)
                .fill(theme.bgElevated)
                .frame(height: 4)
              RoundedRectangle(cornerRadius: 2)
                .fill(theme.accent)
                .frame(width: max(4, (geo.size.width - 20) * (sensitivityValue.wrappedValue / 2) + 10), height: 4)
              Circle()
                .fill(.white)
                .frame(width: 20, height: 20)
                .shadow(radius: 2)
                .offset(x: max(0, (geo.size.width - 20) * (sensitivityValue.wrappedValue / 2)))
            }
          }
          .frame(height: 20)
          Text("High")
            .font(.system(size: 12))
            .foregroundStyle(theme.textTertiary)
        }

        HStack(spacing: 10) {
          iconBackground("timer", color: theme.accent)
          Text("Min snore duration")
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          Text("\(Int(userPreferences.minSnoreDuration)) sec")
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          HStack(spacing: 8) {
            Button {
              if userPreferences.minSnoreDuration > 1 {
                userPreferences.minSnoreDuration -= 1
              }
            } label: {
              ZStack {
                RoundedRectangle(cornerRadius: 14)
                  .fill(theme.bgElevated)
                  .frame(width: 28, height: 28)
                Text("−")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(theme.textPrimary)
              }
            }
            Button {
              if userPreferences.minSnoreDuration < 10 {
                userPreferences.minSnoreDuration += 1
              }
            } label: {
              ZStack {
                RoundedRectangle(cornerRadius: 14)
                  .fill(theme.bgElevated)
                  .frame(width: 28, height: 28)
                Text("+")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(theme.textPrimary)
              }
            }
          }
        }
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }

  // MARK: - Recording

  private var recordingSection: some View {
    VStack(alignment: .leading, spacing: 2) {
      sectionTitle("RECORDING")
      VStack(spacing: 16) {
        HStack(spacing: 10) {
          iconBackground("doc.badge.plus", color: Color(hex: "#FF2D55"))
          Text("Save audio clips")
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          Toggle("", isOn: Binding(
            get: { userPreferences.saveAudioClips },
            set: { userPreferences.saveAudioClips = $0 }
          ))
          .labelsHidden()
          .tint(theme.scoreGreen)
        }

        Button {
          showClipLengthPicker = true
        } label: {
          HStack(spacing: 10) {
            iconBackground("scissors", color: theme.accent)
            Text("Max clip length")
              .font(.system(size: 15))
              .foregroundStyle(theme.textPrimary)
            Spacer()
            Text("\(Int(userPreferences.maxClipLength))s")
              .font(.system(size: 15))
              .foregroundStyle(theme.textTertiary)
            Image(systemName: "chevron.right")
              .font(.system(size: 15))
              .foregroundStyle(theme.textTertiary)
          }
        }
        .buttonStyle(.plain)
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }

  // MARK: - Appearance

  private var appearanceSection: some View {
    VStack(alignment: .leading, spacing: 2) {
      sectionTitle("APPEARANCE")
      VStack(spacing: 16) {
        Button {
          showThemePicker = true
        } label: {
          HStack(spacing: 10) {
            iconBackground("paintpalette", color: theme.scoreGreen)
            Text("Theme")
              .font(.system(size: 15))
              .foregroundStyle(theme.textPrimary)
            Spacer()
            Text(userPreferences.appearance.displayName)
              .font(.system(size: 15))
              .foregroundStyle(theme.textTertiary)
            Image(systemName: "chevron.right")
              .font(.system(size: 15))
              .foregroundStyle(theme.textTertiary)
          }
        }
        .buttonStyle(.plain)
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }

  // MARK: - Data

  private var dataSection: some View {
    VStack(alignment: .leading, spacing: 2) {
      sectionTitle("DATA")
      VStack(spacing: 16) {
        HStack(spacing: 10) {
          iconBackground("heart.fill", color: Color(hex: "#FF2D55"))
          Text("Sync to Apple Health")
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          Toggle("", isOn: Binding(
            get: { userPreferences.syncToHealthKit },
            set: { newValue in
              userPreferences.syncToHealthKit = newValue
              if newValue {
                Task {
                  await HealthKitSync.shared.requestAuthorization()
                }
              }
            }
          ))
          .labelsHidden()
          .tint(theme.scoreGreen)
        }

        Button {
          showDeleteConfirmation = true
        } label: {
          HStack(spacing: 10) {
            iconBackground("trash", color: theme.destructive)
            Text("Delete All Recordings")
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(theme.destructive)
            Spacer()
          }
        }
        .buttonStyle(.plain)
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }

  // MARK: - About

  private var aboutSection: some View {
    VStack(alignment: .leading, spacing: 2) {
      sectionTitle("ABOUT")
      VStack(spacing: 16) {
        HStack(spacing: 10) {
          iconBackground("info.circle.fill", color: Color(hex: "#7C7CFF"))
          Text("Version")
            .font(.system(size: 15))
            .foregroundStyle(theme.textPrimary)
          Spacer()
          Text(appVersion)
            .font(.system(size: 15))
            .foregroundStyle(theme.textTertiary)
        }

        Button {
          rateApp()
        } label: {
          HStack(spacing: 10) {
            iconBackground("star.fill", color: Color(hex: "#FF9F0A"))
            Text("Rate on App Store")
              .font(.system(size: 15))
              .foregroundStyle(theme.accent)
            Spacer()
            Image(systemName: "chevron.right")
              .font(.system(size: 15))
              .foregroundStyle(theme.textTertiary)
          }
        }
        .buttonStyle(.plain)
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
  }

  // MARK: - Helpers

  private func sectionTitle(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 11, weight: .semibold))
      .foregroundStyle(theme.textTertiary)
      .tracking(1)
  }

  private func iconBackground(_ systemName: String, color: Color) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 7)
        .fill(color)
        .frame(width: 28, height: 28)
      Image(systemName: systemName)
        .font(.system(size: 14))
        .foregroundStyle(.white)
    }
  }

  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
  }

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
}
