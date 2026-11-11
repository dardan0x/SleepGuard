---
date: 2026-11-11
feature: F22
branch: feature/f22/t9-detection-replay
title: F22-T9 detection replay tests from a real recording
---

### Completed
- F22-T9: four excerpts of a real 37-minute iPhone recording are replayed through `DetectionStateMachine`. Every decision is compared with a reviewed golden file.

### Technical Details
- The source log is the user's recording from 2026-11-11: imitated snoring, Snore Interrupter off, 41,594 samples. It is **raw log format 1**, because the phone build predates T1. There is no speech data and no settings metadata, so the replay runs at Medium with sleep talking off.
- Fixtures are compact CSV: elapsed rebased to the excerpt start, plus db, spectralScore, snoreConfidence and state. Values are rounded, and the goldens are generated from the rounded data. The fixtures are bundled with `.copy("Fixtures")`.
- Goldens are one line per decision with times in seconds: start, finalize (span, intensity, dB, confidence, bursts) and discard reason. `melodyRequested` is only counted.
- Re-recording needs `TEST_RUNNER_RECORD_REPLAY_GOLDENS=1`, passed by `scripts/record-replay-goldens.sh`. It writes into the source tree through `#filePath` and prints the golden diff. A normal run only compares, and on mismatch it reports the first differing line.
- Mutation check: changing the silence gap from 10 s to 9 s fails all 4 replays. The change was reverted.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Tests/DetectionReplayTests.swift` | +175 | Replay test (4 fixtures) + determinism test + fixture loader + transcript |
| `Packages/AudioEngine/Tests/Fixtures/Replay/*.csv` | 4 files, 1.1 MB | Excerpts |
| `Packages/AudioEngine/Tests/Fixtures/Replay/*.golden.txt` | 4 files | Recorded goldens |
| `Packages/AudioEngine/Tests/Fixtures/Replay/README.md` | +45 | Source, coverage, how to change goldens |
| `Packages/AudioEngine/Package.swift` | +3 | Test resources |
| `scripts/make-replay-fixture.py` | +75 | Cuts an excerpt from a raw log (format 1 or 2) |
| `scripts/record-replay-goldens.sh` | +22 | Explicit golden re-record + diff |
| `docs/trackers/f22-architecture-hardening.md`, `docs/FeatureTracker.md` | — | T9 Done, 12/14 |

### Architecture Decisions
- The goldens are a regression net, not an accuracy claim: they pin today's decisions on real, noisy input for T10.
- The goldens are text, not JSON, so a detection change reads as a reviewable line diff in a PR.

### Build Status
- Lint clean; layering and view-size checks pass; AudioEngine 57 tests pass. No app code changed.

### Suggested Branch
`feature/f22/t9-detection-replay`

### Suggested Commit
`F22-T9 — Detection replay tests from real-recording excerpts`

### Changes done
- See Files Changed.

### Next Session
- T10: `DetectionEngine` actor + `AsyncStream` + ADR 0003. The replay goldens must stay identical.
- Follow-up: add a format-2 excerpt with sleep talking from a real night recorded on a current build.

### Open Questions
- Does the event timing match what was actually done during the recording? Detection saw one long snoring stretch from 0:00 to about 6:54, a loud spike at about 7:06, short isolated snores around 9–10 min, a long stretch from about 15:51 to 20:03, and a short one from about 24:15 to 25:04.
