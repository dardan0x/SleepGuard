# F4 — Recordings

## Overview

List past sleep sessions grouped by month. Tapping a session opens a detail view with a snoring timeline visualization and audio playback with event markers.

## Status

**Done** — All 5 tasks complete.

## Files

| File | Purpose |
|------|---------|
| `Packages/Recordings/Sources/Recordings/RecordingsListView.swift` | Container view with ViewState, month-grouped sections, empty/loaded/error states |
| `Packages/Recordings/Sources/Recordings/RecordingRowView.swift` | Presentational row with date, duration, events, score badge, tap navigation |
| `Packages/Recordings/Sources/Recordings/SessionDetailView.swift` | Session detail with score gauge, stats grid, timeline, event list, mini player |
| `SnoreGuard/AppRegistry.swift` | Route registration for `.recordingDetail(id:)` → `SessionDetailView` |
| `Packages/AudioEngine/Sources/AudioEngine/AudioRecorder.swift` | Audio file saving infrastructure (full session `.caf` file) |
| `Packages/Models/Sources/Models/SleepSession.swift` | `audioFileURL` property added |
| `Packages/Env/Sources/Env/SessionManager.swift` | File URL generation, audio cleanup on discard |
| `Packages/SleepSession/Sources/SleepSession/SessionSummaryView.swift` | Calls `discardCompletedSession()` on discard |

## Routes

| Type | Destination | View | Trigger |
|------|------------|------|---------|
| Push | `.recordingDetail(id:)` | `SessionDetailView` | Tap row in recordings list |

## State

| State | Type | Scope | Description |
|-------|------|-------|-------------|
| `ViewState` | enum | `RecordingsListView` | `.loading`, `.empty`, `.loaded(sections:)`, `.error` |
| `ViewState` | enum | `SessionDetailView` | `.loading`, `.loaded(session:)`, `.error` |
| `audioPlayer` | `AVAudioPlayer?` | `SessionDetailView` | Playback instance for the session's audio file |
| `isPlaying` | `Bool` | `SessionDetailView` | Playback state |
| `currentPlaybackTime` | `TimeInterval` | `SessionDetailView` | Current playback position |

## Edge Cases

| Case | Handling |
|------|----------|
| No recordings | `RecordingsListView` shows empty state with moon icon and "No recordings yet" |
| Session has no audio file | Mini player hidden; `SessionDetailView` still shows all other data |
| Audio file missing on disk | `AVAudioPlayer` init fails silently; mini player shows but playback is no-op |
| User discards session | `SessionManager.discardCompletedSession()` deletes audio file from Documents |
| Simulator mic permission | Auto-granted via `#if targetEnvironment(simulator)` in `AudioRecorder` |

## Tasks Completed

- F4-T1: RecordingsListView (empty + grouped list)
- F4-T2: RecordingRowView component
- F4-T3: SessionDetailView with timeline
- F4-T4: Audio playback with event markers
- F4-T5: Route registration

## V2 Enhancements

- Per-event audio clips (save short buffers around each snore event separately)
- Full-screen playback view with waveform visualization
- Share audio clip functionality
- Background audio playback during review
