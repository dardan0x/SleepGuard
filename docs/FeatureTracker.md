# SnoreGuard — Feature Tracker

> Auto-updated by the AI after every task. This is the local source of truth.

Last updated: 2026-05-14 (Session 41)

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
| Total Tasks | 42 |
| Tasks Done | 42 |
| Tasks In Progress | 0 |
| Tasks Blocked | 0 |
| Tasks Backlog | 0 |
| — | — |
| **Progress** | **100%** |

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

## Activity Log

_Most recent first. The AI appends here after every task._

| Date | Task | Action | Notes |
|------|------|--------|-------|
| 2026-05-14 | Soothing Melody Sheet + Picker Sheets | Completed | RecordingPrestartView actionRow with dynamic value; SoothingMelodySheet with wheel picker (Never/Always/5s/15s/30s/60s), song row, status badge; MelodyPickerSheet with melody 9–17 selection; Melody model + UserPreferences settings; tipsSection gradient glow + stroke; SheetHandle + SheetNavHeader components |
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
| (none) | — | — | — |

## Completed (last 10)

| Task | Feature | Completed | Duration |
|------|---------|-----------|----------|
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

_Unblocked tasks in priority order. The AI updates this after every task._

| Task | Feature | Priority | Why Ready |
|------|---------|----------|-----------|
| F13-T1 | CloudKit Sync | P2 | No blockers |
| F13-T2 | CloudKit Sync | P2 | Depends on F13-T1 |
| F13-T3 | CloudKit Sync | P2 | Depends on F13-T1 |

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
