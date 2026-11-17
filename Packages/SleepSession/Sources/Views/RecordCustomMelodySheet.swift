import DesignSystem
import Env
import FactoryKit
import SleepCore
import SwiftUI

/// Recording your own interrupter sound, hosting the shared content. The
/// recorder holds the take; Save names it "My Sound N".
@MainActor
struct RecordCustomMelodySheet: View {
  @Environment(\.dismiss) private var dismiss

  @State private var recorder = CustomMelodyRecorder()

  var body: some View {
    RecordMelodyContent(
      state: state,
      elapsed: recorder.elapsed,
      canRecord: recorder.permissionGranted,
      onRecordToggle: {
        if recorder.state == .recording {
          recorder.stopRecording()
        } else {
          recorder.startRecording()
        }
      },
      onPlayToggle: { recorder.togglePlayback() },
      onSave: {
        if recorder.save(name: Melody.customName(number: recorder.nameNumber)) {
          dismiss()
        }
      },
      onReRecord: { recorder.discardAndReset() },
      onBack: { dismiss() })
      .onAppear { recorder.checkPermission() }
      .onDisappear { recorder.cleanup() }
  }

  private var state: MelodyRecordingState {
    switch recorder.state {
    case .idle: .idle
    case .recording: .recording
    case .recorded: .recorded(isPlaying: recorder.isPlaying)
    }
  }
}
