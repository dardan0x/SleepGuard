# F4 — Recordings

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P1 |
| **Version** | V1.0 |
| **Blocked By** | F2 (needs recording data to display) |
| **Started** | 2026-05-06 |
| **Completed** | 2026-05-08 |
| **Feature Doc** | — |

## Summary

List past sleep sessions grouped by month. Tapping a session opens a detail view with a snoring timeline visualization and audio playback with event markers.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F4-T1 | RecordingsListView (empty + grouped list) | UI | Done | F2-T2 | Recordings | 2026-05-06 | 2026-05-06 |
| F4-T2 | RecordingRowView component | UI | Done | F4-T1 | Recordings | 2026-05-06 | 2026-05-06 |
| F4-T3 | SessionDetailView with timeline | UI | Done | F4-T1 | Recordings | 2026-05-06 | 2026-05-06 |
| F4-T4 | Audio playback with event markers | UI | Done | F4-T3 | Recordings | 2026-05-06 | 2026-05-06 |
| F4-T5 | Route registration | Wiring | Done | F4-T2, F4-T3 | App | 2026-05-06 | 2026-05-06 |
| F4-T6 | Snore-Only Recordings + Advanced Frequency Player | Feature | Done | F4-T4 | Recordings, AudioEngine, Env | 2026-05-09 | 2026-05-09 |

## Task Details

### F4-T1 — RecordingsListView (empty + grouped list)

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/feature-template.md |
| Status | Done |
| Started | 2026-05-06 |
| Completed | 2026-05-06 |

**Acceptance Criteria:**
- [x] `RecordingsListView` with `ViewState` enum: `.empty`, `.loaded(sessions:)`, `.error`
- [x] Fetches all `SleepSession` records via `@Query` sorted by date descending
- [x] Empty state shows "No recordings yet" placeholder
- [x] Loaded state groups sessions by month/year sections
- [x] Pull-to-refresh re-queries SwiftData
- [x] Builds with zero errors

**Prompt Used:**
Resume SleepGuard. Read AGENTS.md, docs/FeatureTracker.md, docs/SESSION_SUMMARY.md, docs/ProjectArchitecture.md, and the active feature tracker from docs/trackers/. Report state including which architecture doc the feature tracker references, then proceed with the next unblocked task following the workflow exactly.

**Notes:**
- `MonthSection` made `public` to satisfy Swift visibility rules for use in `public enum ViewState`
- `RecordingRowView` created inline as a minimal presentational row; F4-T2 will enhance it with full design, color-coded score indicator, and navigation
- Pull-to-refresh is UX-only since `@Query` auto-updates; no manual re-fetch needed

---

### F4-T2 — RecordingRowView component

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] `RecordingRowView`: presentational, receives `SleepSession` via init
- [x] Shows date, duration, sleep score, event count
- [x] Color-coded score indicator
- [x] Tap navigates to detail via `routerPath.navigate(to:)`
- [x] Builds with zero errors

**Prompt Used:**
Resume SleepGuard. Read AGENTS.md, docs/FeatureTracker.md, docs/SESSION_SUMMARY.md, docs/ProjectArchitecture.md, and the active feature tracker from docs/trackers/. Report state including which architecture doc the feature tracker references, then proceed with the next unblocked task following the workflow exactly.

**Notes:**
- Extracted inline row from `RecordingsListView.swift` into standalone `RecordingRowView.swift`
- Row layout: date (medium) + duration + event count on left; score badge (36pt colored circle) + chevron on right
- Score colors: green ≥80, orange 50-79, red <50 — matches `SleepScoreGauge` palette
- Tap uses `.contentShape(Rectangle())` + `.onTapGesture` for full-row tappability
- `.recordingDetail(id:)` route already existed in `RouterDestination` with placeholder in `AppRegistry`; navigation works end-to-end

---

### F4-T3 — SessionDetailView with timeline

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md, docs/architecture/navigation.md |
| Status | Done |
| Started | 2026-05-06 |
| Completed | 2026-05-06 |

