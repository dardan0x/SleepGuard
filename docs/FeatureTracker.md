# SnoreGuard — Feature Tracker

> Auto-updated by the AI after every task. This is the local source of truth.

Last updated: 2026-05-26 (Session 60)

---

## Dashboard

| Metric | Count |
|--------|-------|
| Features (V1) | 6 |
| Done | 6 |
| In Progress | 0 |
| Backlog | 0 |
| Blocked | 0 |
| — | — |
| Features (V1.1) | 3 |
| Done | 3 |
| In Progress | 0 |
| Backlog | 0 |
| — | — |
| Features (V2) | 4 |
| Done | 4 |
| In Progress | 0 |
| Backlog | 0 |
| Blocked | 0 |
| — | — |
| Features (V3) | 1 |
| Done | 0 |
| In Progress | 1 |
| Backlog | 3 |
| Blocked | 0 |
| — | — |
| Total Tasks | 62 |
| Tasks Done | 57 |
| Tasks In Progress | 0 |
| Tasks Blocked | 0 |
| Tasks Backlog | 5 |
| — | — |
| **Progress** | **92%** |

## Features

| ID | Feature | Priority | Status | Tasks | Progress | File |
|----|---------|----------|--------|-------|----------|------|
| F1 | Onboarding | P0 | Done | 5/5 | ██████████ 100% | [tracker](trackers/f1-onboarding.md) |
| F2 | Live Session | P0 | Done | 7/7 | ██████████ 100% | [tracker](trackers/f2-live-session.md) |
| F3 | Statistics Dashboard | P1 | Done | 3/3 | ██████████ 100% | [tracker](trackers/f3-statistics.md) |
| F4 | Recordings | P1 | Done | 6/6 + polish | ██████████ 100% | [tracker](trackers/f4-recordings.md) |
| F5 | Trends | P1 | Done | 2/2 | ██████████ 100% | [tracker](trackers/f5-trends.md) |
| F6 | Settings | P2 | Done | 3/3 | ██████████ 100% | [tracker](trackers/f6-settings.md) |
| F7 | Audio Clip Export | P1 | Done | 2/2 | ██████████ 100% | [tracker](trackers/f7-audio-clip-export.md) |
| F8 | PDF Sleep Report | P1 | Done | 2/2 | ██████████ 100% | [tracker](trackers/f8-pdf-sleep-report.md) |
| F9 | Enhanced Detection | P2 | Done | 2/2 | ██████████ 100% | [tracker](trackers/f9-enhanced-detection.md) |
| F10 | Smart Alarm | P1 | Done | 3/3 | ██████████ 100% | [tracker](trackers/f10-smart-alarm.md) |
| F11 | Apple Watch | P2 | Done | 4/4 | ██████████ 100% | [tracker](trackers/f11-apple-watch.md) |
| F12 | HealthKit | P1 | Done | 3/3 | ██████████ 100% | [tracker](trackers/f12-healthkit.md) |
| F13 | CloudKit Sync | P2 | Backlog | 0/3 | ░░░░░░░░░░ 0% | [tracker](trackers/f13-cloudkit-sync.md) |
| F14 | SleepGuard Rebrand & Multi-Sound | P0 | In Progress | 17/20 | ████████░░ 85% | [tracker](trackers/f14-sleepguard-rebrand.md) |

## Activity Log

_Most recent first. The AI appends here after every task._

