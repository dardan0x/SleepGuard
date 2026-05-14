import Foundation
import WatchConnectivity
import SwiftUI

@MainActor
final class WatchSessionManager: NSObject, ObservableObject {
  static let shared = WatchSessionManager()

  @Published var isRecording = false
  @Published var eventsCount = 0
  @Published var currentDB: Float = -60.0
  @Published var duration: TimeInterval = 0

  private var startDate: Date?
  private var timer: Timer?
  private var audioRecorder = WatchAudioRecorder()

  private override init() {
    super.init()
  }

  func activate() {
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
  }

  func startSession() {
    isRecording = true
    startDate = Date()
    eventsCount = 0
    duration = 0
    audioRecorder.startRecording()

    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.tick()
      }
    }
  }

  func stopSession() {
    isRecording = false
    timer?.invalidate()
    timer = nil
    audioRecorder.stopRecording()

    guard let startDate else { return }
    let sessionDuration = Date().timeIntervalSince(startDate)

    let payload: [String: Any] = [
      "type": "session",
      "startDate": startDate.timeIntervalSince1970,
      "duration": sessionDuration,
      "eventsCount": eventsCount,
    ]

    if WCSession.default.isReachable {
      WCSession.default.sendMessage(payload, replyHandler: nil) { _ in }
    } else {
      try? WCSession.default.updateApplicationContext(payload)
    }

    self.startDate = nil
  }

  private func tick() {
    guard let startDate else { return }
    duration = Date().timeIntervalSince(startDate)
    currentDB = audioRecorder.currentDB

    if audioRecorder.currentDB > -30 {
      eventsCount += 1
    }
  }

  var durationString: String {
    let total = Int(duration)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    if hours > 0 {
      return String(format: "%d h %d min", hours, minutes)
    }
    return String(format: "%d min", minutes)
  }

  var statusLabel: String {
    if currentDB > -20 { return "Loud snoring" }
    if currentDB > -30 { return "Light snoring" }
    if currentDB > -40 { return "Quiet snoring" }
    return "Quiet"
  }
}

extension WatchSessionManager: WCSessionDelegate {
  nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
