import Foundation
import WatchConnectivity
import Observation

@MainActor
@Observable
public final class WatchConnectivityManager: NSObject {
  public static let shared = WatchConnectivityManager()

  public var isWatchReachable: Bool = false
  public var lastSyncedSession: Date?

  private override init() {
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
  nonisolated public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    let reachable = session.isReachable
    Task { @MainActor in
      isWatchReachable = reachable
    }
  }

  nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {}

  nonisolated public func sessionDidDeactivate(_ session: WCSession) {
    WCSession.default.activate()
  }

  nonisolated public func sessionWatchStateDidChange(_ session: WCSession) {
    let reachable = session.isReachable
    Task { @MainActor in
      isWatchReachable = reachable
    }
  }

  nonisolated public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    handleMessage(message)
  }

  nonisolated public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    handleMessage(applicationContext)
  }

  nonisolated private func handleMessage(_ message: [String: Any]) {
    guard let type = message["type"] as? String, type == "session" else { return }
    Task { @MainActor in
      self.lastSyncedSession = Date()
    }
  }
}
