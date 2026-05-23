import AVFoundation
import DesignSystem
import Env
import Models
import SwiftUI

@MainActor
struct MelodyPickerSheet: View {
  @Environment(Theme.self) private var theme
  @Environment(\.dismiss) private var dismiss

  @Binding var selectedMelodyID: Int

  @State private var previewPlayer: AVAudioPlayer?
  @State private var previewingMelodyID: Int?
  @State private var previewTask: Task<Void, Never>?
  @State private var showRecordSheet = false

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Button {
          stopPreview()
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
          recordYoursRow

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
      stopPreview()
    }
    .sheet(isPresented: $showRecordSheet) {
      RecordCustomMelodySheet()
    }
  }

  // MARK: - Record Yours Row

  private var recordYoursRow: some View {
    Button {
      stopPreview()
      showRecordSheet = true
    } label: {
      HStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(theme.accent.opacity(0.15))
            .frame(width: 36, height: 36)

          Image(systemName: "mic.fill")
            .font(.system(size: 16))
            .foregroundStyle(theme.accent)
        }

          Text(Strings.recordYoursMelodyPickerSheet)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(theme.accent)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
      }
      .padding(16)
      .background(theme.bgCard)
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(theme.accent.opacity(0.3), lineWidth: 1.5)
          .blendMode(.screen)
      )
    }
    .buttonStyle(.plain)
  }

  // MARK: - Melody Rows

  private func melodyRow(_ melody: Melody) -> some View {
    let isSelected = selectedMelodyID == melody.id
    let isPreviewing = previewingMelodyID == melody.id

    return Button {
      withAnimation(.spring(duration: 0.25)) {
        selectedMelodyID = melody.id
      }
      previewMelody(melody)
    } label: {
      HStack(spacing: 12) {
        ZStack {
          if isSelected {
            Circle()
              .fill(theme.accent)
              .frame(width: 36, height: 36)

            if isPreviewing {
              Image(systemName: "speaker.wave.2")
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .symbolEffect(.bounce, options: .repeating)
            } else {
              Image(systemName: "music.note")
                .font(.system(size: 16))
                .foregroundStyle(.white)
            }
          } else {
            if isPreviewing {
              Image(systemName: "speaker.wave.2")
                .font(.system(size: 18))
                .foregroundStyle(theme.accent)
                .frame(width: 36, height: 36)
                .symbolEffect(.bounce, options: .repeating)
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
          Button {
            CustomMelodyStorage.shared.deleteMelody(id: melody.id)
            if selectedMelodyID == melody.id {
              selectedMelodyID = 6
            }
          } label: {
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

  // MARK: - Preview

  private func previewMelody(_ melody: Melody) {
    if previewingMelodyID == melody.id {
      stopPreview()
      return
    }

    stopPreview()

    let url: URL?
    if melody.isCustom {
      url = CustomMelodyStorage.shared.fileURL(for: melody)
    } else {
      url = Bundle.main.url(forResource: melody.filename, withExtension: "mp3", subdirectory: "sounds")
        ?? Bundle.main.url(forResource: melody.filename, withExtension: "mp3")
    }

    guard let fileURL = url else { return }

    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default)
      try session.setActive(true)

      let player = try AVAudioPlayer(contentsOf: fileURL)
      player.volume = 0.8
      previewPlayer = player
      previewingMelodyID = melody.id

      guard player.prepareToPlay() else { return }
      let didPlay = player.play()
      guard didPlay else {
        previewingMelodyID = nil
        previewPlayer = nil
        return
      }

      previewTask?.cancel()
      previewTask = Task {
        try? await Task.sleep(for: .seconds(3))
        guard !Task.isCancelled else { return }
        stopPreview()
      }
    } catch {
      previewingMelodyID = nil
      previewPlayer = nil
    }
  }

  private func stopPreview() {
    previewTask?.cancel()
    previewTask = nil
    previewPlayer?.stop()
    previewPlayer = nil
    previewingMelodyID = nil
  }

  // MARK: - Bottom Area

  private var bottomArea: some View {
    VStack(spacing: 0) {
      Divider()
        .background(theme.border)

      Button {
        stopPreview()
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
