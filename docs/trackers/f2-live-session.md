# F2 — Live Session

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P0 |
| **Version** | V1.0 |
| **Blocked By** | — |
| **Started** | 2026-05-06 |
| **Completed** | 2026-05-06 |
| **Feature Doc** | — |

## Summary

Start/stop background recording with real-time snore detection. Displays a bedside clock UI during recording and a session summary sheet on stop. Uses amplitude + frequency thresholds to classify snoring as quiet/light/loud.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F2-T1 | AudioRecorder + SnoreDetector | Model/State | Done | — | AudioEngine | 2026-05-06 | 2026-05-06 |
| F2-T2 | SessionManager + sleep score algorithm | State | Done | F2-T1 | Env | 2026-05-06 | 2026-05-06 |
| F2-T3 | Pre-start recording screen | UI | Done | F2-T2 | SleepSession | 2026-05-06 | 2026-05-06 |
| F2-T4 | Bedside clock active recording UI | UI | Done | F2-T3 | SleepSession | 2026-05-06 | 2026-05-06 |
| F2-T5 | Session summary sheet | UI | Done | F2-T4 | SleepSession | 2026-05-06 | 2026-05-06 |
| F2-T6 | Route registration + wiring | Wiring | Done | F2-T3, F2-T5 | App | 2026-05-06 | 2026-05-06 |
| F2-T8 | Snore event debounce | State | Done | — | Env | 2026-05-09 | 2026-05-09 |
| F2-T9 | Soothing Melody Sheet + Picker | UI | Done | F2-T3 | SleepSession | 2026-05-14 | 2026-05-14 |
| F2-T10 | Soothing Melody Audio Playback | Audio | Done | F2-T9 | Env / AudioEngine | 2026-05-14 | 2026-05-14 |
| F2-T11 | Custom Melody Recording | Audio / UI | Done | F2-T10 | SleepSession / Env / Models | 2026-05-14 | 2026-05-14 |
| F2-T12 | Low Battery Force-Save | State / UI | Done | — | Env / SleepSession / Recordings / App | 2026-05-19 | 2026-05-19 |

## Task Details

### F2-T1 — AudioRecorder + SnoreDetector

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/state.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] `AudioRecorder`: `@MainActor @Observable` singleton wrapping `AVAudioEngine`
- [ ] Handles mic permission, start/stop, real-time audio level metering (dB)
- [ ] `AVAudioSession` configured: `.playAndRecord`, `.measurement`, `.defaultToSpeaker + .allowBluetooth`
- [ ] `SnoreDetector`: installs tap on audio engine input node, classifies buffers using amplitude thresholds
- [ ] Publishes snoring state: `.quiet`, `.light`, `.loud` or none
- [ ] Builds with zero errors

**Prompt Used:**
Resume SleepGuard development. Proceed with F2-T3 following workflow exactly.

**Notes:**
- AudioRecorder accessed via `.shared` directly in view (consistent with SessionManager pattern) rather than through @Environment. This avoids modifying AppRegistry dependency graph for a single permission bool.
- Transition to active recording is handled by `SleepSessionView` observing `sessionManager.isRecording`; active state shows a placeholder until F2-T4 builds the bedside clock.

---

### F2-T2 — SessionManager + sleep score algorithm

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/state.md, docs/architecture/dependencies.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] `SessionManager`: `@MainActor @Observable` singleton in Env
- [ ] Coordinates AudioRecorder + SnoreDetector lifecycle
- [ ] Creates `SleepSession` on start, appends `SnoreEvent`s during recording, finalizes on stop
- [ ] Computes sleep score 0-100 (weighted: snoring %, intensity distribution, events/hour)
- [ ] Builds with zero errors

**Prompt Used:**
Proceed with F2-T4 (bedside clock active recording UI)

