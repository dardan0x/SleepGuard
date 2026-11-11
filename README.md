# SleepGuard

> Your bedside sleep lab. SleepGuard listens while you sleep, detects and records snoring and sleep talking, then scores your sleep and shows you how it trends over time.

**100% on-device.** All audio analysis runs locally on your iPhone using Apple's `SoundAnalysis` framework. No accounts, no servers, no audio ever leaves your phone.

📐 **How it's built and why:** the [Technical Overview](docs/TECHNICAL_OVERVIEW.md) covers the architecture, every package, the detection and scoring algorithms, Swift 6 concurrency, dependency injection, testing and CI, and the design decisions behind them.

![Platform](https://img.shields.io/badge/platform-iOS%2017.6%2B-blue)
![Language](https://img.shields.io/badge/Swift-6.2-orange)
![Architecture](https://img.shields.io/badge/architecture-SPM%20%C2%B7%20SwiftData%20%C2%B7%20SwiftUI-green)
![Privacy](https://img.shields.io/badge/privacy-on--device-brightgreen)

---

## What it does

SleepGuard turns your phone into a bedside monitor. Start a session, set it on your nightstand, and it captures the sounds of your night — then in the morning you get a sleep score, a timeline of what happened, and audio clips you can play back.

### Core capabilities

| | Feature | What it does |
|---|---------|--------------|
| 🌙 | **Live sleep session** | Bedside-clock UI with a real-time level meter, snoring glow, and live event detection. Keeps recording in the background, recovers from interruptions and route changes, saves automatically when the battery runs critically low, and can restore a night after a crash. |
| 🔊 | **Snore & sleep-talk detection** | Classifies **snoring** (quiet · light · loud · epic) and, optionally, **sleep talking**, using Apple's on-device sound classifier and the sound level. An FFT-based fallback is implemented and waiting for real-night validation. |
| 📊 | **Sleep quality score** | A 0–100 score derived from snoring percentage, event frequency, sleep-talking, and (when available) sleep-stage architecture. |
| 🎧 | **Audio playback** | Browse past nights, jump between events, and play each event's clip, with optional enhanced audio (normalization + bandpass cleanup). |
| 📈 | **Trends & statistics** | Dashboard, calendar, "Last 7 Nights" view, and weekly/monthly Swift Charts for sleep score, snoring time, and event frequency. |
| ⌚ | **Apple Watch + HealthKit** | Reads sleep stages from Apple Watch, overlays a hypnogram on your timeline, and writes sleep sessions back to Apple Health. |
| 📄 | **PDF sleep reports** | Export a polished report — score, stats, sleep-architecture breakdown, and a full event log — to share with a doctor or partner. |
| 🎵 | **Snore Interrupter** | An optional melody that plays when snoring is detected (built-in library + record-your-own). Recording pauses while it plays, and the gap counts as snoring only if snoring resumes afterwards. |
| ⏰ | **Delayed start** | Start recording after a countdown (15 min – 1 h), so falling asleep isn't recorded. |
| 🔒 | **Privacy-first** | Everything lives locally in SwiftData. No sign-in, no cloud, no tracking. |

---

## How detection works

```
AVAudioEngine tap ──► level (RMS + peak dB) + SoundAnalysis snore / speech confidence
      │
      ▼  sampled every 50 ms
per-sample classifier ──► none · quiet · light · loud · epic
      │
      ▼  one ordered stream into the DetectionEngine actor
event rules: sustained ≥ 75 ms to start · 10 s silence to close · false-positive filters
      │
      ▼
SnoreEvent (bursts, intensity, duration) ──► per-event audio clip (.m4a)
```

- **Events** group continuous activity, merging brief breathing pauses (≤10 s) so one snoring spell is one event, not fifty.
- **Bursts** track the actual snoring segments inside an event, so "snoring time" reflects real snoring, not the silent gaps.
- Detection sensitivity is user-tunable (three presets, 5 dB apart), and sleep-talking detection is an opt-in toggle.
- Details: [Technical Overview §5](docs/TECHNICAL_OVERVIEW.md#5-snore-detection) and [`docs/snore-detection-algorithm.md`](docs/snore-detection-algorithm.md).

**Sleep score** starts at 100 and subtracts capped penalties for snoring time, snoring episodes per hour, snoring intensity, sleep talking, very short or long nights, and (when Watch data is present) sleep stages, against sleep-literature targets (deep ≥ 15%, REM ≥ 18%, awake ≤ 8%). The coefficients are product heuristics, not a clinical measure. Formula and worked example: [Technical Overview §6](docs/TECHNICAL_OVERVIEW.md#6-sleep-score).

---

## Architecture

> The short version is below. For the reasoning behind each decision (packages, MV instead of MVVM, Factory DI, the detection actor, Swift 6 isolation), see the [Technical Overview](docs/TECHNICAL_OVERVIEW.md) and the [architecture decision records](docs/adr/).

A modular Swift Package layout with strict isolation, enforced by the compiler through each `Package.swift`:

```
App target (composition root, route registry, Firebase)
   └─► Feature packages  ─►  DesignSystem  ─►  Models
                         ─►  Env  ─►  AudioEngine  ─►  Models
                         ─►  Routing (leaf: route enums + RouterPath)
```

- Each layer depends only on layers below it. `Models` depends on nothing.
- **Feature packages never import each other.** They talk through route enums in the leaf `Routing` package (`RouterDestination`, `SheetDestination`; see `docs/adr/0001-routing-package.md`), and only the app target's `AppRegistry` maps a route to a concrete screen. The one deliberate exception is `Settings → Personalization` (the embedded profile section).
- The widget extension reuses `Models` + `DesignSystem` and reads a JSON snapshot from the App Group, never SwiftData.

| Package | Responsibility |
|---------|----------------|
| `Models` | SwiftData `@Model` types (`SleepSession`, `SnoreEvent`, `SnoreBurst`, `SleepStageSegment`, `SoundCategory`) and the sleep-score formula (`SleepSession.sleepScore(using:)` + `SleepScoreConfig`) |
| `AudioEngine` | `AVAudioEngine` recording (`AudioRecorder`), `SoundAnalysis` detection, FFT fallback, clip extraction, and the detection rules: the pure `DetectionStateMachine` run by the `DetectionEngine` actor |
| `Env` | Shared `@MainActor @Observable` services, each behind a protocol, and the Factory `Container`: `SessionManager`, `RealtimeDetectionTracker` (feeds the detection engine, performs its outputs), `HealthKitSync`, `UserPreferences`, `TabCoordinator`, melody player. No SwiftUI. Test doubles ship in `EnvTestSupport` |
| `Routing` | `RouterDestination`, `SheetDestination`, `RouterPath`. A leaf package with no package dependencies |
| `DesignSystem` | Theme tokens, charts, reusable components, and auto-generated localized strings. Depends only on `Models` (plus Factory, to register `Theme`) |
| `Onboarding` | First-run flow with permission requests (mic, notifications, HealthKit, Watch) |
| `SleepSession` | Live recording UI, bedside clock, session summary |
| `Statistics` | Dashboard, calendar, trends, Last-7-Nights |
| `Recordings` | Session history, detail view, audio player, PDF export |
| `Settings` | Sensitivity, appearance, HealthKit sync, melodies, data management |
| `Personalization` | Briefing engine and quote bank — the content that personalizes the app |
| `Learn` | Learn tab — educational content about sleep and snoring |

**Patterns enforced project-wide:**
- `@State` + a `ViewState` enum per data-loading view — **no ViewModels**, no boolean soup.
- Dependencies resolve from a [Factory](https://github.com/hmlongco/Factory) container — views use `@Injected(\.service)`; `@Observable` classes resolve via `Container.shared` in init. Every service sits behind a protocol (`Factory<any SessionManaging>`, …) with a test double in `EnvTestSupport` (`docs/adr/0002-protocol-services.md`). Feature packages never touch a service's `.shared`; only the app target (the composition root) does. Only `RouterPath` flows through SwiftUI `.environment`.
- All navigation goes through `RouterPath` (`RouterDestination` for push, `SheetDestination` for modals); each tab owns its own path.
- `async/await` everywhere — no Combine, no GCD, no completion handlers.
- **Swift 6 with strict concurrency everywhere** — language mode v6 in all packages, `SWIFT_STRICT_CONCURRENCY = complete` in the app target. `Sendable`/isolation violations are compile errors, fixed properly (never `@unchecked Sendable`). Core packages (`Models`, `Env`, `AudioEngine`) use explicit `@MainActor` annotations; the UI packages declare `MainActor` default isolation.
- **Remote-tunable without a release.** Feature flags and tab order live in `AppConfig` in `Env`, which has no Firebase dependency. `RemoteConfigLoader` in the app target is the only Firebase-aware code and pushes values into it. The sleep-score weights are built in (`SleepScoreConfig.default`); only Debug builds can override them.
- **Crash-safe recording.** During a session `SessionCheckpointStore` writes a recovery snapshot, so a night killed by the system at 4 a.m. can be restored instead of lost.
- **Add-only SwiftData schema.** Properties are only ever added, always with defaults, never renamed or removed, so existing installs never crash on migration. Every container opens through a `VersionedSchema` migration plan (V1, no stages yet), ready for the first change that needs one. `SleepSession` caches its score (versioned, recomputed at launch when the formula changes) so lists never load the `events` relationship.
- **Detection runs off the main actor.** Samples, melody stops, settings changes and session end go into one ordered `AsyncStream`; the `DetectionEngine` actor runs the pure state machine and hands outputs back in order (`docs/adr/0003-detection-actor.md`). Replay tests pin its output on excerpts of a real night.
- **Third-party code is minimal.** Packages use only [Factory](https://github.com/hmlongco/Factory). Firebase (Remote Config, Messaging, Crashlytics) is linked in the app target only and never touches audio.
- **Small views, enforced** — no view file over 200 lines (CI: `scripts/check-view-size.py`, with a ratcheting allowlist for existing offenders), containers under 100; sections are extracted as dedicated view structs (not computed `some View` properties), and sheets/alerts are enum-driven, not boolean flags.
- **UI layering** — only view files import `DesignSystem` for UI chrome, `Env` never imports SwiftUI, and feature packages never touch a service's `.shared`; enforced by `scripts/check-layering.py` in CI.
- Every user-facing string is localized through a generated `Strings` enum.

### Why no ViewModels

SwiftUI views are already value-type descriptions of state, and the Observation framework (iOS 17) lets a view observe `@Observable` services directly. A ViewModel layer would mostly be a mirror of the service, so we skip it:

- **No duplicated state.** Views read the `@Observable` services directly. Observation re-renders only on the properties `body` actually reads, so a ViewModel would add no performance benefit.
- **Local UI state stays local.** Each view's `@State` + `ViewState` enum makes impossible states unrepresentable, with no separate class needed.
- **Less boilerplate.** A ViewModel would mostly forward service calls, and each one is another file for both humans and agents to keep in sync.
- **Big view? Split it, don't add a ViewModel.** Small views are enforced (≤ 200 lines), and each extracted subview owns its own state.
- **DI works outside views.** Plain `@Environment` only resolves inside a view, which is the main reason people still reach for ViewModels. The Factory container resolves anywhere, so an `@Observable` class can get its services without a view.
- **The exception is deliberate.** A dedicated `@Observable` state owner is used only when a screen has real stateful or async workflow logic (`SessionDetailModel`: load, filter, delete; `ClipPlaybackController`: playback).

**Testability doesn't need ViewModels.** Logic lives in plain Swift outside the views (*humble view* / *functional core, imperative shell*), so tests call it directly, with no SwiftUI and no mocks (real services + an in-memory SwiftData `TestStore`):

**277 Swift Testing tests across 8 packages**, run on every PR in CI:

| Package | Tests | What's covered |
|---------|------:|----------------|
| `Models` | 79 | Sleep score (22 + pure formula + versioned cache), snoring episodes, session stats, widget snapshot, crash recovery, schema migration plan |
| `AudioEngine` | 65 | Detection state machine (18), `DetectionEngine` actor, replay against goldens from a real recording, raw-log formats, snore classifier, FFT analyzer, tap levels, clip extraction and compression |
| `Env` | 59 | Detection characterization through the live tracker (13), saving a night (`SessionCommitter`), service overrides with fakes, constructor injection, storage limits, checkpoints, raw-log writer, recording delay |
| `Personalization` | 30 | `BriefingEngine`, a pure function with `now` injected |
| `Statistics` | 18 | `DashboardState` mapping, week-over-week trend calculator |
| `Recordings` | 16 | `SessionDetailModel` (load / filter / delete) with a fake HealthKit, session grouping |
| `DesignSystem` | 7 | Duration and trend formatters, localization catalog, theme override |
| `Routing` | 3 | `RouterPath` navigation and sheets |

### CI and guardrails

| Workflow | Runs on | Checks |
|----------|---------|--------|
| `tests` | Every PR (`macos-26`) | All tests, per package on the iOS Simulator (`scripts/run-tests.sh`) |
| `quality` | Every push + PR | SwiftFormat lint, no hardcoded user-facing strings in the diff, generated `Strings.swift` in sync with the catalog |
| `layering` | Every push + PR | No UI imports in non-view code, no SwiftUI in `Env`, no service `.shared` in feature packages (`scripts/check-layering.py`); no view file over 200 lines unless allowlisted (`scripts/check-view-size.py`) |

A pre-commit hook (`scripts/install-hooks.sh`) runs SwiftFormat on staged Swift files, so lint failures are caught before they reach CI.

---

## Requirements

- iOS 17.6+ (iPhone and iPad)
- Xcode 26+ (Swift 6.2 toolchain)
- Swift 6 language mode with strict concurrency (all packages + app target)
- A physical device for real recording (the simulator uses the Mac's microphone, which is enough for a demo)

## Build & run

```bash
xcodebuild -project SleepGuard.xcodeproj \
  -scheme SleepGuard \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  build
```

Or open `SleepGuard.xcodeproj` in Xcode, select the **SleepGuard** scheme, and run.

> **Tip:** launch with the `-generateMockData` argument in a DEBUG build to populate the dashboard with a realistic month of sample nights — handy for previewing trends and screenshots.

## Project structure

```
SleepGuard/
├── SleepGuard/              # App target — entry point, tabs, composition root, route registry
├── SleepGuard.xcodeproj/
├── Packages/                # 12 feature & support packages (see Architecture)
├── WatchApp/                # watchOS companion sources (not yet an Xcode target)
├── designs/
│   ├── SleepGuard.pen       # Pencil design source — single source of truth for UI
│   └── screenshots/         # Reference screenshots
├── sounds/                  # Soothing melody assets
├── scripts/                 # Localization codegen, test runner, layering + view-size CI checks, replay fixtures
└── docs/                    # ADRs, feature docs and trackers, session summaries
```

## Design

The entire UI is built against a single design source — [`designs/SleepGuard.pen`](designs/SleepGuard.pen) (Pencil format) — using a dark-first theme. Selected tokens:

| Token | Value | | Token | Value |
|-------|-------|---|-------|-------|
| `bg-primary` | `#000000` | | `score-green` | `#30D158` |
| `bg-card` | `#2C2C2E` | | `score-amber` | `#FF9F0A` |
| `accent` | `#5E9CFF` | | `score-red` | `#FF453A` |
| `text-primary` | `#FFFFFF` | | `radius-card` | `16` |
