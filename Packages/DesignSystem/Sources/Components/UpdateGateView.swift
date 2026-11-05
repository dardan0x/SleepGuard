import FactoryKit
import Models
import SwiftUI

/// Presents a soft (dismissible) or hard (blocking) update prompt based on the
/// `UpdateGate` thresholds from Remote Config, compared against the running
/// app version. Renders nothing when the current version satisfies the gate.
public struct UpdateGateView: View {
  private let updateGate: UpdateGate
  private let currentVersion: String
  private let openAppStore: () -> Void

  @Injected(\.theme) private var theme
  @State private var softDismissed = false
  @AppStorage("lastSoftUpdatePromptVersion") private var lastSoftPromptVersion = ""

  public init(
    updateGate: UpdateGate,
    currentVersion: String = Bundle.main.shortVersionString,
    openAppStore: @escaping () -> Void)
  {
    self.updateGate = updateGate
    self.currentVersion = currentVersion
    self.openAppStore = openAppStore
  }

  private enum GateState { case none, soft, hard }

  private var state: GateState {
    if currentVersion.isVersionLower(than: updateGate.minimumVersion) { return .hard }
    if currentVersion.isVersionLower(than: updateGate.recommendedVersion) { return .soft }
    return .none
  }

  public var body: some View {
    switch state {
    case .none:
      EmptyView()
    case .hard:
      gate(
        title: Strings.updateHardTitle,
        message: Strings.updateHardBody,
        primary: Strings.updateActionUpdate,
        dismissible: false)
    case .soft:
      if !softDismissed, lastSoftPromptVersion != updateGate.recommendedVersion {
        gate(
          title: Strings.updateSoftTitle,
          message: Strings.updateSoftBody,
          primary: Strings.updateActionUpdate,
          dismissible: true)
      }
    }
  }

  private func gate(title: String, message: String, primary: String, dismissible: Bool) -> some View {
    ZStack {
      theme.bgPrimary.opacity(0.92)
        .ignoresSafeArea()

      VStack(spacing: 16) {
        Image(systemName: "arrow.up.circle.fill")
          .font(.system(size: 48))
          .foregroundStyle(theme.accent)

        Text(title)
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(theme.textPrimary)
          .multilineTextAlignment(.center)

        Text(message)
          .font(.system(size: 15))
          .foregroundStyle(theme.textSecondary)
          .multilineTextAlignment(.center)

        Button(action: openAppStore) {
          Text(primary)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusSmall))
        }
        .buttonStyle(.plain)

        if dismissible {
          Button {
            softDismissed = true
            lastSoftPromptVersion = updateGate.recommendedVersion
          } label: {
            Text(Strings.updateActionLater)
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(theme.textTertiary)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(28)
      .background(theme.bgCard)
      .clipShape(RoundedRectangle(cornerRadius: theme.radiusCard))
      .padding(.horizontal, 32)
    }
  }
}

private extension String {
  /// Compares dot-separated numeric versions ("1.4.0" < "1.5.0").
  func isVersionLower(than other: String) -> Bool {
    let lhs = split(separator: ".").map { Int($0) ?? 0 }
    let rhs = other.split(separator: ".").map { Int($0) ?? 0 }
    let count = max(lhs.count, rhs.count)
    for index in 0..<count {
      let l = index < lhs.count ? lhs[index] : 0
      let r = index < rhs.count ? rhs[index] : 0
      if l != r { return l < r }
    }
    return false
  }
}

public extension Bundle {
  var shortVersionString: String {
    object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
  }
}
