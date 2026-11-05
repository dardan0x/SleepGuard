import DesignSystem
import FactoryKit
import SwiftUI

/// Save + cancel buttons at the bottom of the Snore Interrupter sheet.
struct SnoreInterrupterButtons: View {
  @Injected(\.theme) private var theme

  let onSave: () -> Void
  let onCancel: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      Button(action: onSave) {
        Text(Strings.saveMelodyPickerSheet)
          .font(.system(size: 15, weight: .bold))
          .tracking(2)
          .foregroundStyle(theme.textPrimary)
          .frame(maxWidth: .infinity)
          .frame(height: 56)
          .background(theme.bgCard)
          .cornerRadius(28)
      }
      .buttonStyle(.plain)

      Button(action: onCancel) {
        Text(Strings.actionCancel)
          .font(.system(size: 17))
          .foregroundStyle(theme.textPrimary)
          .frame(maxWidth: .infinity)
          .frame(height: 44)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 34)
  }
}