| Date | Task | Action | Notes |
|------|------|--------|-------|
| 2026-05-26 | P4-T2 Stage correlation | Completed | `SessionDetailView.loadSession()` auto-fetches sleep stages when `sleepStageSegments == nil`, stores `[]` for no-data to avoid re-query, persists via SwiftData; build succeeds |
| 2026-05-26 | P4-T1 HealthKit read sleep stages | Completed | `fetchSleepStages(for:)` queries HK sleep analysis samples, maps to `SleepStageSegment`; `mapSleepStage` maps core/deep/REM/awake; skips legacy/in-bed/unspecified; build succeeds |
| 2026-05-26 | P3-T6 Build & verify | Completed | Clean build (zero errors); pre-existing asset warnings only; Phase 3 UI verified |
| 2026-05-26 | P3-T5 Player labels | Completed | `PlayerSheetView` navigation title changes based on event category: snoring = "Snoring Player", sleep talking = "Sleep Talking Player", noise = "Noise Player"; localized 2 new title strings; build succeeds |
| 2026-05-26 | P3-T4 Stats grid supplement | Completed | Optional disturbance row in `SessionDetailHeaderView`: full-width `StatCard` below the 2×2 grid, shows non-snoring event count, hidden for snoring-only sessions; localized `session.disturbances`; build succeeds |
| 2026-05-26 | P3-T3 Timeline multi-color | Completed | `SnoringTimelineView` renders events by category: snoring retains intensity colors, sleep talking = purple, noise/coughing/other = orange; `eventColor(_:)` helper; build succeeds |
| 2026-05-26 | P3-T2 EventRow icons | Completed | Category-based icons in `EventRow`: snoring retains intensity dot, sleep talking shows purple `bubble.left.fill`, noise shows orange `waveform`; `Theme` gained `sleepTalkingColor` and `noiseColor` for P3-T3 reuse; build succeeds |
| 2026-05-26 | P3-T1 Category filter | Completed | Segmented picker (`All | Snoring | Sleep Talking | Noise`) in `SessionDetailView`; dynamic show/hide when session has multiple categories; filter wired to events list, player sheet, and events sheet; localized 4 filter strings; build succeeds |
| 2026-05-26 | P2-T5 Build & verify | Completed | Clean build (zero errors); code review confirms snoring behavior unchanged when toggle off; speech priority finalization correct; no regressions; pre-existing asset warnings only |
| 2026-05-26 | P2-T4 Settings toggle | Completed | "Detect Sleep Talking" toggle in SettingsRecordingSection; localized `settings.detectSleepTalking` string; `Strings.swift` regenerated; toggle wired to `UserPreferences.detectSleepTalking`; build succeeds |
| 2026-05-26 | P2-T3 Event creation for sleep talking | Completed | Parallel speech event tracking in SessionManager; `finalizeActiveSpeechEvent()` creates `.sleepTalking` events; 3-sample consecutive gate; snoring priority finalizes speech immediately; `detectSleepTalking` pref (default false); build succeeds |
| 2026-05-26 | P2-T2 Parallel detection wiring | Completed | SpeechDetector wired into SessionManager processing loop; `currentSpeechDetected` exposed; snoring priority preserved; debug prints include speechConfidence; build succeeds |
| 2026-05-25 | SleepGuard Rebrand — Phase 1 Foundation | Completed | Model expansion (SleepStageSegment, SoundCategory.coughing), DetectionState rename, app-wide rebrand (bundle ID, display name, strings), build succeeds |
| 2026-05-26 | P2-T1 SpeechDetector | Completed | SpeechDetector singleton with confidence + db thresholds; SoundAnalysisDetector extracts speech confidence from built-in classifier; build succeeds |
| 2026-05-25 | F14 Feature Doc | Completed | Created `docs/features/f14-sleepguard-rebrand.md` with full template: Files (23 entries), Routes, State, Edge Cases (7), Tasks Completed (5), Remaining Work (Phases 2–4, 15 tasks) |
| 2026-05-24 | Unify duration format across app | Completed | Created `DurationFormatter.hoursAndMinutes` in DesignSystem. Updated TrendsView, Last7NightsStatGrid, Last7NightsRow, SessionStatsGrid, NightGroupRowView to use shared formatter. Removed 5 single-use private wrapper functions. TrendsView label changed from "SNORING MINUTES" to "AVG SNORING". Build succeeds |
| 2026-05-23 | Mock data for App Store screenshots | Completed | Created `MockDataGenerator` generating realistic May 1–23 sleep sessions with trending scores (worse→better), variable events, midnight GMT+2 starts, and multi-session days. Wired `-generateMockData` DEBUG launch argument. Data verified on Statistics dashboard. Build succeeds |
| 2026-05-22 | Future-proof data model for multi-sound detection | Completed | Added `SoundCategory` enum (snoring/sleepTalking/noise/other) to `SnoreEvent` with default `.snoring` — lightweight SwiftData migration, zero data loss. Added `SleepSession.duration(for:)` helper. Explicit `.snoring` in `SessionManager`. No UI changes — stats grid unchanged. Build succeeds |
| 2026-05-22 | Snore detection thresholds + epic tier + sensitivity | Completed | Added 4th `.epic` intensity tier matching SnoreLab. Tightened SoundAnalysis floors (-60→-45, -40→-30, -25→-15) and spectral thresholds (-35→-30, -25→-20, -15→-10, epic=-5). Wired `UserPreferences.detectionSensitivity` to shift thresholds ±5 dB. Updated `sleepScore` for epic penalty. Added `SettingsRecordingSection` with picker. All intensity switches updated. Build succeeds |
| 2026-05-22 | Background audio recording fix | Completed | `SnoreGuard/Info.plist` now explicitly contains `UIBackgroundModes = [audio]` (was missing from built app despite build setting). `AudioRecorder` added `.mixWithOthers`, `isPaused` flag, `routeChangeNotification` + `didBecomeActiveNotification` observers, and robust `resumeRecordingIfNeeded()` fallback. `SoothingMelodyPlayer` no longer changes `AVAudioSession` category to `.playback` (was dropping mic). Build succeeds |
| 2026-05-22 | Snoring time calculation refactor | Completed | `SnoreEvent` gained `duration` field storing event-span (first→last snore, including natural breathing pauses). `snoreDuration` returns `duration` for new data, falls back to burst-sum for legacy. `SleepSession.snoringDuration` no longer adds `gapsDuration`. Aligns with SnoreClock/SnoreLab validated epoch-based measurement. Build succeeds |
| 2026-05-19 | Increase snore event gap threshold | Completed | `eventGapThreshold` in SessionManager changed from 3.0 → 10.0 s. Brief breathing pauses under 10 s now merge into a single SnoreEvent instead of splitting into separate events. Existing burst tracking and gap-free clip extraction already support this. Melody play/stop logic is decoupled and unaffected. Build succeeds |
| 2026-05-19 | Low battery force-save + banner | Completed | SessionManager polls battery every 30s during recording; at ≤2% calls `forceSaveDueToLowBattery()` which stops session and sets `forceSaveReason`. StatisticsTab auto-saves force-saved sessions to SwiftData + HealthKit without showing summary sheet. UserDefaults stores termination reason keyed by session ID. New `LowBatteryBannerView` (MelodyGapsBannerView-inspired) shown in `SessionSummaryView` and `SessionDetailView` when reason exists. Cleanup on session delete. No SleepSession model changes. Build succeeds |
| 2026-05-18 | Gap tracking reliability + model lightness + banner pluralization | Completed | Removed notification-based gap tracking (`.recordingDidPause/.recordingDidResume`); replaced with direct `.soothingMelodyDidStop` observation in SessionManager. Events no longer discarded during mic pause (`!sooothingMelodyPlayer.isPlaying` guard on finalize + `lastSnoringSampleTime` extended on resume). `gapsDuration` reverted from stored to computed to keep SleepSession lightweight. Force-finalized events now have 0.5s minimum (was 0s). MelodyGapsBannerView durationString changed to "over X mins" with proper pluralization |
| 2026-05-17 | UI Polish — Tab Bar + Recording Layout | Completed | `@MainActor` on `onStartRecording` closures (Statistics package); `RecordingPrestartView` compact-height adaptive layout (icon 100→80, headline 28→24 on ≤874 pt screens); custom tab bar `matchedGeometryEffect` sliding pill; liquid glass mimic for iOS < 26 via `.ultraThinMaterial` + gradient highlights |
| 2026-05-16 | Mic permission + charging gates | Completed | RecordingPrestartView and RecordingCountdownView now enforce microphone permission (requests if undetermined, alerts with Settings link if denied) and require iPhone charging (alerts with "Start Anyway" override) before starting a session |
| 2026-05-16 | Melody polish + Event Player fixes | Completed | Lock-screen note; 4s min melody duration; AVAudioEngine recreation fix for recording resume; simulator setActive(false) before playback; missing audio fallback (noAudioView); waveform skeleton loading + Task.detached generation |
| 2026-05-16 | Remove minSnoreDuration from Settings | Completed | Removed user-facing minSnoreDuration stepper from SettingsDetectionSection; hardcoded 2.0 s default in SessionManager; removed 3 unused localization keys; SettingsDetectionSection deleted |
| 2026-05-16 | Fix HealthKit sync auth persistence | Completed | Added `HealthKitSync.checkAuthorizationStatus()` on app launch; Settings toggle now only stays ON if auth is granted; `SessionSummaryView` re-checks auth before syncing so sync works across app restarts |
| 2026-05-14 | Soothing Melody Sheet + Picker Sheets | Completed | RecordingPrestartView actionRow with dynamic value; SoothingMelodySheet with wheel picker (Never/Always/5s/15s/30s/60s), song row, status badge; MelodyPickerSheet with melody 9–17 selection; Melody model + UserPreferences settings; tipsSection gradient glow + stroke; SheetHandle + SheetNavHeader components |
| 2026-05-14 | Soothing Melody Audio Playback | Completed | Wired 11 real MP3s from `sounds/` bundle; SoothingMelodyPlayer (Env) with AVAudioPlayer, auto-stop timer, re-trigger guard; SessionManager triggers play on new snore event; BedsideClockView overlay with pulsing icon + Stop button; detection continues during playback; builds clean |
| 2026-05-14 | Custom Melody Recording | Completed | Pinned "Record yours" row in MelodyPickerSheet; RecordCustomMelodySheet with 10s AVAudioRecorder, playback, re-record, save; CustomMelodyStorage persists to Documents/CustomMelodies/; custom melodies appear in picker, previewable, deletable, and playable during snore detection; SheetHandle/SheetNavHeader extracted to DesignSystem |
| 2026-05-12 | Session 38: Performance fixes + stop button bug + gauge animation | Completed | Fixed `BedsideClockView` stop button always showing short-session alert (used `totalDuration` which is 0 during recording); parallelized `AudioClipExtractor` with `TaskGroup` (batch 4); single-pass `sleepScore`; `NightGroup` stats cached at init; `SessionDetailView` pre-computes sortedEvents/isClipSession in async load; `SnoringTimelineView` skips unnecessary sort; `SleepScoreGauge` animates from 0 on first load |
| 2026-05-11 | PDF visual polish + dark mode color preservation | Completed | Blue gradient header (`#7FD9F2` → `#1A73C0` → `#0D2666`); icy blue card backgrounds (`#F0F7FF`); explicit white page background fill; replaced all `UIColor.white` with explicit RGB; forced `UITraitCollection(userInterfaceStyle: .light)` during generation; removed unused dark red color constants |
| 2026-05-10 | Raw data preservation + per-burst tracking + orphaned file cleanup + mini player dot fix | Completed | Added `SleepSession.rawAudioFileURL` + `rawLogFileURL`; `SessionRawLogWriter` buffers every 50ms classification sample as JSON; `SnoreBurst` tracks continuous snoring segments within events; `snoreDuration` now = sum of burst durations (true snoring time, excludes gaps); `AudioClipExtractor` composes gap-free clips via `AVMutableComposition`; `deleteSessionFiles()` cleans up all files on deletion; Mini player dots now positioned on clips timeline so they align with playback progress |
| 2026-05-09 | Localization: Semantic key migration | Completed | Migrated 132 xcstrings keys from raw English to dot-notation (e.g. `onboarding.page1.title`, `session.recording.statusFormat`); updated generator with camelCase splitting; all 42 source files updated; zero build errors; max constant name 40 chars |
| 2026-05-09 | F4-T6 Polish + Playback Fixes + Reusable Stats Grid + Navigation Polish | Completed | Zero-padding clips, AudioFileURLResolver (stale path fix), SessionStatsGrid, NightGroupRowView single-tap nav, waveform seek, expand hint, hide Peak dB |
| 2026-05-09 | F4-T6: Snore-Only Recordings + Advanced Frequency Player | Completed | Per-event audio clips with spectral analysis; expandable advanced player with waveform, spectrum bars, and stats; legacy full-file fallback |
| 2026-05-09 | F2-T8: Snore event debounce | Completed | Added 3-second gap threshold in SessionManager to merge snore events separated by brief breaths |
| 2026-05-08 | Session 31: Delayed Recording Start (replaces Smart Alarm) | Completed | Replaced Smart Alarm with countdown-based delayed recording; RecordingDelayManager with background timer; RecordingPrestartView delay picker; RecordingCountdownView; SettingsView Start delay; removed alarm badge/overlay |
| 2026-05-08 | Session 30: Summary Polish + Tab Bar Fix + Background Recording | Completed | Save Session button dark pill + glow; 10-min minimum validation alert; custom floating tab bar for iOS < 26; hide tab bar during recording; background recording interruption + route change handling |
| 2026-05-08 | Session 29: Button Redesign + Calendar Polish + Bulk Delete | Completed | RecordingActionButton generic component with glow; CalendarView nav title + day cell backgrounds + today highlight; surface2 theme token; Recordings swipe + long-press bulk delete |
| 2026-05-07 | Session 28: Detection Pipeline Hardening + UI Polish + Recordings Grouping | Completed | Actor-isolation race fix; bandpass filter on recordings; eventsCount stored property fix; dB/snoreConf removed from UI; stats day-averaging; recordings grouped by night with expandable cards |
| 2026-05-07 | F9 Enhancement: SoundAnalysis Snore Detection | Completed | Apple's built-in 300-class sound classifier via SNAudioStreamAnalyzer; zero app size; auto-fallback to FFT if snoring not in built-in classes; runtime diagnostic prints all known classifications |
| 2026-05-07 | Bug Fix: Real-Device Recording | Completed | Fixed playback (`fileExists` URL→path), detection thresholds (-40→-35, CoreML disabled), AudioRecorder format validation + write error logging |
| 2026-05-07 | Design Polish | Completed | Onboarding: button bottom padding (40–48px) to clear swipe area; horizontal padding matched to design (24–32px); badges moved inside text VStack for consistent positioning; progress dots aligned across all pages via invisible Back button placeholder |
| 2026-05-07 | F11-T4 | Completed | Watch data sync via WCSession sendMessage + application context fallback |
| 2026-05-07 | F11-T3 | Completed | WatchAudioRecorder with AVAudioEngine tap and dB threshold detection |
| 2026-05-07 | F11-T2 | Completed | WatchConnectivityManager iOS + WatchSessionManager with WCSessionDelegate |
| 2026-05-07 | F11-T1 | Completed | Watch app source files with SwiftUI UI; manual Xcode target setup documented |
| 2026-05-07 | F10-T3 | Completed | Smart Alarm UI in Settings + Pre-start screen with toggle, time picker, window duration |
| 2026-05-07 | F10-T2 | Completed | BedsideClockView alarm evaluation loop + full-screen alarm overlay with I'm Awake / Snooze |
| 2026-05-07 | F10-T1 | Completed | AlarmManager singleton with UNUserNotificationCenter scheduling and smart wake evaluation |
| 2026-05-07 | F12-T3 | Completed | Settings toggle for HealthKit sync; auto-triggers after session save |
| 2026-05-07 | F12-T2 | Completed | HealthKitSync.writeSleepData creates HKCategorySample with session timestamps and snore metadata |
| 2026-05-07 | F12-T1 | Completed | HealthKit capability + entitlements added to app target; HealthKitSync singleton created in Env package |
| 2026-05-07 | F9-T2 | Completed | SnoreDetector uses CoreML with confidence threshold; falls back to dB thresholds automatically |
| 2026-05-07 | F9-T1 | Completed | Generated SnoreClassifier.mlmodel (decibel → none/quiet/light/loud), integrated into AudioEngine |
| 2026-05-07 | F8-T2 | Completed | PDF share UI — doc.text toolbar button generates sleep report PDF and presents share sheet |
| 2026-05-07 | F8-T1 | Completed | SleepReportPDFGenerator using UIGraphicsPDFRenderer with stats, score, event list |
| 2026-05-07 | F7-T2 | Completed | Export individual event clips via AVAssetExportSession (.caf → .m4a, ±2s trim), shared via ActivityView |
| 2026-05-07 | F7-T1 | Completed | Share full session audio via UIActivityViewController; wired existing toolbar button, conditional on audioFileURL |
| 2026-05-07 | CalendarView | Completed | Built month calendar with session dots, stats, selected-night card; fixed weekday header locale alignment + double back button |
| 2026-05-06 | Polish | Completed | V1 bug hunt: RecordingRowView wired, Color.green→theme, Trends dup labels, SessionDetail delete+URL fix, Stats design compliance |
| 2026-05-06 | F6-T3 | Completed | Delete All Data alert + SwiftData cascade delete; About section with version + rate app store link |
| 2026-05-06 | F6-T2 | Completed | SettingsView with all design sections: Detection, Recording, Appearance, Data, About; confirmationDialogs for pickers |
| 2026-05-06 | F6-T1 | Completed | Extended UserPreferences with minSnoreDuration (default 2s) and maxClipLength (default 30s); Color(hex:) made public |
| 2026-05-06 | F5-T2 | Completed | Stat cards built as part of TrendsView: Avg Score, Best/Worst Night, Total Events |
| 2026-05-06 | F5-T1 | Completed | TrendsView with week/month toggle, Swift Charts bar chart, intensity-colored bars, 4 stat cards |
| 2026-05-06 | F4-T4 | Completed | Audio file saving (full session .caf), mini player with play/pause/scrub/event markers, event row playback |
| 2026-05-06 | F4-T5 | Completed | Fixed .recordingDetail(id:) route in AppRegistry → SessionDetailView; navigation now works end-to-end |
| 2026-05-06 | F4-T3 | Completed | SessionDetailView with score gauge, stats grid, SnoringTimelineView, event list; FetchDescriptor by UUID |
| 2026-05-06 | F4-T2 | Completed | RecordingRowView extracted with score badge, event count, tap navigation to .recordingDetail |
| 2026-05-06 | F4-T1 | Completed | RecordingsListView with ViewState, empty/loaded/error, month-grouped sections, pull-to-refresh |
| 2026-05-06 | F3-T3 | Completed | Converted .liveSession to RouterDestination; Start Recording CTA now uses routerPath.navigate(to:) |
| 2026-05-06 | F3-T2 | Completed | SleepScoreGauge, StatCard, SleepSparkline components; loaded view with gauge + 6 stat cards + sparkline |
| 2026-05-06 | F3-T1 | Completed | StatisticsDashboardView with ViewState, empty/loaded/error, @Query, presentational children |
| 2026-05-06 | F2-T6 | Completed | Route registration + wiring: Start Recording CTA, sheet lifecycle, onboarding routing |
| 2026-05-06 | F2-T5 | Completed | Session summary sheet with sleep score ring, stats grid, Save/Discard |
| 2026-05-06 | F2-T4 | Completed | Bedside clock active recording UI with dB bar, snoring glow, timer |
| 2026-05-06 | F2-T3 | Completed | Pre-start recording screen with mic status + tips + CTA |
| 2026-05-12 | F2-T2 | Fix | Sleep score formula revised (snoring cap 70, events cap 20, intensity penalty added); moved from SwiftData stored to computed property |
| 2026-05-12 | F2-T2 | Refactor | Converted `totalDuration`, `snoringDuration`, `snoringPercentage`, `eventsCount`, `eventsPerHour` from stored to computed on `SleepSession` |
| 2026-05-12 | Session 38 | Bugfix | `BedsideClockView` stop button short-session alert used `session.totalDuration` (always 0 during recording) → fixed to live elapsed time |
| 2026-05-12 | Session 38 | Perf | `AudioClipExtractor.extractClips()` parallelized with `TaskGroup` (batch size 4) |
| 2026-05-12 | Session 38 | Perf | `sleepScore` single-pass; `NightGroup` stats cached at init; `SessionDetailView` pre-computes in async load; `SnoringTimelineView` sort-skip |
| 2026-05-12 | Session 38 | UX | `SleepScoreGauge` animates from 0 → target on first load |
| 2026-05-12 | Session 39 | Perf | Lazy audio init (legacy + clips); `ClipPlaybackController` skips file checks; `SnoringTimelineView` uses `Canvas` instead of `ForEach` |
| 2026-05-12 | Session 39 | Bugfix | False-positive snore detection: removed dB fallback, spectral threshold 0.3→0.6, removed "breathing" identifier, consecutive sample gate, wired `minSnoreDuration` preference |
| 2026-05-12 | Session 39 | UX | Sheet-based player + events UI: `SessionDetailView` restructured with fake mini player bar + `PlayerSheetView` sheet for real audio; `EventsSheetView` with horizontal event cards; audio I/O fully deferred from detail view load path |
| 2026-05-14 | Session 41 | Feature | Last 7 Nights dedicated screen (`Last7NightsView`) matching design fuq0d — chart, stats grid, ALL NIGHTS list, week-over-week trend |
| 2026-05-14 | Session 41 | Polish | Unified duration format to `%d h %d min` / `%d min` across `Last7NightsRow`, `SessionSummaryView`, `BedsideClockView`, `WatchSessionManager` |
| 2026-05-14 | Session 41 | UX | Added event timestamp (`hh:mm am/pm`) to `EventPlayerView` header before "Snoring Event" |
| 2026-05-14 | Session 41 | Bugfix | Fixed tab navigation: each tab now owns its `@State var routerPath` — previously all tabs shared `settingsRouterPath` due to `.environment()` overwrite |
| 2026-05-14 | Session 41 | Route | Added `.last7Nights` to `RouterDestination`; wired "See all" button in `StatisticsMiniChartSection` |
| 2026-05-13 | Session 40 | Polish | Single-event playback from EventsSheetView and SessionDetailEventsView — nested sheet preserves parent, passes `[event]` to PlayerSheetView |
| 2026-05-12 | F2-T2 | Refactor | Converted `SnoreEvent.snoreDuration` from stored to computed (derived from `bursts`) |
| 2026-05-06 | F2-T2 | Completed | SessionManager real-time event tracking + sleep score |
| 2026-05-06 | F2-T1 | Completed | AudioRecorder + SnoreDetector verified from scaffold |
| 2026-05-06 | F1-T2 | Completed | Onboarding screens 1-3 UI with animations |
| 2026-05-06 | Phase 0 | Scaffold complete | Architecture scaffolded, 9 packages, build succeeds |
| 2026-05-06 | Phase 0 | Started | Project kickoff initiated |