**Notes:**
- View-driven audio processing: `.task` polls at 20Hz (50ms) to call `sessionManager.processAudioLevel(db:)` and update the clock display. Task auto-cancels when view is removed (e.g., when `isRecording` becomes false).
- Snoring indicator uses both a text label + colored dot at top, and a subtle full-screen color glow (6% opacity) that animates with state changes.
- Audio level bar maps dB from -60..-20 to 0..1 fill fraction. Color matches snoring state.
- Clock uses thin rounded font at 88pt with 80% opacity label color for nighttime eye comfort.
- Stop button is a 64pt circle with red fill. Tapping it calls `sessionManager.stopSession()`; UX transition to summary sheet will be handled in F2-T5.

---

### F2-T3 — Pre-start recording screen

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-06 |
| Completed | 2026-05-06 |

**Acceptance Criteria:**
- [x] Idle recording state UI with "Start Recording" CTA
- [x] Shows mic permission status indicator
- [x] Displays brief instructions / tips
- [x] Tapping CTA starts recording and transitions to bedside clock
- [x] Builds with zero errors

**Prompt Used:**
Resume SleepGuard. Read AGENTS.md, docs/VIBE_CODING_WORKFLOW.md, docs/FeatureTracker.md, docs/SESSION_SUMMARY.md, docs/ProjectArchitecture.md, and the active feature tracker from docs/trackers/. Report state including which architecture doc the feature tracker references, then proceed with the next unblocked task following the workflow exactly.

**Notes:**
- `SheetDestination.sessionSummary` simplified from `sessionSummary(sessionID:)` to `sessionSummary` (no payload) because the completed session is read from `SessionManager.completedSession`.
- `SleepSessionView` shows `Color.clear` when `completedSession != nil` to prevent a flash of `RecordingPrestartView` during the sheet swap from `.liveSession` to `.sessionSummary`.
- SwiftData save explicitly inserts both the `SleepSession` and all `SnoreEvent` children to ensure persistence.
- Score ring uses `trim(from:to:)` with a colored stroke; score color/label maps 80+ green, 50-79 orange, <50 red.
- **Hard gates added (Session 46+):** Both `RecordingPrestartView` and `RecordingCountdownView` now require microphone permission and iPhone charging before starting a session:
  - **Microphone**: If `AudioRecorder.hasPermission` is false, calls `requestPermission()`; if denied, shows alert with "Open Settings" button linking to app Settings.
  - **Charging**: Checks `UIDevice.current.batteryState`; if not `.charging` or `.full`, shows alert with "Start Anyway" override option and recommendation to plug in for the nightstand experience.
- **minSnoreDuration removed from Settings (Session 46+):** The minSnoreDuration stepper was removed from Settings. SessionManager now hardcodes `2.0` seconds as the minimum event duration filter, which is calibrated to exclude brief breaths and transients without user tuning.

---

### F2-T4 — Bedside clock active recording UI

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-06 |
| Completed | 2026-05-06 |

**Acceptance Criteria:**
- [x] Full-screen bedside clock with large time display
- [x] Real-time audio level indicator (dB bar or wave)
- [x] Snoring indicator: color changes by intensity (quiet/light/loud)
- [x] Recording duration timer
- [x] Stop button prominently displayed
- [x] Dimmed/eye-friendly UI for nighttime use
- [x] Builds with zero errors

**Prompt Used:**
Resume SleepGuard. Read AGENTS.md, docs/VIBE_CODING_WORKFLOW.md, docs/FeatureTracker.md, docs/SESSION_SUMMARY.md, docs/ProjectArchitecture.md, and the active feature tracker from docs/trackers/. Report state including which architecture doc the feature tracker references, then proceed with the next unblocked task following the workflow exactly.

**Notes:**
- `SheetDestination.sessionSummary` simplified from `sessionSummary(sessionID:)` to `sessionSummary` (no payload) because the completed session is read from `SessionManager.completedSession`.
- `SleepSessionView` shows `Color.clear` when `completedSession != nil` to prevent a flash of `RecordingPrestartView` during the sheet swap from `.liveSession` to `.sessionSummary`.
- SwiftData save explicitly inserts both the `SleepSession` and all `SnoreEvent` children to ensure persistence.
- Score ring uses `trim(from:to:)` with a colored stroke; score color/label maps 80+ green, 50-79 orange, <50 red.

---