**Acceptance Criteria:**
- [x] `SessionDetailView` pushed via `RouterDestination.sessionDetail(id:)`
- [x] Shows full session stats (score, duration, snoring %, dB stats)
- [x] Timeline visualization showing snoring events across session duration
- [x] Events colored by intensity (quiet/light/loud)
- [x] Builds with zero errors

**Notes:**
- Code exists in `Packages/Recordings/Sources/Recordings/SessionDetailView.swift`
- Includes `SleepScoreGauge`, 4× `StatCard` grid, `SnoringTimelineView`, `EventRow` list
- Loads `SleepSession` by UUID via `FetchDescriptor` with `ViewState` enum
- Tracker was not updated in previous session; corrected now

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_(decisions, issues, deviations)_

---

### F4-T4 — Audio playback with event markers

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-06 |
| Completed | 2026-05-06 |

**Acceptance Criteria:**
- [x] Audio file saving infrastructure (full session audio to disk)
- [x] Audio player controls (play/pause, scrub, duration)
- [x] Waveform or progress bar with snoring event markers overlaid
- [x] Markers are tappable to jump to that event timestamp
- [x] Builds with zero errors

**Prompt Used:**
Resume SleepGuard. Read AGENTS.md, docs/FeatureTracker.md, docs/SESSION_SUMMARY.md, docs/ProjectArchitecture.md, and the active feature tracker from docs/trackers/. Report state including which architecture doc the feature tracker references, then proceed with the next unblocked task following the workflow exactly — including Design Compliance: always reference designs/SleepGuard.pen before building or modifying any view.

**Notes:**
- Simplified approach: save full session audio as one file, seek to event timestamps during playback
- Per-event audio clips deferred to V2
- `AudioRecorder` writes `AVAudioPCMBuffer` to `AVAudioFile` during recording
- `SleepSession` gained `audioFileURL: String?` property
- `SessionManager` generates file URL in Documents directory, passes to `AudioRecorder`
- `SessionManager.discardCompletedSession()` deletes audio file when session is discarded
- `SessionDetailView` mini player: play/pause, progress bar with event marker dots, tap-to-scrub, time display
- Event row play buttons seek to event timestamp and start playback

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_(decisions, issues, deviations)_

---

### F4-T6 — Snore-Only Recordings + Advanced Frequency Player

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md, docs/architecture/state.md |
| Status | Done |
| Started | 2026-05-09 |
| Completed | 2026-05-09 |

**Acceptance Criteria:**
- [x] `stopSession()` is async and extracts per-event audio clips (±2s padding)
- [x] Full session audio file deleted after clip extraction to save storage
- [x] `SnoreEvent` stores `dominantFrequency`, `spectralCentroid`, `lowFreqRatio`
- [x] `AudioClipExtractor` uses `AVAssetExportSession` + `FFTAnalyzer` for post-processing
- [x] `ClipPlaybackController` manages sequential clip playback across all events
- [x] `WaveformGenerator` generates downsampled amplitude samples + averaged spectrum bars
- [x] `SessionDetailAdvancedPlayerView` shows waveform, 32-bar spectrum, stats grid, event navigator
- [x] `SessionDetailMiniPlayerView` has expand button (`waveform` SF Symbol)
- [x] `SessionDetailView` supports both legacy (full-file) and clip-based playback modes
- [x] Event row share uses pre-extracted clip directly (no on-demand export for clip sessions)
- [x] Builds with zero errors

**Prompt Used:**
Resume SleepGuard. Read AGENTS.md, docs/FeatureTracker.md, docs/SESSION_SUMMARY.md, docs/ProjectArchitecture.md, and the active feature tracker from docs/trackers/. Report state including which architecture doc the feature tracker references, then proceed with the next unblocked task following the workflow exactly.

