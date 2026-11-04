import AVFoundation
import Foundation

@MainActor
final class WatchAudioRecorder: ObservableObject {
  private var engine: AVAudioEngine?
  private var timer: Timer?

  @Published var currentDB: Float = -60.0

  func startRecording() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
    try? session.setActive(true)

    let engine = AVAudioEngine()
    self.engine = engine

    let input = engine.inputNode
    let format = input.outputFormat(forBus: 0)

    input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
      guard let self else { return }
      let level = calculateDB(buffer: buffer)
      Task { @MainActor in
        self.currentDB = level
      }
    }

    try? engine.start()
  }

  func stopRecording() {
    engine?.inputNode.removeTap(onBus: 0)
    engine?.stop()
    engine = nil
    try? AVAudioSession.sharedInstance().setActive(false)
  }

  private func calculateDB(buffer: AVAudioPCMBuffer) -> Float {
    guard let channelData = buffer.floatChannelData?[0] else { return -60.0 }
    let frameLength = UInt32(buffer.frameLength)
    var sum: Float = 0
    for i in 0..<Int(frameLength) {
      sum += abs(channelData[i])
    }
    let avg = sum / Float(frameLength)
    guard avg > 0 else { return -60.0 }
    return 20 * log10(avg)
  }
}
