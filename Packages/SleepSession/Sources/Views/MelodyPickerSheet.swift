import DesignSystem
import Env
import Models
import SwiftUI

@MainActor
struct MelodyPickerSheet: View {
  @Environment(Theme.self) private var theme
  @Environment(\.dismiss) private var dismiss

  @Binding var selectedMelodyID: Int

  @State private var previewPlayer = MelodyPreviewPlayer()
  @State private var showRecordSheet = false

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Button {
          previewPlayer.stop()
          dismiss()
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 17))
            .foregroundStyle(theme.accent)
        }
        .buttonStyle(.plain)

        Spacer()
      }
      .frame(height: 44)
      .padding(.horizontal, 16)

      ScrollView {
        VStack(spacing: 8) {
          RecordCustomMelodyRow {
            previewPlayer.stop()
            showRecordSheet = true
          }

          if !CustomMelodyStorage.shared.customMelodies.isEmpty {
            ForEach(CustomMelodyStorage.shared.customMelodies) { melody in
              melodyRow(melody)
            }
          }

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
    .background(theme.bgPrimary.ignoresSafeArea())
    .onDisappear {
      previewPlayer.stop()
    }
    .sheet(isPresented: $showRecordSheet) {
      RecordCustomMelodySheet()
    }
  }

  private func melodyRow(_ melody: Melody) -> some View {
    MelodyPickerRow(
      melody: melody,
      isSelected: selectedMelodyID == melody.id,
      isPreviewing: previewPlayer.previewingMelodyID == melody.id,
      onTap: {
        withAnimation(.spring(duration: 0.25)) {
          selectedMelodyID = melody.id
        }
        previewPlayer.preview(melody)
      },
      onDelete: {
        CustomMelodyStorage.shared.deleteMelody(id: melody.id)
        if selectedMelodyID == melody.id {
          selectedMelodyID = 6
        }
      }
    )
  }

  // MARK: - Bottom Area

  private var bottomArea: some View {
    VStack(spacing: 0) {
      Divider()
        .background(theme.border)

      Button {
        previewPlayer.stop()
        dismiss()
      } label: {
        Text(Strings.saveMelodyPickerSheet)
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