**Notes:**
- Clip padding: 2 seconds before/after each event (matches existing export behavior)
- Legacy sessions with `audioFileURL != nil` fall back to full-file `AVAudioPlayer`
- New sessions store `audioFileURL = nil` on `SleepSession`; each `SnoreEvent` has its own `audioFileURL`
- Spectrum bars color-coded: green (low freq), amber (mid), red (high) — 0–1000 Hz range
- Stats panel shows: Duration, Peak dB, Dominant Freq, Spectral Centroid, Low-Freq Ratio
- `PlaybackSpectrumAnalyzer` file created but not wired into active UI path; static pre-computed spectrum used instead (simpler, no sync issues)
- **Session 34 refinements (2026-05-09)**:
  - Zero-padding clips: padding changed from 2.0s to 0.0s; clips contain ONLY snore audio
  - Event duration excludes debounce gap: `finalizeActiveEvent(includeGap: false)` trims duration to `lastSnoringSampleTime`
  - `AudioFileURLResolver`: stores only filenames, resolves against current Documents directory at runtime; fixes stale absolute paths after app relaunch
  - Waveform tap-to-seek in advanced player
  - Expand hint changed to pill button with "Details" text
  - Peak dB stat hidden from advanced player
  - `SessionStatsGrid`: extracted reusable 2×2 stat grid component in `DesignSystem`; used by `StatisticsStatsGrid` and `SessionDetailHeaderView`
  - Snore Time stat added to `SessionStatsGrid` with compact `Xhr Ym` / `Xm` format
  - `NightGroupRowView`: single-recording groups tap directly to detail; multi-recording groups expand

---

### F4-T5 — Route registration

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/navigation.md |
| Status | Done |
| Started | 2026-05-06 |
| Completed | 2026-05-06 |

**Acceptance Criteria:**
- [x] `.recordingDetail(id:)` mapped in `withAppRouter()` to real view
- [x] Navigation from list to detail works end-to-end
- [x] Back navigation works
- [x] Builds with zero errors

**Notes:**
- Reused `SessionDetailView` for `.recordingDetail(id:)` route since both show the same session detail content
- `RecordingRowView` already navigated to `.recordingDetail(id:)`; only `AppRegistry` needed updating

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_(decisions, issues, deviations)_

---

### Session 36 Refinements (2026-05-10)

- **Gap-free clips via burst composition**: `AudioClipExtractor` now uses `AVMutableComposition` to stitch individual burst segments into a single clip. Removes debounce gaps so clips contain only actual snoring audio. Legacy events without bursts fall back to single-range export.
- **Mini player dot alignment fix**: Event marker dots on `SessionDetailMiniPlayerView` are now positioned on the concatenated clips timeline (`accumulatedClipDuration / totalClipsDuration`) instead of the full session timeline. Dots now align with playback progress when jumping between events. Intensity colors restored per dot (quiet=grey, light=amber, loud=red).
- **Spectral accuracy**: Spectral analysis runs on gap-free composed clips, giving more accurate dominant frequency and spectral centroid readings.

### Session 28 Refinements (2026-05-07)

- **Night grouping with expandable cards**: Replaced flat `RecordingRowView` list with `NightGroupRowView` cards. Each card represents one night, showing date, total duration, total events, and average score. Tapping expands to reveal individual recording sub-rows with time ranges and individual scores. Tapping a sub-row navigates to that recording's detail.
- **New files**: `NightGroup.swift` (day-group model), `NightGroupRowView.swift` (expandable card UI)
- **Deleted**: `RecordingRowView.swift` (replaced by night grouping)
- **MonthSection updated**: `sessions: [SleepSession]` → `groups: [NightGroup]`

### Session 29 Refinements (2026-05-08)

- **Bulk delete (swipe + long-press)**: `RecordingsListView` rows now support `.swipeActions` (trailing Delete) and `.onLongPressGesture` on `NightGroupRowView` header. Both trigger an alert: "Remove X recordings from this night?" with "Remove" (destructive) and "Discard" (cancel). Deletes all `SleepSession` objects in the night group via `modelContext.delete`; events cascade-delete automatically.
- **NightGroupRowView**: Added `onDeleteRequest` closure parameter; long press `minimumDuration: 0.5` on header HStack alongside existing tap gesture

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

