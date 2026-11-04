import SwiftUI

/// Header bar of the sleep-stages info sheet: title + close button.
struct SleepStagesInfoHeader: View {
  @Environment(Theme.self) private var theme
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    HStack {
      Text(Strings.sleepStagesInfoTitle)
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(theme.textPrimary)

      Spacer()

      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.system(size: 22))
          .foregroundStyle(theme.textTertiary)
      }
      .accessibilityLabel(Strings.actionClose)
    }
  }
}