### F2-T5 — Session summary sheet

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md, docs/architecture/navigation.md |
| Status | Done |
| Started | 2026-05-06 |
| Completed | 2026-05-06 |

**Acceptance Criteria:**
- [x] Sheet presented on stop with `.withEnvironments()`
- [x] Shows sleep score, duration, snoring %, events count, avg/peak dB
- [x] "Save Session" button persists to SwiftData
- [x] "Discard" button deletes without saving
- [x] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_(decisions, issues, deviations)_

---

### F2-T6 — Route registration + wiring

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/navigation.md |
| Status | Done |
| Started | 2026-05-06 |
| Completed | 2026-05-06 |

**Acceptance Criteria:**
- [x] Routes for pre-start, bedside clock, and summary sheet registered
- [x] Navigation from Statistics "Start Recording" CTA works
- [x] From onboarding "Start Recording" routes to pre-start screen
- [x] Builds with zero errors

**Prompt Used:**
Resume SleepGuard. Read AGENTS.md, docs/FeatureTracker.md, docs/SESSION_SUMMARY.md, docs/ProjectArchitecture.md, and the active feature tracker from docs/trackers/. Report state including which architecture doc the feature tracker references, then proceed with the next unblocked task following the workflow exactly.

**Notes:**
- `StatisticsDashboardView` now has a "Start Recording" CTA that presents `.liveSession` sheet via `routerPath.presentedSheet`
- `StatisticsTab` sheet includes `onDismiss` that clears `sessionManager.completedSession`, allowing users to start multiple recording sessions in one app launch
- Onboarding routing already worked via `presentRecordingAfterOnboarding` flag; verified unchanged
- Pre-start (`RecordingPrestartView`) and bedside clock (`BedsideClockView`) are both presented through the `.liveSession` sheet destination; summary through `.sessionSummary`

---

### F2-T8 — Snore event debounce

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/state.md |
| Status | Done |
| Started | 2026-05-09 |
| Completed | 2026-05-09 |

**Acceptance Criteria:**
- [x] Consecutive snore detections separated by brief breaths (< 3s) merge into a single event
- [x] Event intensity upgrades to peak observed level during merged episode
- [x] Real-time event count no longer floods with hundreds of micro-events
- [x] Builds with zero errors

**Prompt Used:**
Add a 3-second debounce threshold between snore events so brief breaths don't split one snoring episode into multiple events.

**Notes:**
- Added `eventGapThreshold: TimeInterval = 3.0` to `SessionManager`
- Tracks `lastSnoringSampleTime` and only finalizes event after 3s of silence
- Added `activeEventIntensity` to track peak intensity; `intensityRank` helper upgrades quiet→light→loud
- `currentSnoringState` still updates immediately for UI responsiveness; only event persistence is debounced

---

### Session 31 Refinements (2026-05-08)

- **Delayed Recording Start (replaces Smart Alarm)**: Removed Smart Alarm entirely. Added countdown-based delayed recording start with options: Off / 15m / 30m / 45m / 1h.
- **RecordingDelayManager**: New `@Observable` singleton with `Timer` on `RunLoop.main` `.common` mode. Tracks `targetDate` for background resilience. Schedules local notification fallback. Posts `.recordingDelayDidComplete` on completion.
- **RecordingCountdownView**: Full-screen countdown with moon icon, large timer "Recording starts in XX:XX", Cancel button, and Start Now button. Auto-starts recording when timer hits zero.
- **RecordingPrestartView Redesign**: Removed alarm toggle/time picker. Added horizontal delay picker with accent selected state. Helper text: "Use this if you need time to fall asleep before recording begins."
- **SettingsView**: Removed Smart Alarm section. Added "Start delay" row in Recording section with confirmation dialog.
- **UserPreferences**: Replaced `alarmEnabled`, `alarmHour`, `alarmMinute`, `alarmWindowMinutes` with `recordingDelayMinutes`.
- **BedsideClockView**: Removed alarm badge and alarm overlay references.

---

### Session 30 Refinements (2026-05-08)

