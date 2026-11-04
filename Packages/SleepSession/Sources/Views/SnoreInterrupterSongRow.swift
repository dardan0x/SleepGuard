import DesignSystem
import SwiftUI

/// Song selection row in the Snore Interrupter sheet: music tile, title,
/// current melody name, chevron.
struct SnoreInterrupterSongRow: View {
  @Environment(Theme.self) private var theme

  let melodyName: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        ZStack {
          RoundedRectangle(cornerRadius: 10)
            .fill(theme.accent)
            .frame(width: 40, height: 40)

          Image(systemName: "music.note")
            .font(.system(size: 18))
            .foregroundStyle(.white)
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(Strings.snoreInterrupterSoundSheet)
            .font(.system(size: 17))
            .foregroundStyle(theme.textPrimary)

          Text(melodyName)
            .font(.system(size: 13))
            .foregroundStyle(theme.textSecondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
      }
      .padding(12)
      .background(theme.bgCard)
      .cornerRadius(12)
    }
    .buttonStyle(.plain)
  }
}
