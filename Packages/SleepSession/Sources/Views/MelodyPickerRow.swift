import DesignSystem
import FactoryKit
import Models
import SwiftUI

/// A single melody row in the picker: selection state ring, previewing
/// speaker bounce, name, custom-melody delete, and the selected checkmark.
struct MelodyPickerRow: View {
  @Injected(\.theme) private var theme

  let melody: Melody
  let isSelected: Bool
  let isPreviewing: Bool
  let onTap: () -> Void
  let onDelete: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 12) {
        ZStack {
          if isSelected {
            Circle()
              .fill(theme.accent)
              .frame(width: 36, height: 36)

            if isPreviewing {
              PreviewSpeakerIcon(size: 16, color: .white)
            } else {
              Image(systemName: "music.note")
                .font(.system(size: 16))
                .foregroundStyle(.white)
            }
          } else {
            if isPreviewing {
              PreviewSpeakerIcon(size: 18, color: theme.accent)
                .frame(width: 36, height: 36)
            } else {
              Image(systemName: "music.note")
                .font(.system(size: 18))
                .foregroundStyle(theme.textTertiary)
                .frame(width: 36, height: 36)
            }
          }
        }

        Text(melody.name)
          .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
          .foregroundStyle(theme.textPrimary)

        Spacer()

        if melody.isCustom {
          Button(action: onDelete) {
            Image(systemName: "trash")
              .font(.system(size: 14))
              .foregroundStyle(theme.textTertiary)
              .padding(8)
          }
          .buttonStyle(.plain)
        }

        if isSelected {
          ZStack {
            Circle()
              .fill(theme.accent)
              .frame(width: 24, height: 24)

            Image(systemName: "checkmark")
              .font(.system(size: 12, weight: .bold))
              .foregroundStyle(.white)
          }
        }
      }
      .padding(isSelected ? 14 : 16)
      .background(theme.bgCard)
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 1.5)
      )
    }
    .buttonStyle(.plain)
  }
}

private struct PreviewSpeakerIcon: View {
  let size: CGFloat
  let color: Color

  var body: some View {
    if #available(iOS 18, *) {
      Image(systemName: "speaker.wave.2")
        .font(.system(size: size))
        .foregroundStyle(color)
        .symbolEffect(.bounce, options: .repeating)
    } else {
      Image(systemName: "speaker.wave.2")
        .font(.system(size: size))
        .foregroundStyle(color)
        .symbolEffect(.pulse)
    }
  }
}
