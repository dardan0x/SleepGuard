# SleepGuard — Technical Overview

A single reference for how SleepGuard is built and why: the architecture, every package, the snore-detection and sleep-score algorithms, the concurrency model, dependency injection, testing and CI, and how the project is developed with AI coding agents.

## Contents

1. [At a glance](#1-at-a-glance)
2. [Architecture](#2-architecture)
3. [Packages](#3-packages)
4. [A night, end to end](#4-a-night-end-to-end)
5. [Snore detection](#5-snore-detection)
6. [Sleep score](#6-sleep-score)
7. [Concurrency (Swift 6)](#7-concurrency-swift-6)
8. [State: why there are no ViewModels](#8-state-why-there-are-no-viewmodels)
9. [Dependency injection with Factory](#9-dependency-injection-with-factory)
10. [Quality: tests, CI, logging, accessibility, privacy](#10-quality-tests-ci-logging-accessibility-privacy)
11. [How the project is built: workflow and AI agents](#11-how-the-project-is-built-workflow-and-ai-agents)
12. [Build and run](#12-build-and-run)
13. [Decisions, history and open items](#13-decisions-history-and-open-items)
14. [Further reading](#14-further-reading)

---

## 1. At a glance

**SleepGuard is an on-device sleep and snore tracker for iOS.** You put the phone on the nightstand and start a session. The app listens all night, detects **snoring** (quiet / light / loud / epic) and, if enabled, **sleep talking**, and saves a short audio clip of each event. In the morning you get a **0–100 sleep score**, a timeline, playable clips, trends and a PDF report.

| | |
|---|---|
| **Platform** | iOS 17.6+ (iPhone and iPad), WidgetKit extension. Watch companion sources exist (`WatchApp/`) but aren't an Xcode target yet |
| **Language** | Swift 6 language mode with **strict concurrency `complete`** everywhere (app target and all packages; packages use swift-tools 6.2) |
| **UI** | SwiftUI, Swift Charts |
| **Persistence** | SwiftData, local only, opened through a `VersionedSchema` migration plan |
| **Audio / ML** | AVAudioEngine, Apple **SoundAnalysis** (built-in classifier, ~300 sound classes), Accelerate/vDSP FFT |
| **Health** | HealthKit: reads Watch sleep stages, writes sleep sessions |
| **Dependency injection** | [Factory](https://github.com/hmlongco/Factory) 3.5 (`FactoryKit`), protocol-typed |
| **Remote** | Firebase Remote Config (feature flags, tabs), Crashlytics, Analytics, Messaging. **Only the app target** links Firebase |
| **Privacy** | No accounts and no servers for user data. Audio never leaves the phone. Privacy manifests for the app and the widget |

**Size:** 12 local Swift packages (237 source files, ~21k lines), the app target (14 files), the widget extension (11 files) and 4 Watch source files. **277 Swift Testing tests** in 8 packages, run in CI. Features are tracked as F1–F23 in [`docs/FeatureTracker.md`](FeatureTracker.md).

---

## 2. Architecture

### 2.1 Pattern

A **modular Swift Package** app using the **MV (Model–View)** approach: SwiftUI views own their screen state, logic lives in services and pure functions, and there are no per-screen ViewModels ([§8](#8-state-why-there-are-no-viewmodels)). The structure follows IceCubesApp, adapted for an audio app: an audio layer instead of a network layer, no authentication, and SwiftData as the main store.

### 2.2 Package graph

Each layer depends only on layers below it, and **feature packages never import each other**.

```
                         ┌──────────────────────────────┐
                         │  App target (SleepGuard)     │  composition root, tabs, route → screen
                         │  + Firebase, widget writer   │  mapping, deep links, Remote Config loader
                         └──────────────┬───────────────┘
   ┌───────────┬────────────┬───────────┼───────────┬───────────┬────────────────┬────────┐
Onboarding SleepSession Statistics Recordings  Settings ──► Personalization     Learn
   │            │                                    (the one allowed feature → feature edge)
   └────────────┴──── also import AudioEngine directly
                                        │
                         ┌──────────────┴───────────────┐
                         │ DesignSystem                 │  Theme, components, charts, Strings
                         └──────────────┬───────────────┘  (depends on Models only)
                         ┌──────────────┴───────────────┐
                         │ Env                          │  services behind protocols, DI container,
                         │                              │  session lifecycle, HealthKit
                         └──────────────┬───────────────┘
                         ┌──────────────┴───────────────┐
                         │ AudioEngine                  │  mic, SoundAnalysis, FFT, detection rules,
                         │                              │  clips
                         └──────────────┬───────────────┘
                         ┌──────────────┴───────────────┐
                         │ Models                       │  SwiftData models, sleep score, logging
                         └──────────────────────────────┘  (depends on nothing)

 Routing  (leaf, SwiftUI only)  ◄── navigating features + app target   route enums + RouterPath (ADR 0001)
 SleepGuardWidgetsExtension     ──► Models + DesignSystem               reads a JSON snapshot, never SwiftData
 WatchApp/                      ──► standalone watchOS sources (WatchConnectivity), not built by the project
```

**Why packages instead of folders:** the compiler enforces the boundaries, so a stray import fails the build instead of slipping through review. Only changed packages rebuild. And the widget extension reuses `Models` and `DesignSystem` without copying code.

### 2.3 Feature isolation: how features talk without importing each other

| Kind | Packages | Role |
|---|---|---|
| **Foundation** | `Models`, `AudioEngine`, `Env`, `DesignSystem`, `Routing` | Data, audio, services, UI building blocks, navigation contract |
| **Feature** | `Onboarding`, `SleepSession`, `Statistics`, `Recordings`, `Settings`, `Personalization`, `Learn` | One part of the app each |

A feature may import foundation packages, never another feature. **The compiler enforces this through the manifests:** `Packages/Statistics/Package.swift` lists only `Models`, `Env`, `Routing`, `DesignSystem` and Factory, so `import Recordings` in a Statistics file fails with "no such module".

**Features communicate through routes.** The Statistics calendar opens the session-detail screen, which lives in Recordings. Statistics doesn't refer to that screen; it navigates to a route value:

```swift
// Packages/Statistics/Sources/Views/CalendarSelectedNightView.swift
routerPath.navigate(to: .sessionDetail(id: session.id))
```

The route is a case in an enum in the leaf `Routing` package ([ADR 0001](adr/0001-routing-package.md)):

```swift
// Packages/Routing/Sources/Router.swift
public enum RouterDestination: Hashable, Sendable {
  case recordingDetail(id: UUID)
  case sessionDetail(id: UUID)
  case liveSession
  case trends
  case last7Nights
  case calendar
}
// Sheets: SheetDestination.sessionSummary, .profileEditor
```

Only the **app target** imports every feature, and it maps each route to a screen:

```swift
// SleepGuard/AppRegistry.swift
case let .sessionDetail(id):
  SessionDetailView(sessionID: id)   // from Recordings
case .liveSession:
  SleepSessionView()                 // from SleepSession
```

```
Statistics ──navigate(.sessionDetail)──► RouterDestination (Routing) ◄── AppRegistry (app) ──► SessionDetailView (Recordings)
     ✗ no import between Statistics and Recordings
```

Features also share **services** (in `Env`, resolved with `@Injected`) and **UI components** (a component used by two features moves into `DesignSystem`).

**Why it's worth it:**
1. **No tangled dependencies.** Swift packages can't have import cycles; the rule makes them impossible to start.
2. **Faster builds.** Changing Recordings rebuilds only Recordings and the app target.
3. **Contained changes.** Recordings can be rewritten completely; as long as `.sessionDetail(id:)` opens a screen, nothing else breaks.
4. **Clear ownership and reuse.** A feature depends only on foundation packages, so it can move to another target without dragging the rest along.

**The one exception: `Settings → Personalization`.** Settings embeds the profile section from Personalization. It's declared in `Settings/Package.swift` and documented in `AGENTS.md`. It points one way, so there's no cycle risk; if more edges appeared, the shared piece would move into a foundation package or behind a route.

**In one sentence:** feature packages are siblings that never import each other; they navigate through a small route package, and only the app target knows which screen each route opens.

### 2.4 Project-wide rules

Every rule below is either checked by the compiler or by CI, or it's a convention written in `AGENTS.md` / `CLAUDE.md`.

| Rule | What it means | Enforced by |
|---|---|---|
| **No ViewModels by default** | Screens that load asynchronously use `@State private var viewState: ViewState` (`.loading / .loaded / .empty / .error`); `@Query`-backed screens react to the query. Exceptions are deliberate ([§8.4](#84-where-there-is-an-observable-state-owner)) | Review |
| **Small views** | View files ≤ 200 lines (containers ≤ 100); each state is its own file; complex sections are their own `View` structs | CI: `check-view-size.py` (ratcheting allowlist, 2 entries) |
| **Services behind protocols** | Every service has a protocol in its own file next to its type (`AudioRecording.swift` beside `AudioRecorder.swift`), a `Factory<any P>` registration and a fake in `EnvTestSupport` ([ADR 0002](adr/0002-protocol-services.md)) | Compiler |
| **Views get services from `@Injected`** | Views never take a service through `init`. Non-view types with logic worth testing take collaborators as `init` parameters defaulting to the container ([§9.5](#95-project-rules-and-the-lessons-behind-them)) | CI: `check-layering.py` rule 6 |
| **No `.shared` in features** | Only the app target (the composition root) touches `X.shared` | CI: rule 4 |
| **Layering** | Non-view code doesn't import `DesignSystem` for UI chrome; `Models` and `AudioEngine` never import SwiftUI/UIKit; `Env` never imports SwiftUI | CI: rules 1–3 |
| **Navigation** | All navigation through `RouterPath` (`RouterDestination` for pushes, `SheetDestination` for sheets). Each tab owns its own path; `RouterPath` is the only object in SwiftUI `.environment` | Convention |
| **Concurrency** | Swift 6 strict concurrency; async/await only (no Combine, GCD or completion handlers); no `@unchecked Sendable` ([§7](#7-concurrency-swift-6)) | Compiler |
| **Logging** | `os.Logger` through `Log.<category>`; never `print` ([§10.3](#103-logging)) | CI: rule 5 |
| **Localization** | Every user-facing string goes through the generated `Strings` enum (source: `Localizable.xcstrings`) | CI: hardcoded-strings check + strings-in-sync check |
| **Accessibility** | Icon-only buttons are `Label(…).labelStyle(.iconOnly)`; custom-drawn views expose a label and value ([§10.4](#104-accessibility)) | Convention |
| **SwiftData schema** | Only add properties, with defaults; never remove or rename (that crashes existing installs). Every container opens through `SleepGuardSchema.container(_:)` with the migration plan | Convention + `SleepGuardSchemaTests` |
| **Design** | `designs/SleepGuard.pen` (Pencil) is the source of truth; its tokens (`bg-card #2C2C2E`, `accent #5E9CFF`, `score-green/amber/red`, `radius-card 16`, …) are mirrored in `Theme` | Review |
| **Formatting** | 2-space indentation and the `.swiftformat` rules | CI: SwiftFormat lint + pre-commit hook |

---

## 3. Packages

| Package | Files / lines | Depends on | What it does |
|---|---|---|---|
| **Models** | 22 / 1.7k | — | SwiftData `@Model`s (`SleepSession`, `SnoreEvent`, `SnoreBurst`, `RecordingGap`, `SleepStageSegment`, `UserProfile`, `LifestyleLog`, `Melody`) and the versioned schema. **The sleep score** (`SleepScore.compute`, `SleepScoreConfig`, the versioned cache). Episode merging (`displayableSnoringEpisodes`), widget snapshot types, `WidgetDeepLink`, the `Log` loggers |
| **AudioEngine** | 14 / 2.2k | Models | `AudioRecorder` (AVAudioEngine, interruptions, route changes), `TapProcessor` (the tap's thread), `SoundAnalysisDetector`, `FFTAnalyzer`, `SnoreDetector` (per-sample classifier), `SpeechDetector`, **`DetectionStateMachine`** (the event rules) run by the **`DetectionEngine` actor**, the raw-log format (`RawLog`), `EventClipCompressor` (.caf → .m4a), `AudioClipExtractor`. No UI imports |
| **Env** | 37 / 3.8k | Models, AudioEngine, Factory | The services and the DI `Container`. `Session/`: `SessionManager` (facade), `SessionRecordingController` (lifecycle), `RealtimeDetectionTracker` (feeds the detection engine, performs its outputs), `SessionCommitter` (saves a finished night). Also `UserPreferences`, `AppConfig`, `HealthKitSync`, `SnoreInterrupterPlayer`, `SessionCheckpointStore`, `PendingSessionStore`, `SessionRawLogWriter` (actor), `StorageLimitEnforcer`, `TabCoordinator`, `WatchConnectivityManager`. `EnvTestSupport` holds the fakes. No SwiftUI |
| **DesignSystem** | 30 / 2.2k | Models, Factory | `Theme` tokens, shared components (`SleepScoreGauge`, `SnoringTimelineView`, `SessionStatsGrid`, `StatCard`, charts), the generated `Strings.swift` and `Localizable.xcstrings` |
| **Routing** | 1 / 0.05k | — | `RouterDestination`, `SheetDestination`, `RouterPath` |
| **Onboarding** | 7 / 0.7k | Models, AudioEngine, Env, DesignSystem | First-run flow and permission requests |
| **SleepSession** | 30 / 2.1k | Models, AudioEngine, Env, Routing, DesignSystem | Recording: pre-start (delay timer, Snore Interrupter), bedside clock with live level, session summary |
| **Statistics** | 26 / 1.7k | Models, Env, Routing, DesignSystem | Home tab: dashboard (`DashboardState`), calendar, trends (Swift Charts), Last 7 Nights |
| **Recordings** | 41 / 3.8k | Models, Env, Routing, DesignSystem | Largest feature: sessions list, session detail (`SessionDetailModel`), event timeline, clip player (`ClipPlaybackController`, with optional "enhanced audio"), sharing, **PDF report** |
| **Settings** | 12 / 1.0k | Models, Env, Routing, DesignSystem, **Personalization** | Sensitivity, appearance, HealthKit, melodies, storage limits, data management, debug tools |
| **Personalization** | 15 / 1.6k | Models, Env, DesignSystem | `BriefingEngine` (pure: sessions + `now` → morning briefing), `QuoteBank`, profile editor, lifestyle surveys |
| **Learn** | 2 / 0.2k | Models, Env, Routing, DesignSystem | Learn tab (web content), behind the `feature_learn` remote flag |

**App target (`SleepGuard/`)** is the composition root: `SleepGuardApp` (container, launch tasks, onboarding gate), `MainTabView` / `CustomTabBarView` (iOS 26 system tab bar, custom one below), `AppRegistry` (route → screen), `DeepLinkRouter` (`sleepguard://start | session/<uuid> | last7nights`), `RemoteConfig/RemoteConfigLoader` (the **only** Firebase-aware code), `PushNotifications/` and `WidgetSnapshotWriter`.

**Widget extension (`SleepGuardWidgets/`)**: Last Night (small, medium, Lock Screen), 7-Night Trend and Start Tracking. It reads `widget-snapshot.json` from the App Group and never opens SwiftData (24 MB peak measured on the simulator, against a ~30 MB budget).

### 3.1 External dependencies

| Dependency | Used by | Why |
|---|---|---|
| `hmlongco/Factory` 3.5.2 (`FactoryKit`) | Env, DesignSystem, every feature package | Compile-time-safe DI container, `@Injected` |
| `firebase/firebase-ios-sdk` 12.14 (Remote Config, Crashlytics, Analytics, Messaging) | App target only | Feature flags, crash reports, push. Kept out of the packages on purpose |
| Apple frameworks | — | SwiftUI, SwiftData, Swift Charts, AVFoundation, SoundAnalysis, Accelerate, HealthKit, WidgetKit, UserNotifications, os |

There are no other third-party libraries. The app's `Package.resolved` is committed, so CI builds exactly these versions.

### 3.2 Where the core logic lives

**`AudioEngine` *hears*, the detection engine *decides*, `Models` *scores and stores*.**
- **`AudioEngine`** is the reason the app exists: it turns microphone input into "was that a snore, and how loud?". Every number the user sees comes from its output, and it holds the hardest code (the audio tap under Swift 6, the classifier, the detection rules).
- **`DetectionStateMachine`** (in AudioEngine) is the brain: it turns 20 classified samples per second into events (debouncing, bursts, melody gaps, false-positive filters). It's a pure value type, so it's tested without audio.
- **`Models`** is the foundation: everything depends on it, and it holds the score formula and the schema rules that keep existing installs from crashing.

---

## 4. A night, end to end

```
User taps Start ─► SleepSession UI ─► SessionManager (Env)
                                          ├─ SessionRecordingController  start/stop, AVAudioSession (.measurement), checkpoints
                                          └─ RealtimeDetectionTracker    every 50 ms: classify → AsyncStream → DetectionEngine actor
                                                                         (pure DetectionStateMachine) → outputs performed on main actor
                                                     ▲
AudioRecorder (AudioEngine) ─ tap ─► TapProcessor ───┤ RMS dB, peak dB, FFT spectral score
                                     SoundAnalysis ──┘ snore / speech confidence
                                          │
                                          ▼
                     per-event .caf (written live) ─► compressed .m4a (+ spectral features)

Stop ─► finish detection (flush the stream) ─► stop audio ─► await clip compression
     ─► Save: summary sheet (or automatically after a low-battery stop)
     ─► SessionCommitter: insert events + session ─► cache score ─► save
                          ─► clear pending-file record + checkpoint ─► storage limits, HealthKit write

App launch ─► refresh stale cached scores ─► widget snapshot JSON (App Group) ─► WidgetCenter reload
App to background ─► widget snapshot JSON ─► WidgetCenter reload
```

**Saving has one owner.** `SessionCommitter` (Env) is the only code that saves a finished night; both the summary sheet and the low-battery auto-save call it. Before it existed, the two paths were copies, and the low-battery copy skipped the cleanup, so a saved night's clips could be deleted at the next launch.

**Crash safety.**
- `SessionCheckpointStore` atomically writes a recovery snapshot during recording, so a night killed at 4 a.m. can be restored and saved.
- `PendingSessionStore` lists the night's files (event clips, the raw log) and deletes them if the session is never saved.
- Both are cleared only after a successful save.

**Failures are visible.** If recording can't start (microphone busy, audio session error), the pre-start and countdown screens show "Couldn't Start Recording". Failures on data paths (checkpoint writes, clip compression, storage cleanup) are logged ([§10.3](#103-logging)).

---

## 5. Snore detection

### 5.1 Where to find it

| Piece | Where |
|---|---|
| Per-sample classifier | `SnoreDetector.classify(db:spectralScore:snoreConfidence:)` → `classifyWithSoundAnalysis`, `classifyWithSpectral` (AudioEngine) |
| Apple ML classifier wrapper | `SoundAnalysisDetector` (AudioEngine) |
| FFT spectral score | `FFTAnalyzer.analyze` (AudioEngine) |
| Audio tap | `TapProcessor`, `AudioRecorder` (AudioEngine) |
| **Event rules** | `DetectionStateMachine.ingest(_:at:)`, `melodyDidStart/Stop`, `finalizeActiveEvents` (AudioEngine) |
| Runs the rules, in order | `DetectionEngine` actor (AudioEngine), [ADR 0003](adr/0003-detection-actor.md) |
| Sampling, sensitivity presets, side effects | `RealtimeDetectionTracker` (`apply(_:)`, `perform(_:generation:)`), Env |
| Replay tests | `Packages/AudioEngine/Tests/Fixtures/Replay/` (excerpts of a real recording + golden outputs) |
| Full write-up | [`docs/snore-detection-algorithm.md`](snore-detection-algorithm.md) |

### 5.2 How it works

1. **Capture.** An AVAudioEngine tap delivers ~1024-frame buffers (about 47 per second at 48 kHz; Apple may choose another size). For each buffer `TapProcessor` computes RMS dB, peak dB and an FFT spectral score, writes the audio to the open event file, and SoundAnalysis updates its snore and speech confidences.
2. **Sample.** Every **50 ms** (20 Hz) the tracker reads the latest values and classifies them. That fixed rate is what the event rules see.
3. **Classify each sample** (`SnoreDetector.classify`):
   - **SoundAnalysis first.** If snore confidence is below the sensitivity's confidence gate → `.none`. Otherwise **peak dB** picks the tier: ≥ epic threshold *and* high confidence → **epic**; ≥ loud → **loud**; ≥ light → **light**; ≥ quiet → **quiet**. Below every dB floor, a strong confidence still gives **quiet**.
   - **FFT fallback (implemented, off in live detection).** Spectral score = `0.7 × ratio score (energy in 100–500 Hz) + 0.3 × centroid score (centroid below ~400 Hz)`; under 0.6 is rejected, and a weaker score raises the dB thresholds. The tracker currently passes `spectralScore: 0`, so live detection uses SoundAnalysis only, until a real night validates the fallback. Raw logs and events still record the real spectral score.
   - **Raw dB alone is never used**: breathing, traffic and bed creaks would count as snoring.
4. **Group samples into events** (`DetectionStateMachine`, on the `DetectionEngine` actor):
   - Samples, melody start/stop, settings changes and session end arrive through **one ordered `AsyncStream`**, each timestamped at its source, so a melody stop that happened between two samples is applied between them.
   - An event **starts** once a snore run has lasted **75 ms** (3 samples at 20 Hz). Thresholds are durations, so they survive a change of sampling rate. The event starts at the run's first sample.
   - Continuous snoring inside an event is stored as **bursts**.
   - An event **closes after 10 s without snoring**. Pauses under 10 s are breathing between snores, so snoring time is **epoch time** (first to last snore), the same definition as validated apps (Chiang et al., 2021).
   - **False-positive filters:** a minimum event length per sensitivity (2 s / 1 s / 0.5 s), and events under 3 s must pass the high-confidence gate (or, without ML, a spectral score ≥ 0.65).
5. **Snore Interrupter (optional melody).** When snoring is confirmed, the mic pauses and a melody plays. The event stays open; afterwards the rules wait 3 s, and the gap counts as snoring only if snoring resumes (`RecordingGap.snoringResumed`). Only the player knows whether the melody actually started (muted, set to "never", missing file), so it reports back into the stream and the engine applies that before the next queued sample.
6. **Audio.** Each event writes its own `.caf` live, compressed to `.m4a` when the event closes. A full-night recording exists only with the Debug "preserve raw audio" setting.
7. **Sleep talking** (opt-in setting) runs in parallel: speech-like SoundAnalysis classes (25 identifier patterns, such as speech, whisper, mumble, groan, laugh, baby babble) through `SpeechDetector`. When snoring starts, an open speech event ends: snoring has priority.

**Sensitivity** (user setting, `RealtimeDetectionTracker.apply(_:)`; levels are relative dBFS from the phone mic, not calibrated dB SPL):

| | quiet / light / loud / epic (dBFS) | confidence gate / high / quiet fallback | min event |
|---|---|---|---|
| Low (noisy room) | −45 / −35 / −15 / −5 | 0.45 / 0.65 / 0.55 | 2.0 s |
| **Medium (default)** | −50 / −40 / −20 / −10 | 0.35 / 0.55 / 0.45 | 1.0 s |
| High (quiet room) | −55 / −45 / −25 / −15 | 0.25 / 0.45 / 0.35 | 0.5 s |

**How changes are kept safe:** the rules are a pure state machine with unit tests, 13 characterization tests through the live tracker, and **replay tests** that feed excerpts of a real recording through the machine and the actor (under three delivery patterns) and compare against golden outputs. Changing detection output means re-recording the goldens on purpose (`scripts/record-replay-goldens.sh`) and explaining the diff.

---

## 6. Sleep score

### 6.1 Where to find it

| Piece | Where |
|---|---|
| **Formula (pure)** | `SleepScore.compute(_ inputs: SleepInputs, config:)` in `Packages/Models/Sources/Data/SleepScore.swift` |
| **Coefficients and caps** | `SleepScoreConfig.default` in `SleepScoreConfig.swift` |
| Inputs from a stored session | `SleepSession.sleepInputs` (`snoringDuration`, `displayableSnoringEpisodes`, `stageStats`) in `SleepSession.swift` |
| Cache and launch refresh | `refreshCachedScore(using:)`, `refreshStaleCachedScores(in:config:)` in `SleepScoreCache.swift` |
| Debug override | `AppConfig.setSleepScoreConfigOverride(_:)` (Debug builds only; Release always uses the defaults) |
| Full write-up | [`docs/sleep-score-calculation.md`](sleep-score-calculation.md) |

### 6.2 The formula

The score starts at **100**, and **independently capped penalties** are subtracted. Each penalty is truncated to an integer on its own. The score never goes below 0, and a zero-length session scores 100.

```
score = max(0, 100 − snoring − events − intensity − sleepTalking − stages − shortSleep − longSleep)
```

| Penalty | Formula (`SleepScoreConfig.default`) | Cap | What it measures |
|---|---|---|---|
| **Snoring** | `snoring % of the night × 0.85` | 75 | How much of the night you snored (the dominant factor). Snoring time = events plus melody gaps where snoring resumed |
| **Events / hour** | `snoring episodes per hour × 2.5` (events within 5 min merge into one episode) | 25 | How fragmented the night was |
| **Intensity** | `light share × 10 + loud share × 20 + epic share × 40`, shares (0–1) of *measured* burst time | 30 | How loud the snoring was |
| **Sleep talking** | `talking % × 0.35 + talking events per hour × 0.8` (only if there are any) | 15 | Weighted below snoring |
| **Sleep stages** | `(15 − deep %) × 0.6 + (18 − REM %) × 0.4 + (awake % − 8) × 1.0`, negative parts count as 0 (only with Watch data) | 15 | Targets from the sleep literature: deep ≥ 15 %, REM ≥ 18 %, awake ≤ 8 % |
| **Short sleep** | `(6 h − hours) × 2` (not applied to sessions under 3 h) | 8 | Short nights, without punishing naps or tests |
| **Long sleep** | `(hours − 9 h) × 1` | 5 | Very long nights |

**Worked example (8 h night):** 20 % snoring → **17**; 4 episodes → 0.5/h × 2.5 → **1**; bursts half light, half loud → 0.5 × 10 + 0.5 × 20 → **15**; 6 talking events totalling 10 min → 2.08 % × 0.35 + 0.75/h × 0.8 → **1**; deep 12 %, REM 15 % → 1.8 + 1.2 → **3**. **Score = 100 − 37 = 63.**

### 6.3 Design decisions

- **The coefficients are product heuristics, not a clinical measure.** Only the stage targets come from the sleep literature, and the code says so.
- **Caps per penalty**, so one bad factor can't hide the others, and each part stays explainable.
- **Intensity is measured against detected burst time**, not the whole night: there's no intensity data during melody gaps, so those gaps aren't penalized.
- **A pure function on plain values.** `SleepScore.compute` takes a `SleepInputs` value, so it's tested with parameterized cases and no SwiftData container.
- **Versioned cache.** Lists, widgets and stats read `cachedSleepScore` and never fault in the `events` relationship (that crashed in production). The cache stores a fingerprint of the formula version and the config; a coefficient change makes it stale, and a launch pass recomputes stale scores. The cache is written after `insert` (SwiftData ignores changes made before insertion) by `SessionCommitter`, by `SessionDetailModel` when HealthKit stages arrive, and by the launch pass.
- **Data and calculation are separate.** `SnoreEvent` stores both `duration` (epoch) and `bursts` (net snoring), so the formula can change without migrating data. With the Debug raw-log setting, every classified sample is logged, so thresholds can be re-tuned against past nights.

---

## 7. Concurrency (Swift 6)

| Setting | Value |
|---|---|
| Language mode | Swift 6 (app: `SWIFT_VERSION 6.0`; packages: `.swiftLanguageMode(.v6)`) |
| Strict concurrency | `complete` |
| Default isolation | App target: `MainActor` (`SWIFT_DEFAULT_ACTOR_ISOLATION`). The 8 UI packages: `.defaultIsolation(MainActor.self)`. `Models`, `Env`, `AudioEngine`: no default, explicit `@MainActor` on every `@Observable` service (the annotations are load-bearing) |
| Escape hatches | No `@unchecked Sendable`, no `nonisolated(unsafe)`. One `OSAllocatedUnfairLock(uncheckedState:)` in `TapProcessor` (below) |

**Where work runs:**
- **Main actor:** UI, services, SwiftData, and the side effects of detection (event files, saves, the melody).
- **`DetectionEngine` actor:** the detection rules, fed by one ordered `AsyncStream`. It awaits each batch of outputs before the next message, so a slow main actor slows the engine but never reorders it ([ADR 0003](adr/0003-detection-actor.md)). The stream is unbounded on purpose: dropping a "melody stopped" or "session ended" message would corrupt a session.
- **`SessionRawLogWriter` actor:** appends the Debug raw log to disk in chunks while recording.
- **The audio tap's thread:** Apple documents only that the tap block runs on a thread other than the main thread. Under Swift 6, a tap closure written inside the `@MainActor` recorder would inherit main-actor isolation and trap there. So the closure is `@Sendable` and everything it touches lives in `TapProcessor`, a `Sendable` type whose mutable state is behind an `OSAllocatedUnfairLock`.
- **Apple delegates** (SoundAnalysis results, `AVAudioPlayerDelegate`, WatchConnectivity) are `nonisolated`: they parse their payload synchronously and hop to the main actor with `Task { @MainActor in … }` only to mutate state.

---

## 8. State: why there are no ViewModels

### 8.1 In short

On iOS 17+, SwiftUI with Observation already does what a ViewModel used to do: it holds state and re-renders exactly the views that read the state that changed. So screen state lives in the view as a `ViewState` enum, business logic lives in services and pure functions that can be unit-tested, and shared state lives in `@Observable` services from the DI container. A ViewModel per screen would mostly duplicate that and fight SwiftUI's own tools (`@Query`, `.task`). It's a default, not a dogma: when a screen owns an imperative resource or a lot of state, it gets an `@Observable` state owner. The community name for this is **MV (Model–View)**, as in IceCubesApp.

### 8.2 Why MVVM existed and what changed

MVVM came to iOS in the UIKit era: views were long-lived mutable objects, there was no data binding, and view controllers grew huge. The ViewModel gave presentation logic a home and a binding layer (KVO, RxSwift, later Combine).

SwiftUI removed both problems. **A view is a cheap value-type description of state**, rebuilt whenever its inputs change. And **SwiftUI is the binding layer**: with Observation (WWDC23, iOS 17), it records which properties `body` reads and re-evaluates the view only when those change. Before that, `ObservableObject` + `@Published` re-rendered on any published change, which is one reason people wrapped everything in ViewModels.

### 8.3 The reasons, with examples from this codebase

| # | Reason | In SleepGuard |
|---|---|---|
| 1 | **Observation makes a ViewModel layer redundant.** The view already reacts precisely to the state it reads. | Shared services are `@MainActor @Observable`; views read them through `@Injected` |
| 2 | **SwiftUI's best tools only work inside views.** `@Query`, `@Environment`, `.task` (auto-cancelled) and `withAnimation` would have to be re-implemented in a ViewModel. | `StatisticsDashboardView` (68 lines) uses `@Query` and maps sessions to a `ViewState` with the pure `DashboardState.make(from:now:calendar:)` |
| 3 | **What people want from a ViewModel is explicit state, and an enum gives that** without a class: loading *and* error can't both be true. | `StatisticsDashboardView.ViewState`: `.loading / .empty / .loaded(DashboardState) / .error` |
| 4 | **Logic isn't in views; it's in testable units.** Pure functions are easier to test than a ViewModel: no mocks, no main actor. | `SleepScore.compute`, `DetectionStateMachine`, `SnoreDetector.classify`, `DashboardState.make`, `BriefingEngine.generate` (30 tests, `now` passed in), `WidgetSnapshotBuilder` |
| 5 | **Fewer lifecycle traps.** `@State` + `.task {}` ties loading to the view's identity and cancels it for free. | Rule: `.task` for loading, `.task(id:)` when it depends on a value, check `Task.isCancelled` before setting an error |
| 6 | **Simpler dependency injection.** Factory's `@Injected` and the `@Observable` macro collide, so every ViewModel would need manual container resolution. | Views write `@Injected(\.service)` |
| 7 | **Simpler Swift 6 concurrency.** Fewer `@MainActor` reference types to reason about. | UI packages are main-actor by default |
| 8 | **Rules a coding agent can follow.** "ViewState enum in the view, logic in services" is easy to enforce consistently. | The rule is in `AGENTS.md`; the vendored `swiftui-view-refactor` skill also recommends MV |

### 8.4 Where there *is* an observable state owner

The rule is "no ViewModel **by default**". Two deliberate exceptions:

| Type | Why it exists |
|---|---|
| `Recordings/Sources/Helpers/SessionDetailModel.swift` | Session detail had a lot of state and side effects (loading with the cached-score refresh, the event filter, deletion). It was introduced when `SessionDetailView` was split from 507 lines to 128. It owns a `ViewState`, doesn't import `DesignSystem`, and is unit-tested: isolated stores through `init`, a fake HealthKit through the container |
| `Recordings/Sources/Helpers/ClipPlaybackController.swift` | Owns an `AVAudioEngine` + player node + EQ: a long-lived imperative resource with timers and callbacks, which doesn't fit in a value-type view. The view holds it in `@State` |

**Rule of thumb:** add an `@Observable` object when the state owns an imperative resource, or when a screen's state and side effects are too big for the view to stay under 200 lines; never one per screen by reflex. Only 3 screens declare a `ViewState` enum; most read `@Query` directly and have no loading phase to model.

### 8.5 Trade-offs: when MVVM would be the better choice

- **Presentation logic inside a view is harder to unit test.** If a team wants to test formatting, validation or multi-step forms with mocks, a ViewModel is a reasonable home (the core of the pro-ViewModel argument).
- **Team conventions.** In a large team with UIKit/MVVM habits, or a mixed UIKit/SwiftUI codebase, consistency can matter more than idiom.
- **Risk of "massive views".** Without discipline, MV becomes MVC by another name. The guardrails here are the CI-enforced 200-line limit, state views in separate files, and logic in services.
- **Sharing presentation logic across platforms** with different views can justify a shared observable model.

For a SwiftUI-only, iOS 17+, SwiftData-backed app, MV + `ViewState` enums + services is less code, fits the framework, and stays testable.

### 8.6 FAQ

**Isn't this just MVC or massive views?** No. Views stay small (200-line limit, enforced in CI) and contain no business logic; they only turn state into UI.

**How do you test without ViewModels?** By testing the logic, not the screen glue: the score, detection, briefings, dashboard mapping and widget data are pure functions or services with unit tests.

**So `SessionDetailModel` is a ViewModel?** Functionally, for that one screen, yes, and deliberately. The rule is about not creating one per screen by default.

**Why not TCA or a Redux-style architecture?** A single-developer, local-only app doesn't need the ceremony or the dependency; `ViewState` enums give explicit states and services give separation.

### 8.7 Sources

- Thomas Ricouard (IceCubesApp), [*SwiftUI in 2025: Forget MVVM*](https://dimillian.medium.com/swiftui-in-2025-forget-mvvm-262ff2bbd2ed) and [*Migrating Ice Cubes to the Observation framework*](https://dimillian.medium.com/migrating-ice-cubes-to-the-swiftui-observation-framework-821f90deebee)
- Apple, WWDC23 [*Discover Observation in SwiftUI*](https://developer.apple.com/videos/play/wwdc2023/10149)
- Mohammad Azam, [*Is MVVM dead in SwiftUI?*](https://azamsharp.github.io/2024/01/09/is-mvvm-dead-in-swiftui.html) (pro-MV)
- Matteo Manferdini, [*Why dismissing view models in SwiftUI is stifling your app's maintainability and testability*](https://daily.dev/posts/why-dismissing-view-models-in-swiftui-is-stifling-your-app-s-maintainability-and-testability-and-th-nqz1dnx9x) (pro-MVVM counterpoint)
- [*You don't need MVVM to test SwiftUI*](https://dev.to/crisfeim/you-dont-need-mvvm-to-test-swiftui-48lk) (DEV Community)
- Apple Developer Forums, [*Stop using MVVM for SwiftUI*](https://developer.apple.com/forums/thread/699003)

---

## 9. Dependency injection with Factory

> Library: [hmlongco/Factory](https://github.com/hmlongco/Factory) 3.5, imported as `FactoryKit`. Adopted in F19 ([`docs/features/f19-factory-di.md`](features/f19-factory-di.md)); every service put behind a protocol in F22 ([ADR 0002](adr/0002-protocol-services.md)).

### 9.1 The problem

Almost every screen needs shared services: `SessionManager`, `UserPreferences`, `Theme`, `HealthKitSync`, `AppConfig`, … (19 registered: 18 in `Env`, plus `Theme` in `DesignSystem`). The question is how a view gets hold of them:

| Option | Problem |
|---|---|
| The view creates it: `let prefs = UserPreferences()` | Each view gets its own copy; state isn't shared |
| The view reaches for the singleton: `UserPreferences.shared` | Hard-wired: can't be replaced in previews or tests, and the dependency is hidden |
| The parent passes it down through `init` | Every intermediate view forwards services it doesn't use ("prop drilling") |
| SwiftUI `.environment` | Works, with the pitfalls below. Used before F19 |
| **A DI container (Factory)** ✅ | One registry; any view asks for a service and the container decides which instance to return |

### 9.2 Before: SwiftUI `.environment`

Before F19, the app target injected every service into the environment at the root, and views read them with `@Environment(X.self)`. The pain points:
1. **Sheets lose the environment.** A sheet is a separate hierarchy, so every sheet had to re-inject every service.
2. **A missing injection compiles and crashes at runtime** ("No Observable object of type HealthKitSync found").
3. **Wiring grows with every service**, at the root and at every sheet.
4. **Previews need the full setup.**

### 9.3 After: Factory

`@Injected` doesn't use the SwiftUI environment at all: it reads from a global container object, `Container.shared`. A view anywhere (deep in a stack, in a sheet, in a widget) resolves the service directly.

**① Register** (`Packages/Env/Sources/Services/Container.swift`):

```swift
public extension Container {
  @MainActor var sessionManager: Factory<any SessionManaging> { self { SessionManager.shared }.singleton }
  @MainActor var userPreferences: Factory<any UserPreferencesStoring> { self { UserPreferences.shared }.singleton }
  @MainActor var healthKitSync: Factory<any HealthKitSyncing> { self { HealthKitSync.shared }.singleton }
  // … 18 protocol-typed services in Env; Theme is registered in DesignSystem
}
```

**② Resolve in views:**

```swift
struct SettingsView: View {
  @Injected(\.userPreferences) private var userPreferences
  @Injected(\.theme) private var theme
}
```

**③ Inject into testable types through `init`, defaulting to the container:**

```swift
public init(
  pendingSessionStore: any PendingSessionStoring = Container.shared.pendingSessionStore(),
  checkpointStore: any SessionCheckpointStoring = Container.shared.sessionCheckpointStore(),
  …)
```

Sheets now re-inject only `RouterPath`: `.withEnvironments()` in `AppRegistry` is one line. The F19 migration moved 91 views from `@Environment(X.self)` to `@Injected(\.x)`.

### 9.4 How Factory works

(Checked against the library source.)

- **`Container`** has one global instance, `Container.shared`, declared `@TaskLocal`. Each service is a computed property returning a `Factory<T>`: a key (the property name, via `#function`) plus a closure that builds `T`.
- **Resolving** (`Container.shared.userPreferences()`): take the lock; pick the closure (a context override such as `.onPreview`, else a runtime override from `register { }`, else the original); ask the **scope** for a cached instance or run the closure.
- **`@Injected`** is a plain property wrapper that resolves **once, when the view struct is created**. It isn't a SwiftUI `DynamicProperty` and subscribes to nothing.
- **So how does the view update?** Through **Observation**, not Factory: SwiftUI tracks which properties of which `@Observable` instance `body` reads, however the view got the reference.

| Scope | Behavior | Used here for |
|---|---|---|
| `unique` (default) | New instance on every resolve | — |
| `singleton` | One instance for the app's lifetime | Every service, plus the two internal session-composition factories |
| `cached` / `shared` / `graph` | Until reset / weak cache / per resolution chain | — |

The singleton factories return the existing `.shared` instances, so the container is a layer on top of the singletons, not a replacement.

**Overrides** for previews and tests: `Container.shared.x.register { fake }`. Because `Container.shared` is task-local, Swift Testing's `.container` trait (`FactoryTesting`) gives each test its own container, so tests with different fakes run in parallel.

### 9.5 Project rules and the lessons behind them

| Rule | Why |
|---|---|
| **Views resolve services with `@Injected`, never through `init`** | Views aren't unit-tested, and the container already swaps services for previews and tests; an `init` parameter would be a second way to do the same thing. Enforced by `check-layering.py` rule 6 (22 views used to take `theme` through `init`) |
| **Testable non-view types take collaborators through `init`, defaulting to the container** | Services, state owners and helpers are where the logic is, so tests build them with fakes directly: `SessionCommitter(pendingSessionStore: FakePendingSessionStore(), …)` |
| **`@Observable` classes never use `@Injected`; they call `Container.shared.x()` in `init`** | Both macros synthesize a `_property` backing store, so the names collide ("invalid redeclaration of synthesized property") |
| **Every service has a protocol in its own file, and a fake** | So any service can be replaced in a test with one line. The fakes live in `EnvTestSupport`; the `UserDefaults` stores use the real type on a throwaway suite (`UserPreferences.isolated()`) |
| **`RouterPath` stays in `.environment`** | Each tab needs its own navigation stack, which is exactly what environment scoping gives. In the container, `unique` scope gave each view a disconnected path and `shared` scope let the path deallocate |
| **`ModelContext` stays in `.environment(\.modelContext)`** | It belongs to SwiftData's own plumbing |
| **`Theme` is registered in DesignSystem** | Env doesn't depend on DesignSystem (and DesignSystem doesn't depend on Env); each package extends `Container` with its own services |
| **Isolation on the factory** | `@MainActor` factories for main-actor services; plain ones for `SessionRawLogWriter` (an actor) and `StorageLimitEnforcer` (`Sendable`). The compiler checks isolation wherever a service is resolved |
| **The app target holds `.shared` directly and doesn't link FactoryKit** | It's the composition root, the one place that knows concrete instances |

### 9.6 Pros and cons

**Pros:**
- **No runtime crash for a missing service:** every key path needs a default closure, so an unregistered service is a compile error.
- **Sheets and deep views just work**, with no hierarchy to fall out of.
- **One file lists every service**, and adding one is one line.
- **Overrides for previews and tests**, isolated per test.
- **Lazy creation**, Swift 6 isolation per factory, and a small, widely used library.

**Cons and trade-offs:**
- **Service-locator criticism:** a view's dependencies aren't in its `init` signature; you read the `@Injected` lines. Everything is still replaceable from outside, which is the property that matters.
- **Global state:** `Container.shared` is global (tests isolate it per task).
- **`@Injected` resolves when the view struct is created**, which SwiftUI does often. For singletons that's a cheap cached lookup, but not free.
- **Two resolution styles** (property wrapper in views, `Container.shared` in `@Observable` classes) because of the macro collision.
- **Doesn't fit per-subtree state** like `RouterPath`, so the project also uses the environment.
- **Protocols with one production conformer:** 19 protocols and 16 fakes to keep in step, existential dispatch (`any P`), and a wide `ThemeProviding` (41 members) that tests rarely replace. ADR 0002 records these costs.
- **A third-party dependency** in most packages. Factory 3 renamed its module, so major upgrades have a cost.

### 9.7 Factory vs the alternatives

| | SwiftUI `.environment` | Factory | Swinject / Resolver | `swift-dependencies` | Manual init injection |
|---|---|---|---|---|---|
| Missing dependency | Runtime crash | **Compile error** | Runtime crash | Compile error | Compile error |
| Works in sheets without re-injection | ❌ | ✅ | ✅ | ✅ | n/a |
| Per-subtree values (navigation) | ✅ best fit | ❌ | ❌ | ⚠️ via scoping | ✅ |
| Boilerplate | Root + sheet wiring | 1 line per service | Registration code + keys | Key type + extension | Every `init` on the path |
| Third-party | No | Yes (small) | Yes | Yes (TCA ecosystem) | No |

**Why Factory here:** compile-time safety like manual injection, with far less boilerplate. It removes the environment's sheet-crash class of bugs, and it leaves the environment for what it's best at: navigation per tab.

---

## 10. Quality: tests, CI, logging, accessibility, privacy

### 10.1 Tests

**277 Swift Testing tests in 8 packages**, run on every pull request:

| Package | Tests | Highlights |
|---|---:|---|
| Models | 79 | Sleep score formula (parameterized) and versioned cache, episodes, stats, widget snapshot, crash-recovery snapshot, schema migration plan |
| AudioEngine | 65 | `DetectionStateMachine` (18), `DetectionEngine` actor under three delivery patterns, **replay against goldens from a real recording**, raw-log formats (incl. a crash-truncated file), classifier, FFT, tap levels, clip extraction |
| Env | 59 | Detection characterization through the live tracker (13), saving a night (`SessionCommitterTests`, incl. the low-battery regression), every service replaced by its fake, constructor injection, storage limits, checkpoints, raw-log writer |
| Personalization | 30 | `BriefingEngine` (pure, `now` injected) |
| Statistics | 18 | `DashboardState` mapping, week-over-week trend |
| Recordings | 16 | `SessionDetailModel` (load, filter, delete) with a fake HealthKit, session grouping |
| DesignSystem | 7 | Formatters, localization catalog, theme override |
| Routing | 3 | `RouterPath` |

Learn, Onboarding, Settings and SleepSession have no test target (views and thin wrappers). Tests run per package on the iOS Simulator with `scripts/run-tests.sh` (not `swift test`, which builds for macOS). Mutation checks were used on the critical tests: breaking the code they protect makes them fail.

### 10.2 CI and guardrails

| Check | Where | Fails when |
|---|---|---|
| **Tests** | `.github/workflows/tests.yml` → `scripts/run-tests.sh` | Any package test fails (PRs + manual runs, `macos-26`, newest Xcode 26) |
| **App build** | `tests.yml`, `app` job | The app + widget fail to build in **Release** with the committed `Package.resolved` (`-disableAutomaticPackageResolution`). Release because that's what Archive uses: a build-phase cycle once broke only Release |
| **Layering** | `layering.yml` → `scripts/check-layering.py` | (1) non-view code imports `DesignSystem`; (2) `Models`/`AudioEngine` import SwiftUI/UIKit; (3) `Env` imports SwiftUI; (4) a feature uses a service's `.shared`; (5) a `print(`; (6) a view stores a service passed through `init` |
| **View size** | `layering.yml` → `scripts/check-view-size.py` | A view file over 200 lines, an allowlisted file growing past its ceiling, or a stale allowlist entry |
| **SwiftFormat** | `quality.yml` (SwiftFormat 0.55, built from source in a `swift:6.0.3` container) | Code isn't formatted per `.swiftformat` |
| **Hardcoded strings** | `quality.yml` → `scripts/check-hardcoded-strings.py` (diff-based) | `Text("Save")` instead of `Strings.…` |
| **Strings in sync** | `quality.yml` | `Localizable.xcstrings` and the generated `Strings.swift` disagree |
| **Pre-commit hook** | `.githooks/pre-commit` (`sh scripts/install-hooks.sh`) | Formats staged Swift files |

### 10.3 Logging

- **`os.Logger`, never `print`.** `Log.<category>` in `Models/Sources/Helpers/Log.swift`, subsystem `com.dardan.SleepGuard`, categories `audio`, `detection`, `session`, `interrupter`, `storage`, `playback`, `app`.
- **Levels:** `.debug` for traces (not persisted), `.info` milestones, `.notice` notable state, `.error` failures, `.fault` for the should-never-happen case (the SwiftData store failing to open).
- **Privacy:** interpolated strings are private by default (file names, melody names, the push token); error descriptions are public so a sysdiagnose is useful.
- **Signposts:** an Instruments interval per session and per snore event (Points of Interest).
- Logger interpolations are autoclosures, so instance properties need `self.`; `.swiftformat` keeps it via `--selfrequired`.

### 10.4 Accessibility

- **VoiceOver:** icon-only buttons are `Label(title, systemImage:).labelStyle(.iconOnly)` (16 of them); the score gauge reads "Sleep score, 82 out of 100"; stat cards read as one element (title, value); the `Canvas`-drawn snoring timeline and sleep-stage chart expose a spoken summary; decorative visuals are hidden. Spoken strings live under `a11y.*`.
- **Not done yet:** Dynamic Type (font sizes are fixed to the design tokens) and 44 pt minimum tap targets (some are 12 × 16 pt). Both need design decisions.

### 10.5 Privacy

- On-device only: no accounts, no user-data servers, audio never leaves the phone.
- **Privacy manifests:** the app declares its required-reason APIs (`UserDefaults` CA92.1, file timestamps C617.1, system boot time 35F9.1) with tracking off; the widget declares `UserDefaults`. Firebase and Factory ship their own manifests.
- HealthKit data stays in HealthKit and the local store; analytics events aren't logged.

---

## 11. How the project is built: workflow and AI agents

The project is built with AI coding agents (Claude Code, plus agents that read `AGENTS.md`), but **the human owns the architecture, the reviews and the guardrails**; the agent works inside a tightly specified box.

### 11.1 Planning: features and tasks

- Every **feature** has an ID (F1–F23), a priority, a tracker in [`docs/trackers/`](trackers/) and a row in [`docs/FeatureTracker.md`](FeatureTracker.md) (dashboard, activity log, what's active, what's next).
- Features split into **tasks** (`F22-T10`) with dependencies and acceptance criteria. The local tracker is updated first; earlier features were also mirrored to Notion.
- A finished feature gets a doc in [`docs/features/`](features/) (files, routes, state, edge cases). Decisions with real trade-offs get an [ADR](adr/).

### 11.2 The per-task loop

```
BEFORE CODING   tracker → task "In Progress"
IMPLEMENTATION  read the relevant rules → build → verify (zero errors, tests, simulator)
AFTER VERIFIED  tracker → "Done", acceptance criteria ticked, prompt recorded, session note written
```

### 11.3 Git

- One task, one branch (`feature/f22/t10-detection-engine-actor`), merged into a feature branch, which merges into `main`.
- Commit messages: `F22-T10 — DetectionEngine actor fed by one ordered AsyncStream`, followed by bullet points.
- **Conflict-free session log:** each session adds its own file in [`docs/sessions/`](sessions/) (89 so far) instead of appending to a shared file; `scripts/compile-sessions.py` numbers them when compiling.

### 11.4 Instruction files, skills and tools

| What | Purpose |
|---|---|
| [`AGENTS.md`](../AGENTS.md) / [`CLAUDE.md`](../CLAUDE.md) | The rulebook (identical apart from the agent's name): behavior principles (state assumptions, simplicity first, surgical diffs), design compliance, localization, SwiftUI / DI / concurrency rules, view limits, schema rules, the workflow, build commands and the required end-of-session handoff |
| Per-topic architecture notes and the full workflow playbook | Kept locally (not in the repository); the rulebook tells the agent to load only the note a task needs, which keeps context small |
| Skills (`.claude/skills/`, pinned commits) | `swiftui-expert-skill` (AvdLee), `swiftui-view-refactor` and `swiftui-performance-audit` (Dimillian). Project rules win on conflicts |
| MCP tools | **XcodeBuildMCP** (build, run, test, screenshot on a simulator pinned by UDID in `.xcodebuildmcp/config.yaml`), **Pencil** (read the design file), **ios-simulator** (UI inspection), **apple-docs** (current APIs), **Notion** |

### 11.5 Why this works

1. **Context is engineered:** a rulebook, small per-topic notes, and a tracker that says where the project is.
2. **Every task is verifiable:** acceptance criteria, a clean build and passing tests before it counts as done.
3. **Machines check the rules:** CI applies the same checks to agent-written and human-written code.
4. **Handoffs are written down:** session notes, feature docs and trackers let any new session pick up cold.
5. **Big changes are staged:** the Swift 6 migration was 16 tasks, one package at a time from the bottom layer up; the Factory migration piloted on one package before 91 views.

---

## 12. Build and run

```bash
# Build and run (Xcode 26+)
xcodebuild -project SleepGuard.xcodeproj -scheme SleepGuard \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build

# What CI builds: Release, unsigned, pinned dependencies
xcodebuild build -project SleepGuard.xcodeproj -scheme SleepGuard -configuration Release \
  -destination 'generic/platform=iOS Simulator' -disableAutomaticPackageResolution CODE_SIGNING_ALLOWED=NO

# Tests and checks
sh scripts/run-tests.sh                   # all package tests on the simulator (or: sh scripts/run-tests.sh Models Env)
python3 scripts/check-layering.py         # rules 1–6
python3 scripts/check-view-size.py
python3 scripts/generate-xcstrings.py     # Strings.txt → Localizable.xcstrings → Strings.swift

# Demo data (Debug builds): launch with -generateMockData
# Deep links
xcrun simctl openurl booted sleepguard://last7nights
xcrun simctl openurl booted sleepguard://start

# Live logs (or Console.app for a device)
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.dardan.SleepGuard"' --level debug
```

Real recording needs a physical device; the simulator uses the Mac's microphone, which is enough for a demo.

---

## 13. Decisions, history and open items

### 13.1 Architecture decision records

| ADR | Decision |
|---|---|
| [0001](adr/0001-routing-package.md) | Navigation in a leaf `Routing` package, so the service layer is SwiftUI-free |
| [0002](adr/0002-protocol-services.md) | Every service behind a protocol, with a test double |
| [0003](adr/0003-detection-actor.md) | Detection rules on an actor fed by one ordered `AsyncStream` |

Each ADR records the context, the decision, the consequences including its honest limits, and the alternatives considered.

### 13.2 Recent hardening (F22–F23)

An architecture review in November 2026 questioned several parts of the design. F22 addressed the structural points, and F23 made the app safer to ship ([`docs/features/f22-architecture-hardening.md`](features/f22-architecture-hardening.md)):

| Concern | Change |
|---|---|
| Score formula inside a `@Model`; cache stale after a coefficient change | Pure `SleepScore.compute(SleepInputs, config:)`; cache stamped with a formula/config fingerprint and refreshed at launch |
| Navigation types in the service layer | Leaf `Routing` package (ADR 0001) |
| Services couldn't be faked | A protocol per service, fakes in `EnvTestSupport`, no `.shared` in features (ADR 0002) |
| Detection ordering held only by accident | Pure `DetectionStateMachine` on a `DetectionEngine` actor, one ordered stream, replay tests from a real recording (ADR 0003) |
| No schema migration path | `VersionedSchema` V1 + migration plan |
| Saving a night duplicated in two views, which had drifted (low-battery nights lost their clips) | One `SessionCommitter`, with a regression test |
| Shipping hygiene | Privacy manifests, `os.Logger` + signposts, failures on data paths logged, pinned dependencies, Release build fixed and built in CI, mock data Debug-only |
| Debug raw log held all night in memory, lost on a crash | Written while recording (JSON Lines) |
| Silent start failures | "Couldn't Start Recording" alert |
| Accessibility | VoiceOver labels and summaries |
| Two ways to inject services into views | Views: `@Injected` only; logic types: `init` injection |

The lesson worth keeping: the structural concerns were cheap to fix once the rules were pure functions with tests around them. The most serious finding was a data-loss bug caused by duplicated save logic.

### 13.3 Open items

- **Detection accuracy.** The replay tests prove detection didn't *change*, not that it's *right*. Next: measure precision and recall against labelled real nights.
- **A real night on a device** for the detection actor (verified so far by replay and on the simulator).
- **Dynamic Type and tap targets** (design decisions).
- **A start-failure alert when recording starts from the notification** (that path only logs today).
- **CloudKit sync** (F13, not started): it needs the first breaking schema migration (dropping `@Attribute(.unique)`).

---

## 14. Further reading

| Document | What's in it |
|---|---|
| [`README.md`](../README.md) | Product overview, features, quick architecture summary |
| [`docs/snore-detection-algorithm.md`](snore-detection-algorithm.md) | Detection in depth: classifier layers, event lifecycle, melody gaps, audio files, raw log |
| [`docs/sleep-score-calculation.md`](sleep-score-calculation.md) | Every score penalty with examples |
| [`docs/adr/`](adr/) | Architecture decision records |
| [`docs/features/`](features/) | One document per shipped feature: files, routes, state, edge cases |
| [`docs/FeatureTracker.md`](FeatureTracker.md), [`docs/trackers/`](trackers/) | Feature and task status, acceptance criteria, notes |
| [`docs/sessions/`](sessions/) | One note per working session |
| [`AGENTS.md`](../AGENTS.md) | The project rulebook |
| [`Packages/AudioEngine/Tests/Fixtures/Replay/README.md`](../Packages/AudioEngine/Tests/Fixtures/Replay/README.md) | How the detection replay fixtures and goldens work |