- **SessionDetailView performance fix**: Pre-computes `sortedEvents` and `isClipSession` during async `loadSession()` instead of sorting/faulting synchronously in `loadedBody`. `ViewState.loaded` now carries cached `sortedEvents: [SnoreEvent]` and `isClipSession: Bool`. Removed `diagnoseAudioFiles()` which iterated all events on main thread.
- **NightGroup stats caching**: `averageScore`, `totalDuration`, `totalEvents` moved from computed properties to stored constants computed once at `init`. Prevents repeated SwiftData relationship faulting + O(n) passes on every `NightGroupRowView.body` evaluation.
- **SnoringTimelineView sort optimization**: Added `isSorted` check before `sorted()` — events are appended chronologically during recording, so the sort is unnecessary for in-memory sessions.
- **AudioClipExtractor parallelization**: Extracted per-event logic into `extractSingleClip()`. `extractClips()` uses `withTaskGroup` (batch size 4) so exports + spectral analysis run concurrently. Each task creates its own `AVURLAsset` to avoid Sendable issues.

### Session 39 Refinements (2026-05-12)

- **Async legacy audio player setup**: `SessionDetailView.setupAudioPlayer(for:)` is now `async` and creates `AVAudioPlayer` inside `Task.detached(priority: .userInitiated)`. Prevents main-thread blocking when opening recordings with large full-session `.caf` files (legacy sessions pre-clip-extraction).
- **One-shot audio setup guard**: Added `@State private var didSetupAudio = false` in `SessionDetailView`. The `.task` in `loadedBody` checks `guard !didSetupAudio else { return }` before initializing playback. Prevents redundant `AVAudioPlayer` creation if SwiftUI re-evaluates the view.
- **Redundant sort removed**: `ClipPlaybackController.loadEvents()` no longer re-sorts events. `SessionDetailView.loadSession()` already passes chronologically sorted events; removing the `events.sorted()` avoids an unnecessary O(n log n) pass.

### Session 39 Refinements (continued, 2026-05-12)

- **Lazy legacy audio player**: `SessionDetailView` no longer creates `AVAudioPlayer` in `.task`. The player is only created when the user taps play. `toggleLegacyPlayback()` spawns an async task if `audioPlayer == nil`; `isLegacyPlayerLoading` prevents duplicate init.
- **Lazy clip audio player**: `ClipPlaybackController.loadEvents()` no longer calls `setupPlayerForCurrentEvent()`. The first `play()` tap creates the `AVAudioPlayer` for the current clip.
- **Removed per-event file checks**: `ClipPlaybackController.loadEvents()` no longer iterates all events calling `FileManager.fileExists(atPath:)`. It maps `event.snoreDuration` directly. Missing clips fail gracefully at playback time.
- **Canvas timeline**: `SnoringTimelineView` reimplemented with `Canvas` + `Path(roundedRect:)` instead of `GeometryReader` + `ForEach` over hundreds of `RoundedRectangle` views. Single render pass eliminates SwiftUI view-creation overhead for high-event-count sessions.
- **Sheet-based player + events UI**: `SessionDetailView` restructured to push audio I/O into bottom sheets. Inline `SessionDetailMiniPlayerView` is now a static fake bar (no live playback state). Tapping it presents `PlayerSheetView` (bottom sheet) which owns all audio state (`AVAudioPlayer`, `ClipPlaybackController`, visualization). Event list shows first 4 inline; "Show All" button presents `EventsSheetView` with horizontally-scrolling compact event cards. Sheets receive pre-computed `sortedEvents` and `isClipSession` from parent. No `.withEnvironments()` needed since sheets only use `Theme` and `dismiss` (standard SwiftUI environments).


### Session 57 Refinements (2026-05-24)

