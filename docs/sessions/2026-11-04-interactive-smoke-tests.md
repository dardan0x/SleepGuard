---
date: 2026-11-04
feature: f18
branch: feature/f18/t12-shared-viewstate
title: Interactive Simulator Smoke Tests
---

### Completed
- Installed `idb` (brew `facebook/fb/idb-companion` 1.7.8 + pipx `fb-idb`
  under Python 3.14, symlinked to `/opt/homebrew/bin/idb` for the MCP server)
  — the ios-simulator MCP now does full UI automation (find/tap/view).
- Ran interactive smoke tests of the F18-restructured screens on the pinned
  iOS 26.2 simulator.

### Verified flows (screenshots captured during the run)
- **Statistics empty state → Start Recording**: renders with design tokens.
- **T5 RecordingPrestartView**: header/tips card/delay picker/Snore
  Interrupter row/helper text all render correctly after the split.
- **T10 SnoreInterrupterSheet**: nav header, wheel picker, song row
  ("Attention Chime" — the T11 localized default), status badge, save/cancel
  — all new structs render.
- **T8 MelodyPickerSheet**: RecordCustomMelodyRow + MelodyPickerRow list;
  selection moves between melodies with the accent ring/checkmark and
  spring animation; MelodyPreviewPlayer does not crash on tap.
- **T8 RecordCustomMelodySheet**: reached; its mic-permission gate fired
  correctly (system alert with proper usage description).

### Finding: recording-start terminates the app on the iOS 26 simulator
- Symptom: tapping Start Recording (with mic permission undetermined) →
  system permission alert flow → RunningBoard terminates the app
  (`isUserKill:0`), no crash report, no exception in stderr.
- **Bisected: PRE-EXISTING, not an F18/T3 regression.** Reproduced with the
  pre-T3 build (b21d8cf, before the SessionManager decomposition) —
  identical behavior. The recording path has never been simulator-safe in
  this environment; real QA requires a physical device.
- Also observed: `simctl privacy grant microphone` does not prevent the
  alert, and idb coordinate taps cannot dismiss SpringBoard permission
  alerts (known limitation) — so the permission flow blocks full
  BedsideClockView/stop-flow automation here.

### Technical Details
- Environment quirks documented for future runs: TCC state persists oddly
  across reinstalls; prefer `xcrun simctl privacy <udid> grant microphone
  <bundle>` before launching, and treat system alerts as manual-only.

### Build Status
- Current branch (t12, all F18 work) rebuilt and installed successfully;
  all non-recording smoke flows pass.

### Suggested Branch
`feature/f18/t12-shared-viewstate` (docs only — no code changes from smoke)

### Next Session
- User merges the final branch; device QA for the recording stack;
  F18 feature doc + tracker close-out.

### Open Questions
- Recording-flow simulator termination: file as a known simulator
  limitation (device-only QA), or investigate TCC-dangling-alert trigger
  separately?
