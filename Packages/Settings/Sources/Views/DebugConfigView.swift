#if DEBUG
import SwiftUI
import Env
import Models
import DesignSystem

/// Developer-only panel for overriding Remote Config values locally, without
/// touching the Firebase console. Overrides take precedence over remote/cached
/// values until reset. Strings here are intentionally not localized (dev-only).
struct DebugConfigView: View {
  @Environment(Theme.self) private var theme
  @Environment(AppConfig.self) private var appConfig

  @State private var tabConfigs: [TabConfig] = []
  @State private var learnIsVisible: Bool = false
  @State private var learnURL: String = ""
  @State private var learnOrder: Int = 2

  var body: some View {
    List {
      Section("Feature Flags") {
        ForEach(FeatureFlag.allCases, id: \.self) { flag in
          Toggle(flag.rawValue, isOn: Binding(
            get: { appConfig.overrideValue(for: flag) },
            set: { appConfig.setOverride(flag, $0) }
          ))
        }
      }

      Section("Tabs") {
        ForEach(tabConfigs.indices, id: \.self) { index in
          VStack(alignment: .leading, spacing: 8) {
            Toggle(tabConfigs[index].tab.rawValue, isOn: Binding(
              get: { tabConfigs[index].isVisible },
              set: { newValue in
                tabConfigs[index] = TabConfig(
                  tab: tabConfigs[index].tab,
                  isVisible: newValue,
                  order: tabConfigs[index].order
                )
              }
            ))
            Stepper("Order: \(tabConfigs[index].order)", value: Binding(
              get: { tabConfigs[index].order },
              set: { newValue in
                tabConfigs[index] = TabConfig(
                  tab: tabConfigs[index].tab,
                  isVisible: tabConfigs[index].isVisible,
                  order: newValue
                )
              }
            ), in: 0...10)
          }
        }
        Button("Apply Tab Changes") {
          appConfig.setTabOverrides(tabConfigs)
        }
      }

      Section("Learn") {
        Toggle("Visible", isOn: $learnIsVisible)
        TextField("URL", text: $learnURL)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
        Stepper("Order: \(learnOrder)", value: $learnOrder, in: 0...10)
        Button("Apply Learn Changes") {
          let config = LearnTabConfig(
            isVisible: learnIsVisible,
            url: learnURL.isEmpty ? nil : learnURL,
            order: learnOrder
          )
          appConfig.setLearnTabOverride(config)
        }
      }

      Section("Update Gate") {
        Text("Current app version compared against the gate. Mock values are 99.0.0.")
          .font(.footnote)
          .foregroundStyle(theme.textTertiary)
        Button("Mock Soft Update") {
          appConfig.setUpdateGateOverride(
            UpdateGate(minimumVersion: "0.0.0", recommendedVersion: "99.0.0")
          )
        }
        Button("Mock Hard Update") {
          appConfig.setUpdateGateOverride(
            UpdateGate(minimumVersion: "99.0.0", recommendedVersion: "99.0.0")
          )
        }
        Button("Clear Update Gate") {
          appConfig.setUpdateGateOverride(nil)
        }
      }

      Section("Diagnostics") {
        Text("Run without the Xcode debugger attached, then relaunch — Crashlytics uploads the report on next launch.")
          .font(.footnote)
          .foregroundStyle(theme.textTertiary)
        Button("Force Test Crash", role: .destructive) {
          fatalError("Crashlytics test crash")
        }
      }

      Section {
        Button("Reset All Overrides", role: .destructive) {
          appConfig.clearOverrides()
          tabConfigs = appConfig.effectiveTabs
          loadLearnConfig()
        }
      }
    }
    .navigationTitle("Debug Config")
    .onAppear {
      tabConfigs = appConfig.effectiveTabs
      loadLearnConfig()
    }
  }

  private func loadLearnConfig() {
    let config = appConfig.effectiveLearnTab
    learnIsVisible = config.isVisible
    learnURL = config.url ?? ""
    learnOrder = config.order
  }
}
#endif
