import SwiftUI

@main
struct SnoreGuardWatchApp: App {
  @WKApplicationDelegateAdaptor(WatchAppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

class WatchAppDelegate: NSObject, WKApplicationDelegate {
  func applicationDidFinishLaunching() {
    WatchSessionManager.shared.activate()
  }
}