- **SessionSummaryView Save Button**: Replaced blue accent button with dark pill (`#1E1D1E` fill + white gradient stroke + two-layer behind glow) matching `RecordingActionButton` design pattern.
- **10-Minute Minimum Validation**: `saveSession()` blocks saves under 600 seconds and shows alert: "Session Too Short" / "To generate meaningful sleep analysis, recordings must be at least 10 minutes long."
- **Custom Tab Bar for iOS < 26**: Design-compliant floating pill (`bgCard`, `border` stroke, `cornerRadius: 36`) with accent selected state; hides during recording.
- **Hide Tab Bar During Recording**: iOS < 26 custom tab bar removed from hierarchy; iOS 26+ uses `.toolbar(.hidden, for: .tabBar)` per tab content.
- **Background Recording (Lock Screen)**: Audio interruption handling with auto-resume; `AVAudioEngineConfigurationChange` observer restarts engine on route changes; `notifyOthersOnDeactivation` on stop.

---

### Session 37 Refinements (2026-05-12)

- **Sleep score formula fix**: Previous formula capped snoring penalty at 30 pts, giving 66+ for 93% snoring sessions. New formula:
  - `snoringPenalty = min(snoring% × 0.7, 70)` (was 0.5, cap 30)
  - `eventsPenalty = min(events/hour × 2, 20)` (was cap 30)
  - `intensityPenalty = min(lightRatio × 10 + loudRatio × 20, 20)` (new — weighted by event duration)
  - `score = max(0, 100 - snoringPenalty - eventsPenalty - intensityPenalty)`
  - A 93% snoring session now scores ~31 instead of 66.
- **Sleep score computed on demand**: Removed `sleepScore` from SwiftData stored properties. `SleepSession.sleepScore` is now a computed property so formula changes retroactively apply to all historical sessions without data migration.
- **Derived session stats computed on demand**: Removed `totalDuration`, `snoringDuration`, `snoringPercentage`, `eventsCount`, and `eventsPerHour` from SwiftData stored properties. All are now computed from raw data (`startDate`, `endDate`, `events` relationship). Only `averageDB` and `peakDB` remain stored because they derive from per-sample audio data not persisted in SwiftData.
- **SnoreEvent.snoreDuration computed on demand**: Removed from SwiftData stored properties. Now computed from `bursts` so gap-detection logic changes retroactively affect event durations.

### Session 36 Refinements (2026-05-10)

- **Raw data preservation**: `SleepSession.rawAudioFileURL` preserves full session `.caf` for future re-processing. `SleepSession.rawLogFileURL` stores a JSON classification log (every 50ms sample with dB, spectral score, snore confidence, state). `SessionRawLogWriter` actor buffers in memory and flushes atomically at session stop.
- **Per-burst tracking**: `SnoreBurst` struct tracks continuous snoring segments within each event. `SnoreEvent.bursts` stores burst boundaries. `SessionManager` tracks `activeBurstStart` and `completedBursts` during recording.
- **True snoring duration**: `finalizeActiveEvent()` computes `snoreDuration` as `sum(burst.duration)` instead of `lastSnoreTime - eventStart`. This excludes debounce gaps from snoring time, making stats and sleep scores more accurate.
- **Background-safe processing**: `processAudioLevel` loop moved from `BedsideClockView` `.task` into `SessionManager` own `Task` so detection continues when app backgrounds.
- **Orphaned file cleanup**: `deleteSessionFiles()` helper removes event clips, legacy full session, raw audio archive, and raw classification log. Wired into `RecordingsListView`, `SessionDetailView`, and `SettingsView` deletion paths.

### Session 32 Refinements (2026-05-09)

- **Snore Event Debounce (F2-T8)**: Added 3-second gap threshold between snore events in `SessionManager`. Prevents brief breaths from splitting one continuous snoring episode into dozens of micro-events. Event intensity upgrades to peak observed level during the merged episode.

---

### Session 28 Refinements (2026-05-07)

- **F2-T2 — SessionManager eventsCount bug fix**: Changed `eventsCount` from computed property to stored `Int` because `@Observable` does not reliably propagate deep mutations on SwiftData `@Model` relationship arrays. Explicitly updated in `finalizeActiveEvent`, `processAudioLevel`, `startSession`, and `stopSession`.
- **F2-T4 — BedsideClockView UI cleanup**: Removed dB display and snore confidence from active recording UI. Added debug logging (`#if DEBUG`) for classification pipeline diagnostics.

