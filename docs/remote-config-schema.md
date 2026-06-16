# Remote Config Schema

Firebase Remote Config drives feature flags, tab configuration, and update gating.
This file documents every parameter so the Firebase console can be configured to match
the keys the app reads in `SleepGuard/RemoteConfig/RemoteConfigLoader.swift`.

## Resolution order

Every value resolves as: **debug override (DEBUG builds only) → last good remote fetch
(cached in UserDefaults) → baked-in default**. The app is fully functional offline and on
first launch before any fetch returns.

## Parameters

Console path: **Run → Remote Config → Create configuration**. Add the four parameters
below, then **Publish changes** (nothing applies until published).

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `feature_flags` | JSON | see below | Per-feature on/off switches |
| `tabs` | JSON | see below | Tab visibility + order |
| `minimum_version` | String | `0.0.0` | Hard-update threshold (block below this) |
| `recommended_version` | String | `0.0.0` | Soft-update threshold (prompt below this) |

### `feature_flags`

A single JSON object keyed by `FeatureFlag.rawValue`. Unknown keys are ignored; missing
keys fall back to their baked-in default (all `true`).

```json
{
  "snoringDetection": true,
  "sleepScore": true,
  "trends": true,
  "calendar": true,
  "soothingMelody": true,
  "healthSync": true,
  "watchApp": true,
  "lifestyleLogging": true,
  "sleepBriefing": true,
  "audioClips": true,
  "pdfReport": true,
  "enhancedSleepTracking": true,
  "sleepTalkingDetection": true,
  "notifications": true
}
```

### `tabs`

A JSON array. `tab` is an `AppTab.rawValue` (`statistics` | `media` | `settings`).
`isVisible` hides the tab when `false`; `order` sorts ascending. If the resolved set is
empty or hides everything, the app falls back to all tabs in canonical order.

```json
[
  { "tab": "statistics", "isVisible": true, "order": 0 },
  { "tab": "media",      "isVisible": true, "order": 1 },
  { "tab": "settings",   "isVisible": true, "order": 2 }
]
```

### `minimum_version` / `recommended_version`

Dot-separated numeric versions compared against the app's `CFBundleShortVersionString`.
Keep both at `0.0.0` so nobody is gated until you intentionally raise them.

- Running version `< minimum_version` → **hard** blocking update screen.
- Running version `< recommended_version` → **soft** dismissible prompt (shown once per
  recommended version).

## Day-to-day operations

- **Disable a feature:** set its value in `feature_flags` to `false` → Publish. Its UI
  disappears on next foreground (gated entry points only — see code map below).
- **Hide / reorder a tab:** edit `tabs` (`isVisible`, `order`) → Publish.
- **Force update:** raise `minimum_version` above the shipped build → Publish.
- **Recommend update:** raise only `recommended_version` → Publish.
- **Staged rollout / targeting:** add a **condition** on a parameter (app version, OS,
  % rollout) in the console.

## Fetch cadence

`RemoteConfigLoader` sets `minimumFetchInterval = 0` in DEBUG (changes apply on next
foreground) and `3600` (1h) in release. Refresh runs on launch and on every
`scenePhase == .active`.

## Local debug overrides

DEBUG builds expose **Settings → Debug Config** to flip flags and tab config locally
without the console. Overrides persist and take precedence until "Reset All Overrides".

## Feature-flag entry-point map

The flag values are always available via `AppConfig.shared.isEnabled(_:)`. UI gating
("flag off = hidden entirely") is wired at these entry points:

| Flag | Gated today | Entry point file(s) for remaining wiring |
|------|-------------|------------------------------------------|
| `sleepBriefing` | ✅ | `SleepGuard/MainTabView.swift` (`generateBriefingIfNeeded`) |
| `watchApp` | ✅ | `Packages/Settings/Sources/Views/SettingsView.swift` |
| `notifications` | ✅ | gates the soft-ask in `SleepGuard/StatisticsTab.swift` (`evaluateNotificationSoftAsk`) |
| `trends` | follow-up | `Packages/Statistics/Sources/Views/StatisticsLoadedView.swift` (Trends button) |
| `calendar` | follow-up | `StatisticsLoadedView.swift` + `StatisticsEmptyView.swift` (Calendar button) |
| `soothingMelody` | follow-up | `Packages/SleepSession/Sources/Views/SoothingMelodySheet.swift`, `SettingsRecordingSection.swift` |
| `healthSync` | follow-up | `SettingsRecordingSection.swift` (HealthKit rows) |
| `audioClips` | follow-up | `SettingsRecordingSection.swift`, `SessionDetailView.swift` |
| `pdfReport` | follow-up | `Packages/Recordings/Sources/Views/SessionDetailView.swift` (export action) |
| `enhancedSleepTracking` | follow-up | `SettingsRecordingSection.swift` |
| `sleepTalkingDetection` | follow-up | `SettingsRecordingSection.swift` |
| `snoringDetection` | follow-up | UI gate + optional detector kill-switch (decision pending) |
| `sleepScore` | follow-up | score display surfaces in `Statistics` |
| `lifestyleLogging` | follow-up | briefing survey chips in `MainTabView.swift` |
