import DesignSystem
import Env
import Models
import SwiftUI

/// Floating capsule tab bar used on iOS < 26. Renders the chrome and items;
/// selection is reported through `onSelect` so the owner keeps coordinator
/// and animation control.
struct CustomTabBarView: View {
  let theme = Theme.shared

  let tabs: [AppTab]
  let selectedTab: AppTab
  let titleFor: (AppTab) -> String
  let onSelect: (AppTab) -> Void

  @Namespace private var tabAnimation

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      HStack(spacing: 4) {
        ForEach(tabs, id: \.self) { tab in
          tabItem(tab: tab, icon: tab.iconName, label: titleFor(tab), isSelected: selectedTab == tab)
        }
      }
      .padding(6)
      .background(
        ZStack {
          Capsule()
            .fill(
              LinearGradient(
                colors: [.white.opacity(0.07), .clear],
                startPoint: .top,
                endPoint: .bottom)
            )
        }
      )
      .overlay(
        Capsule()
          .stroke(.white.opacity(0.1), lineWidth: 0.5)
      )
      .padding(.horizontal, 30)
      .background(
        ZStack {
          Color.clear
        }
        .ignoresSafeArea(edges: .all)
      )
    }
    .padding(.horizontal, 30)
  }

  private func tabItem(tab: AppTab, icon: String, label: String, isSelected: Bool) -> some View {
    Button {
      onSelect(tab)
    } label: {
      VStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 22, weight: .semibold))

        Text(label)
          .font(.system(size: 9, weight: .medium))
          .tracking(0.5)
      }
      .foregroundStyle(isSelected ? theme.accent : theme.textPrimary)
      .frame(maxWidth: .infinity)
      .frame(height: 54)
      .background(alignment: .center) {
        if isSelected {
          RoundedRectangle(cornerRadius: 26)
            .fill(theme.bgCard)
            .overlay(
              RoundedRectangle(cornerRadius: 26)
                .stroke(.white.opacity(0.08), lineWidth: 0.5)
            )
            .overlay(
              RoundedRectangle(cornerRadius: 26)
                .fill(
                  LinearGradient(
                    colors: [.white.opacity(0.06), .clear],
                    startPoint: .top,
                    endPoint: .bottom)
                )
            )
            .matchedGeometryEffect(id: "activeTab", in: tabAnimation)
        }
      }
    }
    .buttonStyle(.plain)
  }
}
