import DesignSystem
import SwiftUI

/// The "Record yours" entry row at the top of the melody picker.
struct RecordCustomMelodyRow: View {
  @Environment(Theme.self) private var theme

  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(theme.accent.opacity(0.15))
            .frame(width: 36, height: 36)

          Image(systemName: "mic.fill")
            .font(.system(size: 16))
            .foregroundStyle(theme.accent)
        }

        Text(Strings.recordYoursMelodyPickerSheet)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(theme.accent)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(theme.accent.opacity(0.3), lineWidth: 1.5)
          .blendMode(.screen)
      )
    }
    .buttonStyle(.plain)
  }
}
