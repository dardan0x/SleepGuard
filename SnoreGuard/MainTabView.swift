import SwiftUI
import Env
import DesignSystem
import SleepSession
import Statistics
import Recordings
import Settings

struct MainTabView: View {
  @Environment(Theme.self) private var theme
  @Environment(SessionManager.self) private var sessionManager
  @State private var selectedTab = 0

  var body: some View {
    if #available(iOS 26.0, *) {
      systemTabView
    } else {
      customTabView
    }
  }

  // MARK: - iOS 26+ (system TabView)

  private var systemTabView: some View {
    TabView {
      StatisticsTab()
        .toolbar(sessionManager.isRecording ? .hidden : .visible, for: .tabBar)
        .tabItem {
          Label(Strings.tabStatistics, systemImage: "chart.bar.fill")
        }

      RecordingsTab()
        .toolbar(sessionManager.isRecording ? .hidden : .visible, for: .tabBar)
        .tabItem {
          Label(Strings.tabMedia, systemImage: "waveform")
        }

      SettingsTab()
        .toolbar(sessionManager.isRecording ? .hidden : .visible, for: .tabBar)
        .tabItem {
          Label(Strings.tabSettings, systemImage: "gearshape")
        }
    }
    .tint(theme.accent)
    .toolbarBackground(theme.bgSecondary, for: .tabBar)
  }

  // MARK: - iOS < 26 (custom floating tab bar)

  private var customTabView: some View {
    ZStack(alignment: .bottom) {
      customContent

      if !sessionManager.isRecording {
        customTabBar
      }
    }
    .ignoresSafeArea(.keyboard)
  }

  @ViewBuilder
  private var customContent: some View {
    StatisticsTab()
      .opacity(selectedTab == 0 ? 1 : 0)
      .allowsHitTesting(selectedTab == 0)

    RecordingsTab()
      .opacity(selectedTab == 1 ? 1 : 0)
      .allowsHitTesting(selectedTab == 1)

    SettingsTab()
      .opacity(selectedTab == 2 ? 1 : 0)
      .allowsHitTesting(selectedTab == 2)
  }

  private var customTabBar: some View {
    VStack(spacing: 0) {
      Spacer()

      HStack(spacing: 4) {
        tabItem(index: 0, icon: "chart.bar.fill", label: Strings.tabStatistics)
        tabItem(index: 1, icon: "waveform", label: Strings.tabMedia)
        tabItem(index: 2, icon: "gearshape", label: Strings.tabSettings)
      }
      .padding(4)
      .background(theme.bgCard)
      .clipShape(Capsule())
      .overlay(
        Capsule()
          .stroke(theme.border, lineWidth: 1)
      )
      .padding(.horizontal, 21)
      .padding(.bottom, 12)
      .padding(.top, 12)
      .background(theme.bgSecondary.ignoresSafeArea(edges: .bottom))
    }
  }

  private func tabItem(index: Int, icon: String, label: String) -> some View {
    let isSelected = selectedTab == index

    return Button {
      withAnimation(.spring(duration: 0.3)) {
        selectedTab = index
      }
    } label: {
      VStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 18, weight: .semibold))

        Text(label)
          .font(.system(size: 10, weight: .semibold))
          .tracking(0.5)
          .textCase(.uppercase)
      }
      .foregroundStyle(isSelected ? theme.textPrimary : theme.tabInactive)
      .frame(maxWidth: .infinity)
      .frame(height: 54)
      .background(isSelected ? theme.accent : Color.clear)
      .clipShape(RoundedRectangle(cornerRadius: 26))
    }
    .buttonStyle(.plain)
  }
}