## Currently Active

| Task | Feature | Started | Assignee |
|------|---------|---------|----------|
| P3-T6 Build & verify | F14 | 2026-05-26 | — |

## Completed (last 10)

| Task | Feature | Completed | Duration |
|------|---------|-----------|----------|
| P3-T5 Player labels | F14 | 2026-05-26 | — |
| P3-T4 Stats grid supplement | F14 | 2026-05-26 | — |
| P3-T3 Timeline multi-color | F14 | 2026-05-26 | — |
| P3-T2 EventRow icons | F14 | 2026-05-26 | — |
| P3-T1 Category filter | F14 | 2026-05-26 | — |
| P2-T5 Build & verify | F14 | 2026-05-26 | — |
| P2-T4 Settings toggle | F14 | 2026-05-26 | — |
| P2-T3 Event creation for sleep talking | F14 | 2026-05-26 | — |
| P2-T2 Parallel detection wiring | F14 | 2026-05-26 | — |
| P2-T1 SpeechDetector | F14 | 2026-05-26 | — |
| SleepGuard Rebrand — Phase 1 Foundation | F14 | 2026-05-25 | — |
| Session 39 | F4 | 2026-05-12 | — |
| Session 38 | F4 | 2026-05-12 | — |
| F4-T6 | F4 | 2026-05-09 | — |
| F2-T8 | F2 | 2026-05-09 | — |

