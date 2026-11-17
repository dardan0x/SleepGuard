import DesignSystem
import Env
import FactoryKit
import SleepCore
import SwiftUI

/// Choosing the interrupter's sound, hosting the shared picker: previews each
/// choice, records a new one, deletes recordings.
@MainActor
struct MelodyPickerSheet: View {
  @Injected(\.customMelodyStorage) private var customMelodyStorage
  @Environment(\.dismiss) private var dismiss

  @Binding var selectedMelodyID: Int

  @State private var previewPlayer = MelodyPreviewPlayer()
  @State private var showRecordSheet = false

  var body: some View {
    MelodyPickerContent(
      custom: customMelodyStorage.customMelodies,
      selectedID: selectedMelodyID,
      previewingID: previewPlayer.previewingMelodyID,
      onRecord: {
        previewPlayer.stop()
        showRecordSheet = true
      },
      onSelect: { melody in
        withAnimation(.spring(duration: 0.25)) {
          selectedMelodyID = melody.id
        }
        previewPlayer.preview(melody)
      },
      onDelete: { melody in
        customMelodyStorage.deleteMelody(id: melody.id)
        if selectedMelodyID == melody.id {
          selectedMelodyID = Melody.defaultID
        }
      },
      onDone: {
        previewPlayer.stop()
        dismiss()
      })
      .onDisappear { previewPlayer.stop() }
      .sheet(isPresented: $showRecordSheet) {
        RecordCustomMelodySheet()
      }
  }
}
