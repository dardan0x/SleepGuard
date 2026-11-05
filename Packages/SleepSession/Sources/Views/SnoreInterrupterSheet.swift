import DesignSystem
import Env
import FactoryKit
import Models
import SwiftUI

@MainActor
struct SnoreInterrupterSheet: View {
  @Injected(\.theme) private var theme
  @Injected(\.userPreferences) private var userPreferences
  @Environment(\.dismiss) private var dismiss

  @State private var draftMode: UserPreferences.SnoreInterrupterMode = .never
  @State private var draftMelodyID = 6
  @State private var showMelodyPicker = false

  private var selectedMelody: Melody? {
    Melody.melody(id: draftMelodyID)
      ?? CustomMelodyStorage.shared.melody(id: draftMelodyID)
  }

  var body: some View {
    VStack(spacing: 0) {
      SheetHandle()

      SheetNavHeader(
        title: Strings.snoreInterrupterRecordingPrestartViewTitle.uppercased(),
        onBack: { dismiss() })

      Divider()
        .background(theme.border)

      ScrollView {
        VStack(spacing: 20) {
          descriptionSection

          SnoreInterrupterDurationPicker(selection: $draftMode)

          SnoreInterrupterSongRow(melodyName: selectedMelody?.name ?? Strings.snoreInterrupterDefaultMelodyName) {
            showMelodyPicker = true
          }

          SnoreInterrupterStatusBadge(isEnabled: draftMode != .never)
        }
        .padding(.top, 24)
        .padding(.horizontal, 20)
      }

      Spacer()

      SnoreInterrupterButtons(
        onSave: {
          userPreferences.snoreInterrupterMode = draftMode
          userPreferences.selectedMelodyID = draftMelodyID
          dismiss()
        },
        onCancel: { dismiss() })
    }
    .background(theme.bgPrimary.ignoresSafeArea())
    .onAppear {
      draftMode = userPreferences.snoreInterrupterMode
      draftMelodyID = userPreferences.selectedMelodyID
    }
    .sheet(isPresented: $showMelodyPicker) {
      MelodyPickerSheet(selectedMelodyID: $draftMelodyID)
    }
  }

  // MARK: - Sections

  private var descriptionSection: some View {
    VStack(spacing: 2) {
      Text(Strings.snoreInterrupterSheetDescSectionTitle)
        .font(.system(size: 15))
        .foregroundStyle(theme.textPrimary)
        .multilineTextAlignment(.center)

      Text(Strings.snoreInterrupterSheetDescSectionSubtitle)
        .font(.system(size: 15))
        .foregroundStyle(theme.textDim)
        .multilineTextAlignment(.center)
    }
  }
}
