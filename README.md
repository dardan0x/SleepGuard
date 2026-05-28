# SleepGuard

An iOS sleep tracker that detects and records snoring, sleep talking, coughing, and ambient noise — then scores your sleep quality and surfaces trends over time. All audio analysis happens on-device; no data leaves your phone.

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Language](https://img.shields.io/badge/language-Swift%205.9-orange)
![Architecture](https://img.shields.io/badge/architecture-SPM%20%2B%20SwiftData-green)

## Features

- **Live Sleep Session** — bedside clock UI with real-time dB monitoring and event detection
- **Multi-Sound Detection** — classifies snoring (quiet/light/loud), sleep talking, coughing, and noise using on-device audio analysis
- **Sleep Quality Score** — computed from snoring percentage, event count, and sleep stage data
- **Audio Playback** — browse sessions, play back full recordings, and share individual event clips
- **Trends & Statistics** — weekly/monthly charts for sleep score, snoring time, and event frequency
- **HealthKit Integration** — read Apple Watch sleep stages and write sleep sessions to Apple Health
- **PDF Reports** — export detailed sleep reports with architecture breakdowns
- **Soothing Melodies** — optional background sounds during sleep sessions
- **Privacy-First** — all data stays local (SwiftData); no accounts or servers

## Architecture

9 modular Swift Packages with strict dependency rules (feature packages never import each other):

| Package | Purpose |
|---------|---------|
| `Models` | SwiftData `@Model` types (`SleepSession`, `SnoreEvent`) |
| `AudioEngine` | `AVAudioEngine` recording + `SoundAnalysis` / amplitude-based detection |
| `Env` | Shared singletons (`SessionManager`, `AudioRecorder`, `HealthKitSync`) |
| `DesignSystem` | Theme, charts, reusable UI components, auto-generated strings |
| `Onboarding` | 5-screen first-run flow with permissions |
| `SleepSession` | Live recording UI + session summary sheet |
| `Statistics` | Dashboard, trends, calendar, last-7-nights view |
| `Recordings` | Session history list, detail view, audio player, PDF export |
| `Settings` | Preferences (sensitivity, appearance, HealthKit sync, melodies) |

**Patterns:** `@State` + `ViewState` enum (no ViewModels), `@Environment` dependency injection, `RouterPath` navigation, `async/await` everywhere.

## Requirements

- iOS 17.0+
- Xcode 16+
- Swift 5.9

## Build

```bash
xcodebuild -project SleepGuard.xcodeproj \
  -scheme SleepGuard \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

## Project Structure

```
SleepGuard/
├── SleepGuard/                  # App target (entry point, tabs, registry)
├── SleepGuard.xcodeproj/
├── Packages/
│   ├── AudioEngine/
│   ├── DesignSystem/
│   ├── Env/
│   ├── Models/
│   ├── Onboarding/
│   ├── Recordings/
│   ├── Settings/
│   ├── SleepSession/
│   └── Statistics/
├── WatchApp/                    # watchOS companion
├── designs/
│   ├── SleepGuard.pen           # Pencil design source
│   └── screenshots/             # UI screenshots
├── sounds/                      # Soothing melody assets
└── docs/                        # Architecture docs & feature trackers
```

## Design

The UI is built against a single design source in [`designs/SleepGuard.pen`](designs/SleepGuard.pen) (Pencil format). Dark-first theme with tokens:

| Token | Value |
|-------|-------|
| `bg-primary` | `#000000` |
| `bg-card` | `#2C2C2E` |
| `accent` | `#5E9CFF` |
| `score-green` | `#30D158` |
| `score-amber` | `#FF9F0A` |
| `score-red` | `#FF453A` |

## License

MIT
