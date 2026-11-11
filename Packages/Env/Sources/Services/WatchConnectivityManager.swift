import Foundation
import Observation
import WatchConnectivity

@MainActor
@Observable
public final class WatchConnectivityManager: NSObject, WatchConnectivityManaging {
  public static let shared = WatchConnectivityManager()

  public var isWatchReachable = false
  public var lastSyncedSession: Date?

  override public init() {
    super.init()
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
  }

  public func checkReachability() {
    isWatchReachable = WCSession.default.isReachable
  }
}

extension WatchConnectivityManager: WCSessionDelegate {
  public nonisolated func session(_ session: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {
    let reachable = session.isReachable
    Task { @MainActor in
      isWatchReachable = reachable
    }
  }

  public nonisolated func sessionDidBecomeInactive(_: WCSession) {}

  public nonisolated func sessionDidDeactivate(_: WCSession) {
    WCSession.default.activate()
  }

  public nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
    let reachable = session.isReachable
    Task { @MainActor in
      isWatchReachable = reachable
    }
  }

  public nonisolated func session(_: WCSession, didReceiveMessage message: [String: Any]) {
    handleMessage(message)
  }

  public nonisolated func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    handleMessage(applicationContext)
  }

  private nonisolated func handleMessage(_ message: [String: Any]) {
    guard let type = message["type"] as? String, type == "session" else { return }
    Task { @MainActor in
      self.lastSyncedSession = Date()
    }
  }
}