---

### F2-T9 — Soothing Melody Sheet + Picker

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-14 |
| Completed | 2026-05-14 |

**Acceptance Criteria:**
- [x] RecordingPrestartView shows clickable "Soothing melody" actionRow with trailing value and chevron
- [x] Tapping row opens SoothingMelodySheet matching design node `zvwP5`
- [x] Sheet has native wheel picker for duration: Never, Always, 5s, 15s, 30s, 60s
- [x] Sheet has song row (RJhGr) showing selected melody; tapping it opens MelodyPickerSheet
- [x] MelodyPickerSheet matches design node `p0pnlC` with melody 9–17 list, accent highlight, checkmark
- [x] Save commits to UserPreferences; Cancel discards draft changes
- [x] TipsSection has gradient glow + stroke matching RecordingActionButton style
- [x] Builds with zero errors

**Prompt Used:**
Build a soothing melody sheet from the design file (node zvwP5) with a native wheel picker for duration and a nested melody picker sheet (node p0pnlC). Make the actionRow on RecordingPrestartView clickable and dynamic. Also add gradient to tipsSection.

**Notes:**
- `Melody` model added to `Models` package; `UserPreferences` extended with `soothingMelodyMode` and `selectedMelodyID`
- Both sheets use draft-state pattern (local `@State` that only commits on Save)
- Extracted reusable `SheetHandle` and `SheetNavHeader` components
- Wheel picker uses SwiftUI `Picker` + `.pickerStyle(.wheel)` inside `bgCard` container
- Nav back buttons say "Search" per design; may need to change to "Back" if confirmed by user

---

### F2-T10 — Soothing Melody Audio Playback

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/concurrency.md |
| Status | Done |
| Started | 2026-05-14 |
| Completed | 2026-05-14 |

**Acceptance Criteria:**
- [x] `sounds/` folder with 11 MP3 files added as bundle resources in the app target
- [x] `Melody` model updated with real `filename` + human-readable `displayName` mapping (11 melodies)
- [x] `SoothingMelodyPlayer` created in `Env` package — `@MainActor @Observable` singleton with `AVAudioPlayer`
- [x] `playIfNeeded()` triggered from `SessionManager` when a new snore event starts (3 consecutive samples)
- [x] Respects `soothingMelodyMode`: Never (skip), Always (loop until manual stop), timed modes (auto-stop timer)
- [x] Playback volume fixed at 0.6 to reduce mic feedback; snore detection continues uninterrupted
- [x] `stop()` called on session end (`stopSession`, `stopAndDiscardSession`) to prevent audio leaking
- [x] `BedsideClockView` shows compact overlay card when `isPlaying` — pulsing music icon, melody name, Stop button
- [x] `MelodyPickerSheet` shows real sound names instead of dummy "Melody N" labels
- [x] `SoothingMelodyPlayer` injected into app environment via `AppRegistry` + `SleepGuardApp`
- [x] Builds with zero errors
- [x] Manual stop allows re-triggering on future snore events
- [x] "Mute for session" button disables all further melody playback during current recording session
- [x] Session mute resets automatically when a new recording starts

**Prompt Used:**
Wire the Soothing Melody feature to real MP3 files. When snoring is detected during recording, play the selected sound for the configured duration. Show a compact overlay on BedsideClockView with a Stop button. Keep snore detection running during playback.

**Notes:**
- Ruby `xcodeproj` gem used to add `sounds/` folder reference to the Xcode project (pbxproj modification)
- `UserPreferences.selectedMelodyID` default changed from 12 → 6 (first valid ID in new 1–11 mapping)
- Re-trigger guard: `playIfNeeded()` returns early if `isPlaying` to prevent audio stuttering on repeated snore detections
- `AVAudioPlayerDelegate` calls `stop()` on natural playback end for non-looping modes
- Overlay uses `.transition(.move(edge: .top).combined(with: .opacity))` for smooth appearance
- Fixed playback: added `overrideOutputAudioPort(.speaker)` because `.measurement` session mode was routing to earpiece, and added `subdirectory: "sounds"` fallback for bundle path resolution

