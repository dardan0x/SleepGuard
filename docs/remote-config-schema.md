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
| `feature_learn` | JSON | `{"visibility": false}` | Learn tab visibility, URL, and order |
| `sleep_score_config` | JSON | see below | Sleep score formula coefficients and caps |
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

### `feature_learn`

A JSON object (or plain boolean). When `visibility` is `true`, the Learn tab appears
at the configured `order` and loads `url` in a web view. `order` is optional and
defaults to `2` (after Media, before Settings). If `url` is missing, the tab shows
an empty state.

```json
{
  "visibility": true,
  "url": "https://example.com/learn",
  "order": 2
}
```

A plain boolean is also accepted:

```json
true
```

### `sleep_score_config`

A single JSON object containing every tunable value in the sleep score formula. Missing keys fall back to their baked-in default, so you only need to include the values you want to change.

```json
{
  "awakeExcessMultiplier": 1.0,
  "awakePctTarget": 8.0,
  "deepDeficitMultiplier": 0.6,
  "deepPctTarget": 15.0,
  "epicIntensityMultiplier": 40.0,
  "eventsPenaltyCap": 25,
  "eventsPerHourMultiplier": 2.5,
  "intensityPenaltyCap": 30,
  "lightIntensityMultiplier": 10.0,
  "longSleepMultiplier": 1.0,
  "longSleepPenaltyCap": 5,
  "longSleepThresholdHours": 9.0,
  "loudIntensityMultiplier": 20.0,
  "maxScore": 100,
  "minScore": 0,
  "remDeficitMultiplier": 0.4,
  "remPctTarget": 18.0,
  "shortSleepMinimumSessionHours": 3.0,
  "shortSleepMultiplier": 2.0,
  "shortSleepPenaltyCap": 8,
  "shortSleepThresholdHours": 6.0,
  "sleepTalkingFrequencyMultiplier": 0.8,
  "sleepTalkingPenaltyCap": 15,
  "sleepTalkingPercentageMultiplier": 0.35,
  "snoringMultiplier": 0.85,
  "snoringPenaltyCap": 75,
  "stagePenaltyCap": 15
}
```

**Common tweaks:**

| Goal | Change |
|------|--------|
| Make snoring punish more/less | Raise/lower `snoringMultiplier` |
| Cap how much snoring can deduct | Adjust `snoringPenaltyCap` |
| Make loud/epic snores count more | Raise `loudIntensityMultiplier` / `epicIntensityMultiplier` |
| Tighten/relax stage thresholds | Adjust `deepPctTarget`, `remPctTarget`, `awakePctTarget` |
| Adjust short/long sleep thresholds | Change `shortSleepThresholdHours` / `longSleepThresholdHours` |

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
- **Show / hide Learn tab:** set `feature_learn.visibility` and `feature_learn.url` → Publish.
- **Tune sleep score formula:** edit `sleep_score_config` → Publish. New sessions and sessions opened in detail use the new formula immediately. List/statistics views show the cached score until the session is re-saved or reopened.
- **Force update:** raise `minimum_version` above the shipped build → Publish.
- **Recommend update:** raise only `recommended_version` → Publish.
- **Staged rollout / targeting:** add a **condition** on a parameter (app version, OS,
  % rollout) in the console.

## Fetch cadence

`RemoteConfigLoader` sets `minimumFetchInterval = 0` in DEBUG (changes apply on next
foreground) and `3600` (1h) in release. Refresh runs on launch and on every
`scenePhase == .active`.

## Local debug overrides

DEBUG builds expose **Settings → Debug Config** to flip flags, tab config, and Learn
tab config locally without the console. Overrides persist and take precedence until
"Reset All Overrides".

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
