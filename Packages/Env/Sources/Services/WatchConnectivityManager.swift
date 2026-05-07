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
  public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    isWatchReachable = session.isReachable
  }

  public func sessionDidBecomeInactive(_ session: WCSession) {}

  public func sessionDidDeactivate(_ session: WCSession) {
    WCSession.default.activate()
  }

  public func sessionWatchStateDidChange(_ session: WCSession) {
    isWatchReachable = session.isReachable
  }

  public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    handleMessage(message)
  }

  public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    handleMessage(applicationContext)
  }

  private func handleMessage(_ message: [String: Any]) {
    guard let type = message["type"] as? String, type == "session" else { return }
    lastSyncedSession = Date()
  }
}
