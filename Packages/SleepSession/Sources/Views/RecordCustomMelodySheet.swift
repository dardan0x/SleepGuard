import DesignSystem
import Env
import FactoryKit
import SwiftUI

@MainActor
struct RecordCustomMelodySheet: View {
  @Injected(\.theme) private var theme
  @Environment(\.dismiss) private var dismiss

  @State private var recorder = CustomMelodyRecorder()

  var body: some View {
    VStack(spacing: 0) {
      SheetHandle()
      SheetNavHeader(title: Strings.recordMelodySheetNavHeader, onBack: { dismiss() })
      Divider().background(theme.border)

      Spacer()

      VStack(spacing: 32) {
        timerDisplay

        recordButton

        if case .recorded = recorder.state {
          playbackButton
        }
      }

      Spacer()

      if case .recorded = recorder.state {
        actionButtons
      }
    }
    .background(theme.bgPrimary.ignoresSafeArea())
    .onAppear {
      recorder.checkPermission()
    }
    .onDisappear {
      recorder.cleanup()
    }
  }

  // MARK: - Timer Display

  private var timerDisplay: some View {
    Text(formatTime(recorder.elapsed))
      .font(.system(size: 56, weight: .light, design: .monospaced))
      .foregroundStyle(theme.textPrimary)
      .contentTransition(.numericText())
  }

  // MARK: - Record Button

  private var recordButton: some View {
    Button {
      switch recorder.state {
      case .idle:
        recorder.startRecording()
      case .recording:
        recorder.stopRecording()
      case .recorded:
        recorder.startRecording()
      }
    } label: {
      ZStack {
        Circle()
          .fill(recorder.state == .recording ? theme.bgCard : Color(hex: "#FF453A"))
          .frame(width: 88, height: 88)

        if recorder.state == .recording {
          RoundedRectangle(cornerRadius: 4)
            .fill(theme.textPrimary)
            .frame(width: 28, height: 28)
        } else {
          Circle()
            .fill(theme.textPrimary)
            .frame(width: 32, height: 32)
        }
      }
    }
    .buttonStyle(.plain)
    .disabled(!recorder.permissionGranted)
    .overlay(
      Circle()
        .stroke(recorder.state == .recording ? Color(hex: "#FF453A").opacity(0.5) : Color.clear, lineWidth: 4)
        .frame(width: 100, height: 100)
        .scaleEffect(recorder.state == .recording ? 1.15 : 1.0)
        .opacity(recorder.state == .recording ? 0 : 1)
        .animation(recorder.state == .recording ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: recorder.state)
    )
  }

  // MARK: - Playback Button

  private var playbackButton: some View {
    Button {
      recorder.togglePlayback()
    } label: {
      HStack(spacing: 8) {
        Image(systemName: recorder.isPlaying ? "stop.fill" : "play.fill")
          .font(.system(size: 16, weight: .semibold))
        Text(recorder.isPlaying ? Strings.stopRecordCustomMelodySheet : Strings.playRecordCustomMelodySheet)
          .font(.system(size: 15, weight: .semibold))
      }
      .foregroundStyle(theme.accent)
      .frame(width: 140, height: 44)
      .background(
        RoundedRectangle(cornerRadius: 22)
          .stroke(theme.accent, lineWidth: 1.5)
      )
    }
    .buttonStyle(.plain)
  }

  // MARK: - Action Buttons

  private var actionButtons: some View {
    VStack(spacing: 12) {
      Button {
        if recorder.save() {
          dismiss()
        }
      } label: {
        Text(Strings.saveRecordCustomMelodySheet)
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
        recorder.discardAndReset()
      } label: {
        Text(Strings.reRecordCustomMelodySheet)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(theme.textSecondary)
          .frame(maxWidth: .infinity)
          .frame(height: 44)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 34)
  }

  // MARK: - Formatting

  private func formatTime(_ time: TimeInterval) -> String {
    let total = Int(time)
    let seconds = total % 60
    let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
    return String(format: "%d.%d", seconds, tenths)
  }
}
