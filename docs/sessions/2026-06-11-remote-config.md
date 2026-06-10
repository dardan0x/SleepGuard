---
date: 2026-06-11
feature: none
branch: feature/remote-config/firebase-flags-tabs-update-gating
title: Firebase Remote Config — Feature Flags, Configurable Tabs & Update Gating
---

### Completed
- Remote-config foundation: feature flags, configurable tabs, and soft/hard update gating, all driven by Firebase Remote Config with offline-safe defaults.
- Firebase was discovered already integrated (SDK incl. `FirebaseRemoteConfig`, `GoogleService-Info.plist`, `FirebaseApp.configure()`), so the loader was built this session rather than deferred.

### Technical Details
- Resolution order for every config value: debug override (DEBUG only) → last good remote fetch (UserDefaults cache) → baked-in default.
- `AppConfig` is a Firebase-free `@MainActor @Observable .shared` service in `Env`. Firebase types are isolated to the app-target `RemoteConfigLoader`, which decodes RC JSON and calls `AppConfig.apply(...)`.
- RC keys: `feature_flags` (JSON object), `tabs` (JSON array of `TabConfig`), `minimum_version`, `recommended_version`.
- `TabCoordinator.selectedTab` changed from `Int` to `AppTab`; `TabResetSignal.tab` likewise. `MainTabView` now builds both the iOS 26 system `TabView` and the legacy custom bar from `appConfig.visibleTabsInOrder` via `ForEach`, with `ensureValidSelection` resetting selection if the active tab is hidden.
- `UpdateGateView` (DesignSystem) compares `CFBundleShortVersionString` to the gate: below `minimum_version` → blocking screen; below `recommended_version` → dismissible prompt (once per recommended version via `@AppStorage`).
- `RemoteConfigLoader` uses `minimumFetchInterval = 0` (DEBUG) / `3600` (release); refresh on launch and every `scenePhase == .active`.
- DEBUG-only `DebugConfigView` (Settings) flips flags + tab config locally; reachable via a `#if DEBUG` "Debug Config" button.
- Feature-flag UI gating wired for `sleepBriefing` (MainTabView) and `watchApp` (SettingsView). Remaining flags have keys + `isEnabled` available; entry-point gating mapped in `docs/remote-config-schema.md`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/AppConfigModels.swift` | new | `FeatureFlag`, `AppTab`, `TabConfig`, `UpdateGate` |
| `Packages/Env/Sources/Services/AppConfig.swift` | new | Firebase-free observable config store + cache + debug overrides |
| `Packages/Env/Sources/Services/Router.swift` | ~±10 | `TabCoordinator`/`TabResetSignal` Int → `AppTab`; import Models |
| `SleepGuard/RemoteConfig/RemoteConfigLoader.swift` | new | Firebase RC fetch → `AppConfig.apply` |
| `SleepGuard/SleepGuardApp.swift` | ~±15 | inject `AppConfig`, update-gate overlay, RC refresh on launch/active, `openAppStore` |
| `SleepGuard/AppRegistry.swift` | ~±4 | `AppConfig` in both env wiring funcs |
| `SleepGuard/MainTabView.swift` | ~±60 | data-driven tabs (system + custom), `view(for:)`/`title(for:)`/`ensureValidSelection`, briefing gate |
| `SleepGuard/StatisticsTab.swift` / `RecordingsTab.swift` / `SettingsTab.swift` | ~±1 each | reset-signal compares against `AppTab` cases |
| `Packages/DesignSystem/Sources/Components/UpdateGateView.swift` | new | soft/hard update UI + version compare + `Bundle.shortVersionString` |
| `Packages/Settings/Sources/Views/DebugConfigView.swift` | new | DEBUG override panel |
| `Packages/Settings/Sources/Views/SettingsView.swift` | ~±15 | `AppConfig` env, watch-section gate, debug entry + sheet |
| `Packages/DesignSystem/Sources/Resources/Strings.txt` + generated | +6 | update-prompt strings |
| `docs/remote-config-schema.md` | new | RC key reference + entry-point map |

### Architecture Decisions
- **Firebase isolation in app target**: `AppConfig` exposes plain Swift values so feature packages (which import `Env`) never transitively link Firebase, satisfying module-isolation rules.
- **Tabs keyed by `AppTab` not Int**: required for remote reorder/hide; index-based tags can't survive reordering.
- **Gating = UI visibility only**: background processing untouched; `snoringDetection` kill-switch left as an open decision rather than guessed.
- **Partial entry-point gating**: only cleanly-bounded gates (briefing, watch) wired this pass; deeper gates touch subview signatures and are documented for on-demand wiring to keep the diff surgical.

### Build Status
- **BUILD SUCCEEDED** — zero warnings/errors (two pre-existing warnings in unrelated code remain).

### Changes done
```
- Add FeatureFlag/AppTab/TabConfig/UpdateGate models
- Add Firebase-free AppConfig service (resolution order + cache + debug overrides)
- Add RemoteConfigLoader bridging Firebase RC into AppConfig
- Make tabs data-driven (TabCoordinator + MainTabView) keyed by AppTab
- Add UpdateGateView soft/hard update gating
- Add DEBUG-only DebugConfigView override panel
- Gate sleepBriefing + watchApp entry points
- Add update-prompt strings + docs/remote-config-schema.md
```

### Next Session
- Configure the 4 RC parameters in the Firebase console (see `docs/remote-config-schema.md`) and verify the fetch loop on-device.
- Wire remaining feature-flag entry points per the map in `docs/remote-config-schema.md` (trends, calendar, soothingMelody, healthSync, audioClips, pdfReport, enhancedSleepTracking, sleepTalkingDetection, sleepScore, lifestyleLogging).
- Replace the placeholder App Store ID in `SleepGuardApp.openAppStore()`.

### Open Questions
- Should `snoringDetection` off also halt the detector (kill-switch) or only hide UI?
- Commit `GoogleService-Info.plist`, or gitignore it? (Already present in the repo at `SleepGuard/Configuration/`.)
