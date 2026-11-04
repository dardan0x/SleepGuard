import AVFoundation
import DesignSystem
import Env
import SwiftUI

@MainActor
struct RecordCustomMelodySheet: View {
  @Environment(Theme.self) private var theme
  @Environment(\.dismiss) private var dismiss

  @State private var viewState: ViewState = .idle
  @State private var elapsed: TimeInterval = 0
  @State private var permissionGranted = false
  @State private var recorder: AVAudioRecorder?
  @State private var recordedURL: URL?
  @State private var playbackPlayer: AVAudioPlayer?
  @State private var isPlaying = false
  @State private var timer: Timer?

  private let maxDuration: TimeInterval = 10

  enum ViewState {
    case idle
    case recording
    case recorded
  }

  var body: some View {
    VStack(spacing: 0) {
      SheetHandle()
      SheetNavHeader(title: Strings.recordMelodySheetNavHeader, onBack: { dismiss() })
      Divider().background(theme.border)

      Spacer()

      VStack(spacing: 32) {
        timerDisplay

        recordButton

        if case .recorded = viewState {
          playbackButton
        }
      }

      Spacer()

      if case .recorded = viewState {
        actionButtons
      }
    }
    .background(theme.bgPrimary.ignoresSafeArea())
    .onAppear {
      checkPermission()
    }
    .onDisappear {
      cleanup()
    }
  }

  // MARK: - Timer Display

  private var timerDisplay: some View {
    Text(formatTime(elapsed))
      .font(.system(size: 56, weight: .light, design: .monospaced))
      .foregroundStyle(theme.textPrimary)
      .contentTransition(.numericText())
  }

  // MARK: - Record Button

  private var recordButton: some View {
    Button {
      switch viewState {
      case .idle:
        startRecording()
      case .recording:
        stopRecording()
      case .recorded:
        startRecording()
      }
    } label: {
      ZStack {
        Circle()
          .fill(viewState == .recording ? theme.bgCard : Color(hex: "#FF453A"))
          .frame(width: 88, height: 88)

        if viewState == .recording {
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
    .disabled(!permissionGranted)
    .overlay(
      Circle()
        .stroke(viewState == .recording ? Color(hex: "#FF453A").opacity(0.5) : Color.clear, lineWidth: 4)
        .frame(width: 100, height: 100)
        .scaleEffect(viewState == .recording ? 1.15 : 1.0)
        .opacity(viewState == .recording ? 0 : 1)
        .animation(viewState == .recording ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: viewState)
    )
  }

  // MARK: - Playback Button

  private var playbackButton: some View {
    Button {
      togglePlayback()
    } label: {
      HStack(spacing: 8) {
        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
          .font(.system(size: 16, weight: .semibold))
        Text(isPlaying ? Strings.stopRecordCustomMelodySheet : Strings.playRecordCustomMelodySheet)
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
        saveRecording()
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
        discardAndReset()
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

  // MARK: - Recording Logic

  private func checkPermission() {
    switch AVAudioSession.sharedInstance().recordPermission {
    case .granted:
      permissionGranted = true
    case .denied:
      permissionGranted = false
    case .undetermined:
      Task {
        let granted = await withCheckedContinuation { continuation in
          AVAudioSession.sharedInstance().requestRecordPermission { granted in
            continuation.resume(returning: granted)
          }
        }
        permissionGranted = granted
      }
    @unknown default:
      permissionGranted = false
    }
  }

  private func startRecording() {
    cleanup()

    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
      try session.setActive(true)
    } catch {
      print("[RecordCustomMelodySheet] Failed to configure session: \(error)")
      return
    }

    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("custom_melody_temp.m4a")
    if FileManager.default.fileExists(atPath: tempURL.path) {
      try? FileManager.default.removeItem(at: tempURL)
    }

    let settings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 44100,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
    ]

    do {
      let rec = try AVAudioRecorder(url: tempURL, settings: settings)
      rec.record()
      recorder = rec
      recordedURL = tempURL
      viewState = .recording
      elapsed = 0

      timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak rec] _ in
        Task { @MainActor in
          guard let rec, rec.isRecording else { return }
          elapsed = rec.currentTime
          if rec.currentTime >= maxDuration {
            stopRecording()
          }
        }
      }
    } catch {
      print("[RecordCustomMelodySheet] Failed to start recording: \(error)")
    }
  }

  private func stopRecording() {
    timer?.invalidate()
    timer = nil
    recorder?.stop()
    elapsed = recorder?.currentTime ?? elapsed
    recorder = nil
    viewState = .recorded

    try? AVAudioSession.sharedInstance().setActive(false)
  }

  private func togglePlayback() {
    if isPlaying {
      playbackPlayer?.stop()
      playbackPlayer = nil
      isPlaying = false
      return
    }

    guard let url = recordedURL else { return }
    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.volume = 0.8
      player.play()
      playbackPlayer = player
      isPlaying = true

      Task {
        try? await Task.sleep(for: .seconds(player.duration + 0.1))
        playbackPlayer = nil
        isPlaying = false
      }
    } catch {
      print("[RecordCustomMelodySheet] Failed to play back: \(error)")
    }
  }

  private func saveRecording() {
    guard let url = recordedURL else { return }
    let name = "My Sound \(CustomMelodyStorage.shared.allCustomMelodies().count + 1)"
    _ = CustomMelodyStorage.shared.saveRecording(name: name, from: url)
    dismiss()
  }

  private func discardAndReset() {
    cleanup()
    viewState = .idle
    elapsed = 0
    recordedURL = nil
  }

  private func cleanup() {
    timer?.invalidate()
    timer = nil
    recorder?.stop()
    recorder = nil
    playbackPlayer?.stop()
    playbackPlayer = nil
    isPlaying = false
    if let url = recordedURL {
      try? FileManager.default.removeItem(at: url)
      recordedURL = nil
    }
  }

  // MARK: - Formatting

  private func formatTime(_ time: TimeInterval) -> String {
    let total = Int(time)
    let seconds = total % 60
    let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
    return String(format: "%d.%d", seconds, tenths)
  }
}
