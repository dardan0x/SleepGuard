# ADR 0004: Move pure logic and strings into the `SleepGuardShared` repo

- **Status:** Accepted
- **Date:** 2026-11-14
- **Task:** Shared repo, Phase 0 (SleepGuardUIKitWay plan)

## Context

A second app, `SleepGuardUIKitWay`, rebuilds SleepGuard with a UIKit shell and a hexagonal core. It needs the same sleep score, the same detection rules and the same strings. Copying them would give two formulas and two state machines that drift apart.

The code that both apps need was already pure:

- `SleepScore`, `SleepScoreConfig`, `SleepInputs` and the cache-version hash (`Models`).
- `DetectionStateMachine`, `DetectionEngine`, their input/output types and the replay goldens (`AudioEngine`).
- The plain value types those use, which SwiftData also stores inside the models: `SnoreIntensity`, `SoundCategory`, `SleepStage`, `SleepStageSegment`, `StageStats`, `RecordingGap`, `SnoreBurst`, `DetectionState`.
- The string catalog and its generated `Strings` accessor (`DesignSystem`).

## Decision

Move that code, unchanged, into a separate git repo, `SleepGuardShared`, checked out next to this one. It is one Swift package with two products:

```
SleepGuardShared
  ├─ SleepCore      Foundation only: score, detection, value types (+ their tests and goldens)
  └─ SleepStrings   Localizable.xcstrings, generated Strings, the generator scripts
```

In this repo:

- `Models`, `AudioEngine`, `DesignSystem`, `Env`, `Recordings` and `Statistics` depend on a released version: `.package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.1.0")`. `exact:` so every package graph (each package's own test run, the app) agrees without relying on eight lockfiles.
- `SleepGuard.xcworkspace` adds `../SleepGuardShared` as a local package, which overrides the remote one everywhere in the graph. Building through the workspace uses the local checkout; building the project uses the release. Its `Package.resolved` holds the same pins as the project's (`scripts/bump-shared.sh` keeps them aligned). Files that name a moved type add `import SleepCore`. No re-export (`@_exported`): an import says where a type comes from.
- `DesignSystem/Sources/Strings.swift` is now `@_exported import SleepStrings`, so every `Strings.x` call site is unchanged. This is the one re-export. A `typealias` was tried first and failed: the app and widget targets build with member import visibility (`SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`), which hides the enum's members unless the defining module is imported. The alternative was `import SleepStrings` in every file that uses a string, plus linking the product into both targets by hand.
- `scripts/generate-strings.py`, `generate-xcstrings.py` and `record-replay-goldens.sh` run the shared repo's scripts against the local checkout. `scripts/bump-shared.sh <version>` moves the app to a new release.
- What stays here: the SwiftData `@Model` classes and everything computed on them (`snoringDuration`, `snoringEpisodes`, `refreshCachedScore`), the classifiers (`SnoreDetector`, `SpeechDetector`), all services, all views.

## Consequences

- **One source for the rules.** A score or detection change is made once and tested once. The replay goldens passed unchanged after the move.
- **Stored data is unaffected.** `SleepGuardSchemaTests.storeWrittenBeforeTheValueTypesMovedToSleepCoreStillOpens` opens a store written before the move (`Tests/ModelsTests/Fixtures/premove-v1.store`) and decodes every moved type from it.
- **`Strings` is no longer main-actor-isolated.** It used to inherit `DesignSystem`'s default isolation. Callers are unaffected.
- **A shared change affects every app.** Stored value types are now edited in another repo; changing their stored properties or raw values is still a schema change here (see "SwiftData Schema Rules").
- **Limits, stated plainly:**
  - **Two builds can differ.** The workspace builds your local shared checkout; `run-tests.sh`, the project and CI build the pinned release. A shared change is only tested here after it is tagged and bumped. This was chosen over a plain path dependency (which would make every build local) to get reproducible, versioned pins.
  - The workspace needs `../SleepGuardShared` beside this repo. The project and CI do not.
  - The `strings-sync` check moved to the shared repo's CI, where the generated file lives.
  - Still in this repo, and candidates to move later: episode merging and snoring duration (computed on the `@Model`), the classifier rules, and the sensitivity thresholds in `RealtimeDetectionTracker`. Each needs a small refactor to become pure first, so they were left out of a move-only change.

## Revision: night rules (F0-T6, 2026-11-14)

Episode grouping, snoring duration with the gap rule, event count, stage percentages and the score inputs were computed properties on `SleepSession`, and SleepGuardUIKitWay had ported them to its own value types: two copies of the same rules. They now live once in `SleepCore`, on shared values (`Night`, `NightEvent`, `NightEpisode`, `NightSummary`).

- `SleepSession+Night.swift` maps the stored models to `Night`; the computed properties call the shared rules. `SnoringEpisode` keeps its public API and wraps `NightEpisode`, adding the stored `SnoreEvent`s screens need.
- Kept on purpose: an unfinished session maps to a zero-length night (scores the maximum); `sleepInputs` uses the cached snoring duration when present.
- Proof: every Models test (episodes, stats, score, cache) passes unchanged. No schema change.
- Cost: the computed properties now build a `Night` (mapping every event) each time they are read. They already faulted every event, so the cost is the same order; lists keep using the cached score.

## Revision: statistics rules (F4-T2 in SleepGuardUIKitWay, 2026-11-14)

The Statistics numbers (dashboard state, week-over-week trend, Last 7 Nights day totals and best/worst, Trends averages, calendar month stats and grid, mini-chart day averages) were computed inside the Statistics views. They now live in `SleepCore` (`NightDashboard`, `ScoreTrend`, `NightDay`/`NightDayStats`, `NightPeriod`, `CalendarMonth`) on `NightSummary`, which gained `loudestIntensity`.

- The views keep their types (`DashboardState`, `DaySummary`, `Trend`); their bodies call the shared rules. No visual change intended.
- Two mappings, because faulting `events` has crashed: `summaryWithoutEvents` (cached score and snoring time, no events) chooses nights; `nightSummary` (reads events) is built only for the nights a screen shows. The dashboard and the trend stay event-free, as before.
- Proof: the Statistics tests (dashboard, week-over-week) pass unchanged; the same cases run in the shared repo against the shared rules.

## Alternatives

- **Copy the code into the new app.** No coupling, but two diverging formulas; rejected.
- **One repo per package.** A change that spans logic and strings would need two versions and two pins; rejected for one repo with several products.
- **`@_exported import SleepCore` from `Models`.** Two lines instead of ~40 import edits, but it relies on an underscored attribute and hides where types come from; rejected.
- **A plain path dependency** (the first version of this change). Every build sees local edits, including package tests, but nothing is versioned and CI needs the sibling checked out at some ref. Replaced by versioned releases plus the workspace override.
- **A git submodule.** Each app would carry its own copy of the checkout, so an edit would not reach the other app until both pointers moved; rejected for a sibling checkout.
