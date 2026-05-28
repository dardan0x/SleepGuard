# SleepGuard Watch App

This directory contains the Apple Watch companion app for SleepGuard.

## Manual Setup Required

The Watch app target must be added to the main Xcode project manually. The source code is ready — only the Xcode target configuration is needed.

### Steps

1. **Open SleepGuard.xcodeproj in Xcode**

2. **Add Watch App Target**
   - File → New → Target
   - Select "watchOS" tab → "App"
   - Product Name: `SleepGuardWatch`
   - Language: Swift
   - Interface: SwiftUI
   - Uncheck "Include Notification Scene"
   - Finish

3. **Replace Generated Files**
   - Delete the auto-generated `ContentView.swift` and `<AppName>App.swift` in the Watch target
   - Add the files from `WatchApp/Sources/` to the Watch target:
     - `SleepGuardWatchApp.swift`
     - `ContentView.swift`
     - `WatchSessionManager.swift`
     - `WatchAudioRecorder.swift`

4. **Add Framework Capabilities**
   - Select the Watch Extension target → Signing & Capabilities
   - Add "Background Modes" → check "Audio"

5. **Build the Watch App**
   - Select the Watch scheme
   - Build (⌘+B)

The iOS app already includes `WatchConnectivityManager` in the Env package and shows Watch connection status in Settings.
