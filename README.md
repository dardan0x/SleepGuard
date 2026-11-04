# SleepGuard

> Your bedside sleep lab. SleepGuard listens while you sleep, detects and records snoring, sleep talking, coughing, and ambient noise — then scores your sleep and shows you how it trends over time.

**100% on-device.** All audio analysis runs locally on your iPhone using Apple's `SoundAnalysis` framework. No accounts, no servers, no audio ever leaves your phone.

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Language](https://img.shields.io/badge/Swift-6.2-orange)
![Architecture](https://img.shields.io/badge/architecture-SPM%20%C2%B7%20SwiftData%20%C2%B7%20SwiftUI-green)
![Privacy](https://img.shields.io/badge/privacy-on--device-brightgreen)

---

## What it does

SleepGuard turns your phone into a bedside monitor. Start a session, set it on your nightstand, and it captures the sounds of your night — then in the morning you get a sleep score, a timeline of what happened, and audio clips you can play back.

### Core capabilities

| | Feature | What it does |
|---|---------|--------------|
| 🌙 | **Live sleep session** | Bedside-clock UI with a real-time decibel meter, snoring glow, and live event detection. Keeps recording in the background and survives interruptions, route changes, and low battery. |
| 🔊 | **Multi-sound detection** | Classifies **snoring** (quiet · light · loud · epic), **sleep talking**, **coughing**, and **ambient noise** using Apple's on-device 300-class sound classifier — with an FFT/amplitude fallback. |
| 📊 | **Sleep quality score** | A 0–100 score derived from snoring percentage, event frequency, sleep-talking, and (when available) sleep-stage architecture. |
| 🎧 | **Audio playback** | Browse past nights, scrub the full recording, jump between events, and play individual gap-free snore clips with optional enhanced audio (normalization + bandpass cleanup). |
| 📈 | **Trends & statistics** | Dashboard, calendar, "Last 7 Nights" view, and weekly/monthly Swift Charts for sleep score, snoring time, and event frequency. |
| ⌚ | **Apple Watch + HealthKit** | Reads sleep stages from Apple Watch, overlays a hypnogram on your timeline, and writes sleep sessions back to Apple Health. |
| 📄 | **PDF sleep reports** | Export a polished report — score, stats, sleep-architecture breakdown, and a full event log — to share with a doctor or partner. |
| 🎵 | **Soothing melodies** | Optional background sounds that fade in when snoring is detected (built-in library + record-your-own), without ever dropping the mic. |
| ⏰ | **Delayed start & smart wake** | Countdown-based delayed recording and a smart alarm that wakes you in a light-sleep window. |
| 🔒 | **Privacy-first** | Everything lives locally in SwiftData. No sign-in, no cloud, no tracking. |

---

## How detection works

```
AVAudioEngine tap
      │  (full-spectrum PCM, 50 ms windows)
      ▼
SoundAnalysis  ──►  300-class classifier  ──►  snore / speech / cough / baby / noise confidence
      │                                              │
      │ (fallback if "snoring" unavailable)          ▼
      ▼                                    consecutive-sample gate + dB floor
amplitude / FFT detector                              │
                                                      ▼
                                          SnoreEvent (bursts, intensity, duration)
                                                      │
                                                      ▼
                                     gap-free audio clip + raw classification log
```

- **Events** group continuous activity, merging brief breathing pauses (≤10 s) so one snoring spell is one event, not fifty.
- **Bursts** track the actual snoring segments inside an event, so "snoring time" reflects real snoring, not the silent gaps.
- Detection sensitivity is user-tunable (±5 dB), and sleep-talking detection is an opt-in toggle.

**Sleep score** combines a snoring penalty (capped), an events-per-hour penalty, an optional sleep-talking penalty, and — when Watch data is present — a sleep-architecture penalty grounded in sleep-medicine thresholds (deep ≥ 15%, REM ≥ 18%, awake ≤ 8%).

---

## Architecture

A modular Swift Package layout with strict isolation: **feature packages never import each other** — they depend only on `Models`, `AudioEngine`, `Env`, and `DesignSystem`. The app target is the only place that wires everything together.

| Package | Responsibility |
|---------|----------------|
| `Models` | SwiftData `@Model` types — `SleepSession`, `SnoreEvent`, `SnoreBurst`, `SleepStageSegment`, `SoundCategory` |
| `AudioEngine` | `AVAudioEngine` recording + `SoundAnalysis` detection + amplitude/FFT fallback + clip extraction |
| `Env` | Shared `@MainActor @Observable` singletons — `SessionManager`, `AudioRecorder`, `HealthKitSync`, melody player |
| `DesignSystem` | Theme tokens, charts, reusable components, and auto-generated localized strings |
| `Onboarding` | First-run flow with permission requests (mic, notifications, HealthKit, Watch) |
| `SleepSession` | Live recording UI, bedside clock, session summary |
| `Statistics` | Dashboard, calendar, trends, Last-7-Nights |
| `Recordings` | Session history, detail view, audio player, PDF export |
| `Settings` | Sensitivity, appearance, HealthKit sync, melodies, data management |
| `Personalization` | Briefing engine and quote bank — the content that personalizes the app |
| `Learn` | Learn tab — educational content about sleep and snoring |

**Patterns enforced project-wide:**
- `@State` + a `ViewState` enum per data-loading view — **no ViewModels**, no boolean soup.
- Dependencies flow through `@Environment`; shared services are `.shared` singletons.
- All navigation goes through `RouterPath` (`RouterDestination` for push, `SheetDestination` for modals); each tab owns its own path.
- `async/await` everywhere — no Combine, no GCD, no completion handlers.
- **Swift 6 with strict concurrency everywhere** — language mode v6 in all packages, `SWIFT_STRICT_CONCURRENCY = complete` in the app target. `Sendable`/isolation violations are compile errors, fixed properly (never `@unchecked Sendable`). Core packages (`Models`, `Env`, `AudioEngine`) use explicit `@MainActor` annotations; the UI packages declare `MainActor` default isolation.
- **Small views, enforced** — no view file over 200 lines, containers under 100; sections are extracted as dedicated view structs (not computed `some View` properties), and sheets/alerts are enum-driven, not boolean flags.
- **UI layering** — only view files import `DesignSystem` for UI chrome; enforced by `scripts/check-layering.py` in CI.
- Every user-facing string is localized through a generated `Strings` enum.

---

## Requirements

- iOS 17.0+
- Xcode 26+ (Swift 6.2 toolchain)
- Swift 6 language mode with strict concurrency (all packages + app target)
- A physical device for real recording (the simulator has no microphone input)

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
├── SleepGuard/              # App target — entry point, tabs, dependency graph, route registry
├── SleepGuard.xcodeproj/
├── Packages/                # 11 feature & support packages (see Architecture)
├── WatchApp/                # watchOS companion
├── designs/
│   ├── SleepGuard.pen       # Pencil design source — single source of truth for UI
│   └── screenshots/         # Reference screenshots
├── sounds/                  # Soothing melody assets
├── scripts/                 # Localization codegen (generate-strings, generate-xcstrings) + layering CI check
└── docs/                    # Architecture docs, feature trackers, session summaries
```

## Design

The entire UI is built against a single design source — [`designs/SleepGuard.pen`](designs/SleepGuard.pen) (Pencil format) — using a dark-first theme. Selected tokens:

| Token | Value | | Token | Value |
|-------|-------|---|-------|-------|
| `bg-primary` | `#000000` | | `score-green` | `#30D158` |
| `bg-card` | `#2C2C2E` | | `score-amber` | `#FF9F0A` |
| `accent` | `#5E9CFF` | | `score-red` | `#FF453A` |
| `text-primary` | `#FFFFFF` | | `radius-card` | `16` |
