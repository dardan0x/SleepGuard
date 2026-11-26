import Config
import DesignSystem
import FactoryKit
import Services
import SleepCore
import SwiftUI

/// The Snore Interrupter's settings, hosting the shared content. Edits a
/// draft and writes it to the preferences on Save.
@MainActor
struct SnoreInterrupterSheet: View {
  @Injected(\.userPreferences) private var userPreferences
  @Injected(\.customMelodyStorage) private var customMelodyStorage
  @Environment(\.dismiss) private var dismiss

  @State private var draftMode: SnoreInterrupterMode = .never
  @State private var draftMelodyID = Melody.defaultID
  @State private var showMelodyPicker = false

  var body: some View {
    SnoreInterrupterSettingsContent(
      mode: $draftMode,
      melodyName: customMelodyStorage.resolve(id: draftMelodyID).name,
      onSound: { showMelodyPicker = true },
      onSave: {
        userPreferences.snoreInterrupterMode = draftMode
        userPreferences.selectedMelodyID = draftMelodyID
        dismiss()
      },
      onCancel: { dismiss() })
      .onAppear {
        draftMode = userPreferences.snoreInterrupterMode
        draftMelodyID = userPreferences.selectedMelodyID
      }
      .sheet(isPresented: $showMelodyPicker) {
        MelodyPickerSheet(selectedMelodyID: $draftMelodyID)
      }
  }
}
