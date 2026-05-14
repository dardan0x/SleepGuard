import DesignSystem
import Models
import SwiftUI

@MainActor
struct MelodyPickerSheet: View {
  @Environment(Theme.self) private var theme
  @Environment(\.dismiss) private var dismiss

  @Binding var selectedMelodyID: Int

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Button {
          dismiss()
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "chevron.left")
              .font(.system(size: 17))
              .foregroundStyle(theme.accent)
          }
        }
        .buttonStyle(.plain)

        Spacer()
      }
      .frame(height: 44)
      .padding(.horizontal, 16)

      ScrollView {
        VStack(spacing: 8) {
          ForEach(Melody.allMelodies) { melody in
            melodyRow(melody)
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 8)
      }

      Spacer()

      bottomArea
    }
    .background(theme.bgSecondary.ignoresSafeArea())
  }

  // MARK: - Rows

  private func melodyRow(_ melody: Melody) -> some View {
    let isSelected = selectedMelodyID == melody.id

    return Button {
      withAnimation(.spring(duration: 0.25)) {
        selectedMelodyID = melody.id
      }
    } label: {
      HStack(spacing: 12) {
        ZStack {
          if isSelected {
            Circle()
              .fill(theme.accent)
              .frame(width: 36, height: 36)

            Image(systemName: "music.note")
              .font(.system(size: 16))
              .foregroundStyle(.white)
          } else {
            Image(systemName: "music.note")
              .font(.system(size: 18))
              .foregroundStyle(theme.textTertiary)
              .frame(width: 36, height: 36)
          }
        }

        Text(melody.name)
          .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
          .foregroundStyle(theme.textPrimary)

        Spacer()

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

  // MARK: - Bottom Area

  private var bottomArea: some View {
    VStack(spacing: 0) {
      Divider()
        .background(theme.border)

      Button {
        dismiss()
      } label: {
        Text("SAVE")
          .font(.system(size: 15, weight: .bold))
          .tracking(1.5)
          .foregroundStyle(theme.textPrimary)
          .frame(maxWidth: .infinity)
          .frame(height: 66)
      }
      .buttonStyle(.plain)

      RoundedRectangle(cornerRadius: 3)
        .fill(theme.textPrimary)
        .frame(width: 134, height: 5)
        .padding(.bottom, 8)
    }
  }
}
