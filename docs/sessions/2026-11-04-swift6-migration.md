---
date: 2026-11-04
feature: f17
branch: feature/f17/swift6-migration
title: Swift 6 Migration
---

### Completed
- F17-T1: Migration baseline — branch created, baseline build succeeded (Swift 5), test run documented (no test action in scheme), tripwire audit (0 `@unchecked Sendable`, 0 Combine, 176 files)
- F17-T2: Models → Swift 6 (tools 6.2 + v6). Fix: `SnoringEpisode` dropped `Sendable` (held `[SnoreEvent]` @Model refs)
- F17-T3: AudioEngine → Swift 6. Fixes: `ClipResult: Sendable`; `extractSingleClip` refactored to Sendable params (no @Model capture in `addTask`)
- F17-T4: Env → Swift 6. Fixes: `StorageLimitEnforcer` `Sendable` + `@MainActor` (removed `MainActor.run` wrapper sending `ModelContext`); `WatchConnectivityManager` `nonisolated` WCSessionDelegate methods (2 iterations)
- F17-T5: DesignSystem → Swift 6 + `.defaultIsolation(MainActor)`. Consumer fallout fixed: `TimeRange` (Statistics), `EventCategoryFilter` (Recordings) annotated `@MainActor`
- F17-T6–T8, T10–T12: Onboarding, SleepSession, Statistics, Personalization, Settings, Learn → Swift 6 + `.defaultIsolation`. SleepSession needed `PreviewSpeakerIcon` (`#available(iOS 18, *)` bounce; pulse fallback on 17). Rest were manifest-only
- F17-T9: Recordings → Swift 6. Fixes: `WaveformGenerator` statics `nonisolated`; `event.snoreDuration` hoisted out of `Task.detached`
- F17-T13: App target → `SWIFT_VERSION = 6.0` + `SWIFT_STRICT_CONCURRENCY = complete`. Compiled clean FIRST try — all 9 app files zero changes
- F17-T14: Verification — build zero errors; simulator launch/render healthy (Statistics + 4 tabs); `generate-strings.py` exit 0
- F17-T15: Docs sync — concurrency/overview/modules/rules/INDEX rewritten for Swift 6 (local, gitignored); AGENTS.md + CLAUDE.md concurrency rules updated
- F17-T16: This feature doc + session fragment

### Technical Details
- Isolation split: explicit `@MainActor` in Models/Env/AudioEngine (no package default); `.defaultIsolation(MainActor.self)` in DesignSystem, Onboarding, SleepSession, Statistics, Recordings, Personalization, Settings, Learn
- `.defaultIsolation` makes all package public API (incl. `Strings`) MainActor-isolated — nonisolated enums referencing `Strings` needed `@MainActor`
- Swift 6 enforces protocol-conformance availability: `BounceSymbolEffect: IndefiniteSymbolEffect` is iOS 18+ while target is iOS 17
- SDK does not Sendable-check `installTap`, `requestMediaDataWhenReady`, or `decidePolicy` blocks — compiled unchanged; on-device verification is the safety net
- `StorageLimitEnforcer.enforceLimits` restructured from `await MainActor.run` to `@MainActor` function — the wrapper's `@Sendable` closure sent `ModelContext`
- Merge workflow: small manifest-only flips merged locally into `feature/f17/swift6-migration`; multi-file/behavioral changes went through user-opened PRs (#62–#72)

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| 11 × `Packages/*/Package.swift` | ~+60 | tools 6.2, `swiftLanguageMode(.v6)`, `.defaultIsolation` where applicable |
| `SleepGuard.xcodeproj/project.pbxproj` | +4/-2 | `SWIFT_VERSION = 6.0`, `SWIFT_STRICT_CONCURRENCY = complete` (Debug+Release) |
| `SnoreEpisode.swift` | 1 | `Sendable` removed from `SnoringEpisode` |
| `AudioClipExtractor.swift` | ~+20/-10 | `ClipResult: Sendable`; Sendable-params `extractSingleClip` |
| `StorageLimitEnforcer.swift` | ~+5/-25 | `Sendable` class; `@MainActor` entry; wrapper removed |
| `WatchConnectivityManager.swift` | ~+15/-5 | `nonisolated` delegates, MainActor hops |
| `TrendsView.swift` / `SessionDetailView.swift` | +1 each | `@MainActor` on private enums |
| `MelodyPickerSheet.swift` | ~+20/-10 | `PreviewSpeakerIcon` with availability gate |
| `WaveformGenerator.swift` / `PlayerSheetView.swift` | +3/-2 | `nonisolated` statics; Sendable capture hoisting |
| `AGENTS.md`, `CLAUDE.md` | +14/-10 | Swift 6 concurrency rules |
| `docs/architecture/*` (8 files) | rewritten | Swift 6 reality (gitignored, local-only) |

### Architecture Decisions
- **IceCubes-style isolation split** over all-explicit: removes boilerplate in 8 UI packages; explicit annotations stay load-bearing in Models/Env/AudioEngine
- **Drop `Sendable` from `SnoringEpisode`** rather than snapshot refactor: consumed only synchronously in MainActor UI; minimal-change rule
- **Pulse fallback for iOS 17** melody icon: discrete bounce also resolves to the iOS 18 conformance; pulse's indefinite conformance is iOS 17-annotated
- **Deployment targets unchanged**: language mode is independent of OS target

### Build Status
- **BUILD SUCCEEDED** — zero errors across all targets, every task. Simulator smoke test PASS.

### Suggested Branch
`feature/f17/swift6-migration`

### Suggested Commit
`[F17] — Swift 6 migration complete` (merge `feature/f17/swift6-migration` → `main` via PR)

### Next Session
- On-device recording verification (mic tap → AAC encode → clip playback → melody)
- Optional: `SWIFT_UPCOMING_FEATURE_*` flags pass (IceCubes sets 10)
- Optional: wire `PersonalizationTests` into a scheme

### Open Questions
- Merge `feature/f17/swift6-migration` → `main` now, or after on-device verification?
