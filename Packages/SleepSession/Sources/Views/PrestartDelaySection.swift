import DesignSystem
import Env
import SwiftUI

/// Recording-delay picker on the prestart screen: one button per delay
/// option; the selection writes to `UserPreferences.recordingDelayMinutes`
/// with the same spring animation as before.
struct PrestartDelaySection: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences

  private let delayOptions = [0, 15, 30, 45, 60]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(Strings.sessionPrestartDelayLabel)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(theme.textPrimary)

      HStack(spacing: 8) {
        ForEach(delayOptions, id: \.self) { minutes in
          delayButton(minutes: minutes)
        }
      }
    }
    .padding(16)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  private func delayButton(minutes: Int) -> some View {
    let isSelected = userPreferences.recordingDelayMinutes == minutes
    let label = minutes == 0 ? Strings.sessionPrestartDelayOff : (minutes == 60 ? "1h" : "\(minutes)m")

    return Button {
      withAnimation(.spring(duration: 0.25)) {
        userPreferences.recordingDelayMinutes = minutes
      }
    } label: {
      Text(label)
        .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
        .foregroundStyle(isSelected ? theme.textPrimary : theme.textSecondary)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(isSelected ? theme.accent : theme.bgElevated)
        .cornerRadius(12)
    }
    .buttonStyle(.plain)
  }
}