---

### F2-T11 — Custom Melody Recording

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-14 |
| Completed | 2026-05-14 |

**Acceptance Criteria:**
- [x] Pinned "Record yours" row at top of `MelodyPickerSheet` with mic icon and accent styling
- [x] Tapping "Record yours" opens `RecordCustomMelodySheet` for in-app recording
- [x] Recording sheet has record/stop button, timer (0.1s precision), and 10-second auto-stop
- [x] After recording: playback button, "Re-record" (discard + restart), and "Save" buttons
- [x] Saved recordings appear in the melody list above bundled sounds
- [x] Custom melodies are persisted to `Documents/CustomMelodies/` with metadata in UserDefaults
- [x] Custom melodies can be deleted (trash button on row)
- [x] Custom melodies can be previewed (3-second tap-to-play)
- [x] Custom melodies work with snore-triggered playback via `SoothingMelodyPlayer`
- [x] `SheetHandle` and `SheetNavHeader` extracted to `DesignSystem` for reuse
- [x] Helper text added under "Soothing melody" actionRow in `RecordingPrestartView`
- [x] Builds with zero errors

**Prompt Used:**
Add a "Record yours" row at the top of MelodyPickerSheet that opens a recording view. Allow users to record up to 10 seconds, playback before saving, discard/re-record, and save. Saved custom melodies should appear in the list and work with snore-triggered playback.

**Notes:**
- `CustomMelodyStorage` (Env) manages custom melody metadata + file I/O
- Custom melody IDs start at 100 to avoid conflicts with bundled IDs (1–11)
- `AVAudioRecorder` used for custom recording (simpler than `AVAudioEngine`)
- `Melody` model gained `isCustom: Bool` flag
- Extracted `SheetHandle` and `SheetNavHeader` from `SoothingMelodySheet.swift` to `DesignSystem/SheetHeader.swift`

## Update Rules (for the AI)

After completing a task in this feature:
1. Check off acceptance criteria boxes
2. Fill Started/Completed dates in task table and detail section
3. Set task Status to **Done**
4. Fill "Prompt Used" with the prompt summary
5. Add any notes about decisions or deviations
6. If ALL tasks are Done → set feature Status to **Done**, fill Completed date
7. Also update the index file (docs/FeatureTracker.md)


### Session 38 Refinements (2026-05-12)

- **Stop button short-session alert bug**: `BedsideClockView` StopRecordingButton checked `session.totalDuration < minimumSaveDuration`, but `totalDuration` is computed from `endDate` which is `nil` during recording → always 0. Fixed to use `currentTime.timeIntervalSince(session.startDate)` (live elapsed time).
- **SleepScoreGauge animation**: Added `@State animatedProgress` starting at 0, animated to `CGFloat(score) / 100.0` via `.onAppear`. Uses `.animation(.easeOut(duration: 0.8), value: animatedProgress)` + `.onChange(of: score)` for updates. Render-server driven, no main-thread load.
- **Computed property performance**: `SleepSession.sleepScore` refactored to single-pass over events (previously did 3+ passes). Cuts CPU work when `StatisticsDashboardView` or `NightGroup` averages scores across multiple recordings.
- **Clip extraction parallelization**: `AudioClipExtractor.extractClips()` now uses `TaskGroup` with batch size 4 instead of sequential `for` loop. Reduces post-recording "Processing session…" overlay time for long sessions with many events.

### Session 48 Refinements (2026-05-17)

- **Compact-height adaptive layout**: `RecordingPrestartView` now uses `isCompactHeight` (`UIScreen.main.bounds.height <= 874`) to scale down `iconSection` (100 → 80 pts, font 44 → 36 pts) and headline title (28 → 24 pts) on smaller devices (iPhone 16e, 17 Pro, and smaller). Pro Max screens retain the original larger sizing.

### Session 39 Refinements (2026-05-12)

