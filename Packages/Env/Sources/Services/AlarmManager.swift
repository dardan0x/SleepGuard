import Foundation
import UserNotifications
import Observation
import AudioEngine

@MainActor
@Observable
public final class AlarmManager {
  public static let shared = AlarmManager()

  public var isAlarmSet: Bool = false
  public var alarmTime: Date? = nil
  public var alarmWindowMinutes: Int = 30

  public private(set) var alarmTriggered: Bool = false

  private init() {
    requestNotificationPermission()
  }

  // MARK: - Configuration

  public func setAlarm(hour: Int, minute: Int, windowMinutes: Int = 30) {
    var components = DateComponents()
    components.hour = hour
    components.minute = minute
    guard let time = Calendar.current.date(from: components) else { return }

    alarmTime = time
    alarmWindowMinutes = windowMinutes
    isAlarmSet = true
    alarmTriggered = false
    scheduleNotification()
  }

  public func clearAlarm() {
    alarmTime = nil
    isAlarmSet = false
    alarmTriggered = false
    cancelNotification()
  }

  // MARK: - Smart Wake Evaluation

  /// Checks if the alarm should trigger now. Returns true if alarm fires.
  public func evaluate(currentTime: Date, snoringState: SnoringState) -> Bool {
    guard isAlarmSet, !alarmTriggered, let alarmTime else { return false }

    let calendar = Calendar.current
    let alarmComponents = calendar.dateComponents([.hour, .minute], from: alarmTime)

    // Build concrete alarm date relative to current time
    var targetComponents = calendar.dateComponents([.year, .month, .day], from: currentTime)
    targetComponents.hour = alarmComponents.hour
    targetComponents.minute = alarmComponents.minute
    targetComponents.second = 0

    guard var target = calendar.date(from: targetComponents) else { return false }

    // If target is before now, it's tomorrow
    if target <= currentTime {
      target = calendar.date(byAdding: .day, value: 1, to: target) ?? target
    }

    let windowStart = target.addingTimeInterval(-Double(alarmWindowMinutes) * 60)

    // Not in window yet
    guard currentTime >= windowStart else { return false }

    // Past exact alarm time — always trigger
    if currentTime >= target {
      alarmTriggered = true
      cancelNotification()
      return true
    }

    // In smart window — trigger if light or quiet snoring
    if snoringState == .light || snoringState == .quiet {
      alarmTriggered = true
      cancelNotification()
      return true
    }

    return false
  }

  public func snooze(minutes: Int = 10) {
    guard let alarmTime else { return }
    let calendar = Calendar.current
    var components = calendar.dateComponents([.hour, .minute], from: alarmTime)
    let totalMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0) + minutes
    components.hour = totalMinutes / 60
    components.minute = totalMinutes % 60
    if let newTime = calendar.date(from: components) {
      self.alarmTime = newTime
      alarmTriggered = false
      scheduleNotification()
    }
  }

  // MARK: - Notifications

  private func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
  }

  private func scheduleNotification() {
    guard let alarmTime else { return }

    let calendar = Calendar.current
    let alarmComponents = calendar.dateComponents([.hour, .minute], from: alarmTime)

    let now = Date()
    var targetComponents = calendar.dateComponents([.year, .month, .day], from: now)
    targetComponents.hour = alarmComponents.hour
    targetComponents.minute = alarmComponents.minute
    targetComponents.second = 0

    guard var target = calendar.date(from: targetComponents) else { return }
    if target <= now {
      target = calendar.date(byAdding: .day, value: 1, to: target) ?? target
    }

    let interval = target.timeIntervalSince(now)
    guard interval > 0 else { return }

    let content = UNMutableNotificationContent()
    content.title = "Wake Up"
    content.body = "Your smart alarm is going off"
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
    let request = UNNotificationRequest(identifier: "snoreguard-alarm", content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request)
  }

  private func cancelNotification() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["snoreguard-alarm"])
  }
}
