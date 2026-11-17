import DesignSystem
import FactoryKit
import SwiftUI

/// The prestart's recording options: the start delay and, when enabled, the
/// Snore Interrupter row and its note. SleepGuard only; sits in the shared
/// prestart content's options slot.
struct PrestartOptions: View {
  let showsSnoreInterrupter: Bool
  let snoreInterrupterValue: String
  let onSnoreInterrupter: () -> Void
  @Injected(\.theme) private var theme
  @Injected(\.userPreferences) private var userPreferences

  var body: some View {
    VStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 8) {
        PrestartDelayOptions(minutes: Binding(
          get: { userPreferences.recordingDelayMinutes },
          set: { userPreferences.recordingDelayMinutes = $0 }))
        if showsSnoreInterrupter {
          PrestartSnoreInterrupterRow(
            icon: "timer",
            title: Strings.snoreInterrupterRecordingPrestartViewTitle,
            value: snoreInterrupterValue,
            subtitle: Strings.snoreInterrupterLockscreenNote,
            action: onSnoreInterrupter)
            .padding(.top, 8)
        }
      }
      if showsSnoreInterrupter {
        Text(Strings.snoreInterrupterRowHelperText)
          .font(.system(size: 14))
          .foregroundStyle(theme.textTertiary)
          .multilineTextAlignment(.center)
          .lineLimit(nil)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity)
      }
    }
  }
}
