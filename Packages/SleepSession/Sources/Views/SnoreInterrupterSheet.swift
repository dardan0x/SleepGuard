import DesignSystem
import Env
import Models
import SwiftUI

@MainActor
struct SnoreInterrupterSheet: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(\.dismiss) private var dismiss

  @State private var draftMode: UserPreferences.SnoreInterrupterMode = .never
  @State private var draftMelodyID = 6
  @State private var showMelodyPicker = false

  private var selectedMelody: Melody? {
    Melody.melody(id: draftMelodyID)
      ?? CustomMelodyStorage.shared.melody(id: draftMelodyID)
  }

  private var isMelodyEnabled: Bool {
    draftMode != .never
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

          durationPicker

          songRow

          statusBadge
        }
        .padding(.top, 24)
        .padding(.horizontal, 20)
      }

      Spacer()

      buttonsArea
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

  private var durationPicker: some View {
    Picker(Strings.durationPickerTitle, selection: $draftMode) {
      ForEach(UserPreferences.SnoreInterrupterMode.allCases, id: \.self) { mode in
        Text(mode.displayLabel)
          .tag(mode)
      }
    }
    .pickerStyle(.wheel)
    .frame(height: 180)
    .background(theme.bgCard)
    .cornerRadius(12)
  }

  private var songRow: some View {
    Button {
      showMelodyPicker = true
    } label: {
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

          Text(selectedMelody?.name ?? "Melody 12")
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

  private var statusBadge: some View {
    HStack(spacing: 4) {
      Circle()
        .fill(theme.accent)
        .frame(width: 6, height: 6)

      Text(isMelodyEnabled ? Strings.soundEnabledSnoreInterrupterSheet : Strings.soundDisabledSnoreInterrupterSheet)
        .font(.system(size: 12))
        .foregroundStyle(theme.accent)
    }
    .padding(.vertical, 4)
    .padding(.horizontal, 10)
    .background(theme.accent.opacity(0.2))
    .overlay(
      Capsule()
        .stroke(theme.accent, lineWidth: 1)
    )
    .clipShape(Capsule())
  }

  private var buttonsArea: some View {
    VStack(spacing: 8) {
      Button {
        userPreferences.snoreInterrupterMode = draftMode
        userPreferences.selectedMelodyID = draftMelodyID
        dismiss()
      } label: {
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

      Button {
        dismiss()
      } label: {
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