- **Duration format unification**: `NightGroupRowView` now uses shared `DurationFormatter.hoursAndMinutes` for both group total duration and per-session durations in expanded rows. Removed private `totalDurationString` and `durationString` wrappers.

### Session 41 Refinements (2026-05-14)

- **Event player timestamp**: `EventPlayerView.headerSection` now displays the event's start time (e.g., `2:30 pm` / `11:30 am`) before the "Snoring Event" label. Uses explicit 12-hour logic with lowercase `am`/`pm` for consistency.
- **Duration format fix**: `SessionSummaryView` and `BedsideClockView` now use `%d h %d min` / `%d min` format matching `NightGroupRowView`.

### Session 40 Refinements (2026-05-13)

- **Single-event playback from `EventsSheetView`**: Tapping an event card's Play button opens `PlayerSheetView` as a nested sheet (parent stays open) and passes only `[event]` as `sortedEvents`. This plays just that event's recording, showing its own waveform and duration — not the full concatenated sequence.
- **Single-event playback from `SessionDetailEventsView`**: Same fix applied to the inline detail page event list. `SessionDetailView`'s `.player` sheet case passes `sortedEvents: initialEvent.map { [$0] } ?? sortedEvents`.

### Session 66 Refinements — Enhanced Audio Playback (2026-05-28 → 2026-05-29)