- **False-positive detection fix**: The snore detector was creating massive false positives (breathing, bed creaking, traffic, talking) due to a pure dB fallback with no frequency discrimination. Fixed in `SnoreDetector`, `SoundAnalysisDetector`, and `SessionManager`:
  - `classifyWithThresholds()` removed from fallback chain
  - Spectral threshold raised from 0.3 → 0.6 with -35 dB minimum floor
  - `"breathing"` removed from `SoundAnalysisDetector.snoreIdentifiers`
  - `SessionManager` requires 3 consecutive snoring samples (≈150 ms) before starting an event
  - `finalizeActiveEvent()` now uses `UserPreferences.minSnoreDuration` (default 2.0 s) instead of hardcoded 0.5 s
- **UI hang root cause identified**: The hang was caused by thousands of false-positive events per session, not the audio player. Sorting/iterating thousands of events in `loadSession()`, `SnoringTimelineView`, and `sleepScore` blocked the main thread.

### Session 49 Refinements (2026-05-18)

- **Gap tracking reliability**: Removed the fragile notification-based gap tracking (`.recordingDidPause` / `.recordingDidResume`) between `AudioRecorder` and `SessionManager`. Replaced with a single `.soothingMelodyDidStop` observer in `SessionManager` that logs the gap directly. This catches timer stops, manual stops, non-snore stops, and session-end stops uniformly — no gaps are lost when `melodyStartTime` is overwritten.
- **Event discard during mic pause fixed**: Added `!soothingMelodyPlayer.isPlaying` guard to the event-finalize condition in `processAudioLevel()`. Prevents stale frozen `currentDB` from finalizing (and discarding) the active event while the mic is paused. When the mic resumes, `handleMelodyDidStop()` extends `lastSnoringSampleTime` to the resume time so `eventSpan` includes the gap and passes the minimum-duration check.
- **Model lightness**: Reverted `SleepSession.gapsDuration` from stored (`TimeInterval = 0`) back to computed (`recordingGaps?.reduce(0) { $0 + $1.duration } ?? 0`). `SleepSession` now only stores raw data (`recordingGaps` array); all derived stats are computed on demand. Changing formulas in the future requires zero migrations.
- **Force-finalized event minimum**: `finalizeActiveEvent(skipMinDuration: true)` now uses 0.5s floor instead of bypassing the check entirely. Prevents 0-second events from being saved while still allowing short melody-triggered events.
- **MelodyGapsBannerView pluralization**: `durationString` now returns "over 1 min" / "over 2 mins" / "over 1 h 30 mins" with proper singular/plural localization keys (`time.minute.singular`, `time.minute.plural`, `time.hour.singular`, `time.hour.plural`, `common.over`).

### F2-T12 — Low Battery Force-Save

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/state.md |
| Status | Done |
| Started | 2026-05-19 |
| Completed | 2026-05-19 |

**Acceptance Criteria:**
- [x] `SessionManager` monitors battery level every 30s during recording (via `processingTask` counter)
- [x] At ≤2% battery, session is force-stopped and auto-saved to SwiftData + HealthKit
- [x] User sees an explanatory banner in `SessionSummaryView` and `SessionDetailView`
- [x] No changes to `SleepSession` SwiftData model
- [x] Banner is styled consistently with `MelodyGapsBannerView`
- [x] UserDefaults key cleaned up when session is deleted

**Prompt Used:**
Force-save session when battery hits 2% to prevent data loss. Show a banner in session stats/summary explaining the force-save. Avoid polluting SleepSession model if possible; use MelodyGapsBannerView as inspiration.

**Notes:**
- Battery monitoring lives in `SessionManager.processingTask` (survives background audio)
- `forceSaveReason` is a transient `String?` on `SessionManager`; never persisted to model
- `StatisticsTab` intercepts `completedSession` change and auto-saves when `forceSaveReason != nil`
- `LowBatteryBannerView` reads `UserDefaults` internally (key: `session_termination_reason_<sessionID>`)
- Force-saved sessions bypass the 10-minute minimum duration check
- Simulator skips battery monitoring (`#if targetEnvironment(simulator)`)