## Completed (last 10)

| Task | Feature | Completed | Duration |
|------|---------|-----------|----------|
| Session 30 | V2 Polish | 2026-05-08 | — |
| Session 29 | V2 Polish | 2026-05-08 | — |

## Up Next

_Unblocked tasks in priority order. F13 (CloudKit Sync) is intentionally skipped for now. F14 is the active focus._

| Task | Feature | Priority | Why Ready |
|------|---------|----------|-----------|
| P4-T3 Stage timeline overlay | F14 | P2 | Depends on P4-T2 |
| P4-T2 Stage correlation | F14 | P2 | Depends on P4-T1 |
| P4-T3 Stage timeline overlay | F14 | P2 | Depends on P4-T2 |
| P4-T4 Statistics integration | F14 | P2 | Depends on P4-T3 |
| P4-T5 Settings toggle | F14 | P2 | Depends on P4-T4 |
| P4-T6 Build & verify | F14 | P2 | Depends on P4-T5 |

## Blocked

| Task | Feature | Blocker | Since |
|------|---------|---------|-------|
| (none) | — | — | — |

## Completed (last 10)

| Task | Feature | Completed | Duration |
|------|---------|-----------|----------|
| Session 29 | V2 Polish | 2026-05-08 | — |
| F11-T4 | F11 | 2026-05-07 | — |
| F11-T3 | F11 | 2026-05-07 | — |
| F11-T2 | F11 | 2026-05-07 | — |
| F11-T1 | F11 | 2026-05-07 | — |
| F10-T3 | F10 | 2026-05-07 | — |
| F10-T2 | F10 | 2026-05-07 | — |
| F10-T1 | F10 | 2026-05-07 | — |
| F12-T3 | F12 | 2026-05-07 | — |
| F12-T2 | F12 | 2026-05-07 | — |

---

## Update Rules (for the AI)

After **every task**, update this file:
1. Recalculate all Dashboard counts and progress percentage
2. Move completed task from "Currently Active" to "Completed (last 10)"
3. Update the Features table: status, task counts, progress bar
4. Add a row to Activity Log
5. Refresh "Up Next" — check if blocked tasks are now unblocked
6. Update `Last updated` date
7. If a feature is fully done: set status to **Done**, progress to 100%
