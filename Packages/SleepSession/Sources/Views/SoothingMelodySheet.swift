import DesignSystem
import Env
import Models
import SwiftUI

@MainActor
struct SoothingMelodySheet: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(\.dismiss) private var dismiss

  @State private var draftMode: UserPreferences.SoothingMelodyMode = .never
  @State private var draftMelodyID: Int = 12
  @State private var showMelodyPicker = false

  private var selectedMelody: Melody? {
    Melody.melody(id: draftMelodyID)
  }

  private var isMelodyEnabled: Bool {
    draftMode != .never
  }

  var body: some View {
    VStack(spacing: 0) {
      SheetHandle()

      SheetNavHeader(
        title: "SOOTHING MELODY",
        onBack: { dismiss() }
      )

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
    .background(theme.bgSecondary.ignoresSafeArea())
    .onAppear {
      draftMode = userPreferences.soothingMelodyMode
      draftMelodyID = userPreferences.selectedMelodyID
    }
    .sheet(isPresented: $showMelodyPicker) {
      MelodyPickerSheet(selectedMelodyID: $draftMelodyID)
    }
  }

  // MARK: - Sections

  private var descriptionSection: some View {
    VStack(spacing: 2) {
      Text("We'll play a tune for this duration when snoring is detected.")
        .font(.system(size: 15))
        .foregroundStyle(theme.textPrimary)
        .multilineTextAlignment(.center)

      Text("Always plays from the start.")
        .font(.system(size: 15))
        .foregroundStyle(theme.textDim)
        .multilineTextAlignment(.center)
    }
  }

  private var durationPicker: some View {
    Picker("Duration", selection: $draftMode) {
      ForEach(UserPreferences.SoothingMelodyMode.allCases, id: \.self) { mode in
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
          Text("Soothing tune")
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

      Text(isMelodyEnabled ? "Melody enabled" : "Melody disabled")
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
        userPreferences.soothingMelodyMode = draftMode
        userPreferences.selectedMelodyID = draftMelodyID
        dismiss()
      } label: {
        Text("SAVE")
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

// MARK: - Sheet Handle

struct SheetHandle: View {
  var body: some View {
    HStack {
      Spacer()
      RoundedRectangle(cornerRadius: 2)
        .fill(Color(hex: "#8E8E93").opacity(0.5))
        .frame(width: 36, height: 4)
      Spacer()
    }
    .frame(height: 28)
  }
}

// MARK: - Sheet Nav Header

struct SheetNavHeader: View {
  @Environment(Theme.self) private var theme
  let title: String
  let onBack: () -> Void

  var body: some View {
    HStack {
      Button(action: onBack) {
        HStack(spacing: 2) {
          Image(systemName: "chevron.left")
            .font(.system(size: 17))
            .foregroundStyle(theme.accent)
        }
      }
      .buttonStyle(.plain)
      .frame(width: 80, alignment: .leading)

      Spacer()

      Text(title)
        .font(.system(size: 13, weight: .semibold))
        .tracking(1.5)
        .foregroundStyle(theme.textPrimary)

      Spacer()

      Color.clear
        .frame(width: 80)
    }
    .frame(height: 52)
    .padding(.horizontal, 16)
  }
}