- **`ClipPlaybackController` full refactor to `AVAudioEngine`**: Replaced `AVAudioPlayer` with `AVAudioPlayerNode` → `AVAudioUnitEQ` → `mainMixerNode`. Same public surface preserved (`play/pause/togglePlayback/seek/seekToOverall/seekInCurrentClip/nextEvent/previousEvent/cleanup`, `currentEvent/currentTime/totalClipsDuration/isPlaying`, etc.). Engine is lazy-started on first `play()`, format-detected per clip, and the chain is only re-connected when the file format actually differs (sample rate / channels / common format). Manual host-time math tracks `currentClipTime` instead of `playerTime(forNodeTime:)` queries — more stable across pause/resume.
- **Per-clip peak normalization (Enhanced Audio)**: On clip load, `currentGainDB(for:)` reads the file into a buffer, finds peak amplitude, and sets `eq.globalGain` to bring that peak to −3 dBFS, capped at the EQ's +24 dB ceiling. Loud clips get less boost; quiet clips get max boost — so every clip plays at similar perceived loudness without saturating.
- **Bandpass for noise reduction**: Two-band EQ — high-pass at 80 Hz (HVAC rumble + 50/60 Hz mains hum) and low-pass at 1.5 kHz (broadband mic hiss). Snore energy lives 100 Hz–1 kHz so the passband preserves it entirely. Bands bypass + `globalGain = 0` when enhancement is off.
- **`enhancedAudioEnabled` public toggle**: `didSet` re-applies bypass state and (if currently loaded) recomputes per-clip gain immediately. Wired to `UserPreferences.enhancedAudioPlayback` (new pref, defaults `true` on first access) so the choice persists across sessions.
- **Stale-completion guard**: monotonic `playbackToken` invalidates `scheduleSegment`'s completion when we stop, pause, seek, or load a new clip — so auto-advance can't fire twice or out-of-turn.
- **Audio cutting off early — `.dataConsumed` → `.dataPlayedBack` fix**: User reported clips ending milliseconds-to-seconds early. Root cause: the default completion type fires when data is read from the source (before the output buffer drains), and our `handlePlaybackFinished` immediately called `playerNode.stop()` (and possibly reconnected the chain for the next clip), flushing in-flight audio. Switched to `completionCallbackType: .dataPlayedBack` so cleanup happens after the tail has actually been heard.
- **Enhanced Audio toggle UI in `PlayerSheetView`**: Card under the player controls (same `theme.bgCard` / `theme.radiusCard` styling as the rest of the player), label + description on the left, SwiftUI `Toggle` on the right tinted with `theme.accent`. Only rendered in the clip-session branch (the legacy `AVAudioPlayer` path is unaffected by the toggle and showing it there would be misleading). Toggle binding writes both the controller (instant audio change) and `UserPreferences` (persistence).
- **Sheet detent bump 470 → 580**: With the toggle card added, the player + controls + toggle no longer fit in the old `.height(470)` detent. Bumped to `.height(580)`; also added `.large` as a second detent so users can drag for more breathing room without losing the default size.
- **Loading skeleton replaces "Audio unavailable" flash**: Two new state flags (`didFinishInitialLoad`, `hasLoadingTimedOut`). On first render — before `.task` has set anything up — the body now renders `loadingSkeleton` (waveform-shaped placeholder built from `theme.bgElevated` shapes + a circular `ProgressView` tinted with `theme.accent`) instead of falling through to `noAudioView`. `.task` flips `didFinishInitialLoad = true` after work completes; a 10 s safety task flips `hasLoadingTimedOut = true` so users aren't stuck on the skeleton forever if the legacy async export fails. The "Audio unavailable" view now only shows after we've actually given the load a chance.
- **Burst marker position math fix in `EventPlayerView`**: `position = burst.startOffset / totalDuration` was a latent multi-event bug — `burst.startOffset` is relative to the EVENT's start (not the session timeline), so dividing by `totalClipsDuration` (sum across all events) clustered all dots invisibly at the far-left edge for multi-event sessions. Fixed to `burst.startOffset / event.snoreDuration` with an `event.snoreDuration > 0` guard.
- **Burst markers: dots → capsule spans**: Replaced single-point `Circle` markers with `Capsule` shapes spanning each burst's `[startOffset, endOffset]` range. Each capsule shows both *when* a burst started AND *how long it lasted* — the previous dots threw `endOffset` away. Minimum width 6 pt so very short bursts stay visible. Loosened the bursts guard from `count > 1` to `!isEmpty`, so single-burst events also show their span instead of a placeholder dot at the start. Direct visual verification tool for the FP investigation work in F9: a wide capsule over tall waveform bars = real snore; a narrow capsule on flat waveform = suspicious orphan.
- **Legend: 2-color → 4-color intensity legend**: Was hardcoded `theme.scoreAmber` ("Light snore") + `theme.scoreRed` ("Loud snore"), which didn't include the Quiet color (gray) that most events actually use — leaving users staring at gray dots with no legend entry. Replaced with four chips (Quiet / Light / Loud / Epic) pulled via `theme.intensityColor(_:)` — the same source the burst markers use, so the legend can't drift out of sync if design tokens are tuned. Tightened chip spacing (14 / 4 vs 20 / 6) to fit all four across the card on any iPhone width. Reuses existing intensity-label strings; no new localization needed.
- **2 new localized strings** (added via `Strings.txt` + `generate-xcstrings.py`): `event.player.enhancedAudio.label` ("Enhanced Audio") and `event.player.enhancedAudio.description` ("Boosts volume and reduces background noise").
- **`UserPreferences.enhancedAudioPlayback`**: New `Bool` pref following the same `access`/`withMutation` pattern as other prefs. **Defaults to `true`** on first access (explicit `defaults.object(forKey:)` check) so new installs get the enhancement immediately without needing onboarding.
- **Files changed**: `Packages/Recordings/Sources/Helpers/ClipPlaybackController.swift` (~310 lines, full rewrite of internals), `Packages/Recordings/Sources/Views/PlayerSheetView.swift` (toggle UI + skeleton state + detent), `Packages/Recordings/Sources/Views/EventPlayerView.swift` (marker math + capsule spans + 4-color legend), `Packages/Env/Sources/Services/UserPreferences.swift` (new pref), `Packages/DesignSystem/Sources/Resources/Strings.txt` + regenerated `Localizable.xcstrings` + `Strings.swift` (2 new strings). All public API on `ClipPlaybackController` preserved; only `PlayerSheetView` consumes it.
