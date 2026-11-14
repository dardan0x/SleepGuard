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

- `Models`, `AudioEngine`, `DesignSystem`, `Env`, `Recordings` and `Statistics` depend on the package by path (`../../../SleepGuardShared`). Files that name a moved type add `import SleepCore`. No re-export (`@_exported`): an import says where a type comes from.
- `DesignSystem/Sources/Strings.swift` is now `@_exported import SleepStrings`, so every `Strings.x` call site is unchanged. This is the one re-export. A `typealias` was tried first and failed: the app and widget targets build with member import visibility (`SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`), which hides the enum's members unless the defining module is imported. The alternative was `import SleepStrings` in every file that uses a string, plus linking the product into both targets by hand.
- `scripts/generate-strings.py`, `generate-xcstrings.py` and `record-replay-goldens.sh` run the shared repo's scripts against the local checkout.
- What stays here: the SwiftData `@Model` classes and everything computed on them (`snoringDuration`, `snoringEpisodes`, `refreshCachedScore`), the classifiers (`SnoreDetector`, `SpeechDetector`), all services, all views.

## Consequences

- **One source for the rules.** A score or detection change is made once and tested once. The replay goldens passed unchanged after the move.
- **Stored data is unaffected.** `SleepGuardSchemaTests.storeWrittenBeforeTheValueTypesMovedToSleepCoreStillOpens` opens a store written before the move (`Tests/ModelsTests/Fixtures/premove-v1.store`) and decodes every moved type from it.
- **`Strings` is no longer main-actor-isolated.** It used to inherit `DesignSystem`'s default isolation. Callers are unaffected.
- **A shared change affects every app.** Stored value types are now edited in another repo; changing their stored properties or raw values is still a schema change here (see "SwiftData Schema Rules").
- **Limits, stated plainly:**
  - A path dependency means this repo no longer builds on its own. A fresh clone, and CI, need `SleepGuardShared` beside it. CI is not updated yet: until the shared repo has a remote, `tests.yml` cannot fetch it. The intended end state is a versioned URL dependency, with the sibling checkout as a local override.
  - `strings-sync` in `quality.yml` no longer checks anything here (the generated file is in the other repo); that check has to move to the shared repo's CI.
  - Still in this repo, and candidates to move later: episode merging and snoring duration (computed on the `@Model`), the classifier rules, and the sensitivity thresholds in `RealtimeDetectionTracker`. Each needs a small refactor to become pure first, so they were left out of a move-only change.

## Alternatives

- **Copy the code into the new app.** No coupling, but two diverging formulas; rejected.
- **One repo per package.** A change that spans logic and strings would need two versions and two pins; rejected for one repo with several products.
- **`@_exported import SleepCore` from `Models`.** Two lines instead of ~40 import edits, but it relies on an underscored attribute and hides where types come from; rejected.
- **A git submodule.** Each app would carry its own copy of the checkout, so an edit would not reach the other app until both pointers moved; rejected for a sibling checkout.
