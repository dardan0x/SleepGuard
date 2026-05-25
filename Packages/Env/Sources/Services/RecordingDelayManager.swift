import Foundation
import UserNotifications
import Observation

public extension Notification.Name {
  static let recordingDelayDidComplete = Notification.Name("recordingDelayDidComplete")
}

@MainActor
@Observable
public final class RecordingDelayManager {
  public static let shared = RecordingDelayManager()

  public var isActive = false
  public var targetDate: Date?
  public var currentRemainingSeconds: Int = 0

  private var timer: Timer?
  private let notificationId = "sleepguard-delayed-recording"

  private init() {}

  public func startDelay(minutes: Int) {
    guard minutes > 0 else {
      finish()
      return
    }
    targetDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
    isActive = true
    updateCurrentRemainingSeconds()
    scheduleNotification(minutes: minutes)
    startTimer()
  }

  public func cancel() {
    isActive = false
    targetDate = nil
    currentRemainingSeconds = 0
    timer?.invalidate()
    timer = nil
    cancelNotification()
  }

  public func finish() {
    cancel()
  }

  public var remainingTimeString: String {
    let minutes = currentRemainingSeconds / 60
    let seconds = currentRemainingSeconds % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }

  public func checkIfComplete() -> Bool {
    guard isActive, let targetDate else { return false }
    if Date() >= targetDate {
      finish()
      return true
    }
    return false
  }

  // MARK: - Private

  private func startTimer() {
    timer?.invalidate()
    timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
      guard let self, self.isActive else { return }
      self.updateCurrentRemainingSeconds()
      if self.checkIfComplete() {
        NotificationCenter.default.post(name: .recordingDelayDidComplete, object: nil)
      }
    }
    RunLoop.main.add(timer!, forMode: .common)
  }

  private func updateCurrentRemainingSeconds() {
    guard let targetDate else {
      currentRemainingSeconds = 0
      return
    }
    currentRemainingSeconds = max(0, Int(targetDate.timeIntervalSinceNow))
  }

  // MARK: - Notifications

  private func scheduleNotification(minutes: Int) {
    let content = UNMutableNotificationContent()
    content.title = "SleepGuard"
    content.body = "Your recording session is starting now"
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
    let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request)
  }

  private func cancelNotification() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
  }
}
