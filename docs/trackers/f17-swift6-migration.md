# F17 — Swift 6 Migration

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P1 |
| **Version** | V5 |
| **Blocked By** | — |
| **Started** | 2026-11-03 |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

Migrate the entire SleepGuard codebase (11 SPM packages + app target) to the
Swift 6 language mode with strict concurrency, following the architecture the
IceCubesApp project adopted (documented in IceCubesApp/docs/architecture, Oct
2026). Packages move to `swift-tools-version: 6.2` + `swiftLanguageMode(.v6)`;
the app target moves to `SWIFT_VERSION = 6.0` with `SWIFT_STRICT_CONCURRENCY =
complete`. UI/feature packages declare `.defaultIsolation(MainActor.self)`;
core packages (Models, Env, AudioEngine) keep explicit `@MainActor`
annotations with no default isolation, matching the IceCubes split. No user-
facing behavior changes — this is an infrastructure hardening feature.

## Decisions

- **Package isolation split (IceCubes style)**: `Models`, `Env`, `AudioEngine`
  keep the explicit-`@MainActor` style (no package default isolation);
  `DesignSystem`, `Learn`, `Onboarding`, `Personalization`, `Recordings`,
  `Settings`, `SleepSession`, `Statistics` declare
  `.defaultIsolation(MainActor.self)` and may drop explicit view annotations.
- **Per-task stacked branches** (user decision 2026-11-03): each task gets its own
  branch `feature/f17/t#-short-description`, stacked on the previous task's
  branch (the migration is strictly sequential — each flip builds on the
  previous). `feature/f17/swift6-migration` is the integration branch: each
  task branch is fast-forwarded into it when the task is Done. Commits tagged
  `[F17-T#]`. Created retroactively for T2–T4 (repacked from the old
  single-branch history).
- **Deployment targets unchanged**: iOS 17 / watchOS 10 / macOS 14 stay as-is;
  language mode is independent of deployment target. No platform bumps.
- **`SWIFT_UPCOMING_FEATURE_*` flags**: out of scope (optional separate pass).
- **WatchApp**: out of scope — not wired into the Xcode project (0 refs in
  pbxproj) and still uses `ObservableObject`. Revisit when it is integrated.
- **No `@unchecked Sendable`**: Sendable/isolation violations are fixed
  properly (value types, `let`, locks), per IceCubes rules.
- **Notion**: not synced — the Notion integration has access to zero pages from
  this environment. Local tracker is the source of truth.

## Reference: Current State (2026-11-03 audit)

- Toolchain: Xcode 26.4, Swift 6.3 — supports tools 6.2 + language mode v6.
- App target: `SWIFT_VERSION = 5.0`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
  and `SWIFT_APPROACHABLE_CONCURRENCY = YES` already set; no strict concurrency.
- Packages: all `swift-tools-version: 5.9`; iOS 17 (+ watchOS 10 for Models/
  AudioEngine; + macOS 14 for Env); no external SPM dependencies.
- Tripwires found: 0 `@unchecked Sendable`, 0 `import Combine` in source,
  1 `DispatchQueue` (SessionManager AAC encode), 2 `Task.detached`
  (PlayerSheetView, StorageLimitEnforcer), 17 `@escaping` view-init callbacks,
  18 `@Observable` classes across 16 files (mostly Env services), 5 SwiftData
  `@Model` classes. 176 Swift files total.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F17-T1 | Migration baseline: branch + baseline build/test log | Chore | Done | — | repo | 2026-11-03 | 2026-11-03 |
| F17-T2 | Models → Swift 6 (tools 6.2, v6, explicit @MainActor kept) | Migration | Done | F17-T1 | Models | 2026-11-03 | 2026-11-03 |
| F17-T3 | AudioEngine → Swift 6 (tools 6.2, v6) | Migration | Done | F17-T2 | AudioEngine | 2026-11-03 | 2026-11-03 |
| F17-T4 | Env → Swift 6 (tools 6.2, v6) | Migration | Done | F17-T2, F17-T3 | Env | 2026-11-03 | 2026-11-03 |
| F17-T5 | DesignSystem → v6 + .defaultIsolation(MainActor) | Migration | Done | F17-T4 | DesignSystem | 2026-11-03 | 2026-11-03 |
| F17-T6 | Onboarding → v6 + .defaultIsolation(MainActor) | Migration | Done | F17-T5 | Onboarding | 2026-11-04 | 2026-11-04 |
| F17-T7 | SleepSession → v6 + .defaultIsolation(MainActor) | Migration | Done | F17-T5 | SleepSession | 2026-11-04 | 2026-11-04 |
| F17-T8 | Statistics → v6 + .defaultIsolation(MainActor) | Migration | Done | F17-T5 | Statistics | 2026-11-04 | 2026-11-04 |
| F17-T9 | Recordings → v6 + .defaultIsolation(MainActor) | Migration | Done | F17-T5 | Recordings | 2026-11-04 | 2026-11-04 |
| F17-T10 | Personalization → v6 + .defaultIsolation(MainActor) | Migration | Done | F17-T5 | Personalization | 2026-11-04 | 2026-11-04 |
| F17-T11 | Settings → v6 + .defaultIsolation(MainActor) | Migration | Done | F17-T10 | Settings | 2026-11-04 | 2026-11-04 |
| F17-T12 | Learn → v6 + .defaultIsolation(MainActor) | Migration | Done | F17-T5 | Learn | 2026-11-04 | 2026-11-04 |
| F17-T13 | App target → Swift 6 + strict concurrency complete | Migration | Done | F17-T2–F17-T12 | App | 2026-11-04 | 2026-11-04 |
| F17-T14 | Full verification: build + tests + simulator smoke test | Verify | In Progress | F17-T13 | repo | 2026-11-04 | — |
| F17-T15 | Docs sync: architecture docs + AGENTS/CLAUDE concurrency rules | Docs | Backlog | F17-T13 | docs | — | — |
| F17-T16 | Feature doc + session fragment | Docs | Backlog | F17-T14, F17-T15 | docs | — | — |

## Task Details

### F17-T1 — Migration baseline: branch + baseline build/test log

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/concurrency.md`, `docs/architecture/modules.md` |
| Status | Done |
| Started | 2026-11-03 |
| Completed | 2026-11-03 |

**Acceptance Criteria:**
- [x] Branch `feature/f17/swift6-migration` created from clean `main`
- [x] Baseline build log saved (current Swift 5 settings, zero errors)
- [x] Baseline test run log saved
- [x] Audit notes (tripwire counts) recorded in this tracker

**Prompt Used:**
Set up the Swift 6 migration: create the F17 tracker with 16 tasks per the plan, update FeatureTracker, create branch `feature/f17/swift6-migration`, and capture baseline build/test logs under current Swift 5 settings.

**Notes:**
- Baseline build: **BUILD SUCCEEDED** (`/tmp/sleepguard-f17-baseline-build.log`, 89 s).
- Baseline tests: scheme `SleepGuard` has **no test action configured** — the project has zero test targets. Log at `/tmp/sleepguard-f17-baseline-test.log` (exit 66 documents this). F17-T14 verification will rely on build + simulator smoke test.
- Build surfaced two always-run script phases worth knowing: `Generate Strings.swift` and `Firebase Crashlytics`.
- Tripwire audit recorded in "Reference: Current State" section above.

---

### F17-T2 — Models → Swift 6

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/concurrency.md`, `docs/architecture/networking.md` (model conventions) |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] `Package.swift`: tools 5.9 → 6.2, `swiftSettings: [.swiftLanguageMode(.v6)]`
- [x] NO `.defaultIsolation` declared (explicit-`@MainActor` style package)
- [x] All 4 SwiftData `@Model` classes compile under v6 with correct isolation
- [x] `Sendable` conformances verified/added (structs, immutable `let`)
- [x] Zero `@unchecked Sendable` introduced
- [x] Package builds standalone with zero errors

**Prompt Used:**
Migrate the Models package to Swift 6: bump Package.swift to tools 6.2 with `swiftLanguageMode(.v6)`, keep the explicit-`@MainActor` style (no default isolation), fix any v6 compile errors.

**Notes:**
- One error surfaced: `SnoringEpisode` (Sendable struct) stored `[SnoreEvent]` — a non-Sendable `@Model` class. Fix: **removed the `Sendable` conformance** from `SnoringEpisode` rather than refactoring to a snapshot type. It is consumed only synchronously in MainActor UI (SnoringTimelineView, SessionDetailView), so the conformance bought nothing. No other changes.

---

### F17-T3 — AudioEngine → Swift 6

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/concurrency.md` |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] `Package.swift`: tools 5.9 → 6.2, `swiftLanguageMode(.v6)`, no defaultIsolation
- [x] Existing `nonisolated` AVFoundation/SoundAnalysis delegate patterns preserved and still compile
- [x] `AudioRecorder`, `SoundAnalysisDetector`, `SpeechDetector`, `SnoreDetector` Sendable/isolation-correct (locks or `let` where mutable state exists)
- [x] Zero `@unchecked Sendable` introduced
- [x] Package builds standalone with zero errors

**Prompt Used:**
Migrate AudioEngine to Swift 6 (tools 6.2 + `swiftLanguageMode(.v6)`, no default isolation) and fix all v6 compile errors.

**Notes:**
- `ClipResult` made `Sendable` (UUID/URL/Double members) — required by `withTaskGroup`.
- `extractSingleClip` no longer takes `SnoreEvent` (@Model, non-Sendable) — refactored to take `eventID`/`eventTimestamp`/`eventSnoreDuration`/`bursts` (all Sendable) so the `addTask` closure captures only Sendable values. Convenience `extractSingleClip(for: SnoreEvent…)` overload preserved; no external callers of the old signature exist.
- The `installTap` closures in `AudioRecorder` compile unchanged — `AVAudioNodeTapBlock` is not Sendable-checked in the iOS 26 SDK. Flagged for T14 smoke test: real recording verification on device/simulator is the safety net for this path.

---

### F17-T4 — Env → Swift 6

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/concurrency.md`, `docs/architecture/dependencies.md` |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] `Package.swift`: tools 5.9 → 6.2, `swiftLanguageMode(.v6)`, no defaultIsolation
- [x] All 18 `@Observable` service classes keep **explicit** `@MainActor` (load-bearing here)
- [x] `DispatchQueue` AAC-encode site in `SessionManager` audited (Sendable capture list / isolation correct)
- [x] `Task.detached` in `StorageLimitEnforcer` audited
- [x] `WatchConnectivityManager` delegate isolation correct
- [x] Zero `@unchecked Sendable` introduced
- [x] Package builds standalone with zero errors

**Prompt Used:**
Migrate Env to Swift 6 (tools 6.2 + `swiftLanguageMode(.v6)`, no default isolation) and fix all v6 compile errors.

**Notes:**
- `StorageLimitEnforcer`: class made `Sendable` (stateless); `enforceLimits` made `@MainActor` with the `MainActor.run` wrapper removed — the wrapper's `@Sendable` closure captured non-Sendable `ModelContext` ("sending risks data races"). Planning now runs directly on MainActor; file deletion stays off-main via `Task.detached`. All 4 call sites are MainActor (app launch, 2 settings views, summary view).
- `WatchConnectivityManager`: `WCSessionDelegate` methods marked `nonisolated` (protocol is nonisolated, class is `@MainActor` — conformance crossed isolation). Second iteration: `[String: Any]` message dict is now parsed synchronously in the nonisolated method; only the `lastSyncedSession = Date()` assignment hops to MainActor (capturing the dict in the Task re-errored as "sending").
- `SessionManager`'s `requestMediaDataWhenReady` DispatchQueue + continuation site compiles unchanged — the SDK block is not Sendable-checked. Flagged for T14 smoke test.

---

### F17-T5 — DesignSystem → v6 + .defaultIsolation(MainActor)

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md`, `docs/architecture/dependencies.md` |
| Status | Done |
| Started | 2026-11-03 |
| Completed | 2026-11-03 |

**Acceptance Criteria:**
- [x] `Package.swift`: tools 6.2, `swiftSettings: [.swiftLanguageMode(.v6), .defaultIsolation(MainActor.self)]`
- [x] `Theme` and all components compile; explicit `@MainActor` annotations may be dropped where the compiler default covers them
- [x] `@escaping` action closures in `StopRecordingButton`, `RecordingActionButton`, `SheetHeader`, `RecordingActionButton`, `UpdateGateView` compile under v6 (add `@Sendable`/isolation as needed)
- [x] Zero `@unchecked Sendable` introduced
- [x] Package builds standalone with zero errors

**Prompt Used:**
Migrate DesignSystem to Swift 6 with `.defaultIsolation(MainActor.self)`; fix all surfaced errors including any consumer breakage in still-v5 packages.

**Notes:**
- DesignSystem sources compiled clean on the first try — views were already explicitly `@MainActor` per project rules, so default isolation changed nothing internally.
- `.defaultIsolation(MainActor)` makes **all DesignSystem public API (incl. `Strings`) MainActor-isolated**. This broke two nonisolated enums in still-v5 consumer packages (they reference `Strings.*`):
  - `Statistics/TrendsView.swift` — file-scope `private enum TimeRange` → annotated `@MainActor`.
  - `Recordings/SessionDetailView.swift` — nested `private enum EventCategoryFilter` (nested types don't inherit the `@MainActor` view's isolation) → annotated `@MainActor`.
- Both consumer fixes ride on the T5 branch by necessity (build must stay green); Statistics/Recordings get their own flips in T8/T9. Branch: `feature/f17/t5-designsystem-swift6`.
- Verified non-issue: `SettingsView.swift`'s `extension UserPreferences.AppearanceSetting` inherits MainActor from the extended type (UserPreferences is @MainActor in Env), so it needed no change.

---

### F17-T6 — Onboarding → v6 + .defaultIsolation(MainActor)

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Done |
| Started | 2026-11-04 |
| Completed | 2026-11-04 |

**Acceptance Criteria:**
- [x] `Package.swift`: tools 6.2 + v6 + `.defaultIsolation(MainActor.self)`
- [x] Package builds standalone with zero errors

**Prompt Used:**
Migrate Onboarding to Swift 6 with `.defaultIsolation(MainActor.self)`; fix any surfaced errors.

**Notes:**
- Zero source changes required — manifest-only flip. First UI package that needed no consumer annotations. Branch `feature/f17/t6-onboarding-swift6`, merged via PR #66.

---

### F17-T7 — SleepSession → v6 + .defaultIsolation(MainActor)

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Done |
| Started | 2026-11-04 |
| Completed | 2026-11-04 |

**Acceptance Criteria:**
- [x] `Package.swift`: tools 6.2 + v6 + `.defaultIsolation(MainActor.self)`
- [x] Package builds standalone with zero errors

**Prompt Used:**
Migrate SleepSession to Swift 6 with `.defaultIsolation(MainActor.self)`; fix any surfaced errors.

**Notes:**
- New error class surfaced: **conformance availability**. Swift 6 enforces protocol-conformance availability — `BounceSymbolEffect: IndefiniteSymbolEffect` is annotated iOS 18+ while the package targets iOS 17. Swift 5 mode silently allowed it.
- Fix: extracted `PreviewSpeakerIcon` in `MelodyPickerSheet`; `.bounce.repeating` gated behind `if #available(iOS 18, *)`, `.pulse` fallback on iOS 17 (`PulseSymbolEffect`'s indefinite conformance IS iOS 17-annotated — `BedsideClockView` compiles untouched). Discrete `.bounce` also resolves to the iOS 18 conformance, so it couldn't serve as the fallback.
- Runtime impact: on iOS 17 the melody-preview icon pulses instead of bounces. iOS 18+ unchanged. Flagged for T14 smoke test on a 17-device if available. Branch `feature/f17/t7-sleepsession-swift6`, merged PR #67.

---

### F17-T8 — Statistics → v6 + .defaultIsolation(MainActor)

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Done |
| Started | 2026-11-04 |
| Completed | 2026-11-04 |

**Acceptance Criteria:**
- [x] `Package.swift`: tools 6.2 + v6 + `.defaultIsolation(MainActor.self)`
- [x] Package builds standalone with zero errors

**Prompt Used:**
Migrate Statistics to Swift 6 with `.defaultIsolation(MainActor.self)`; fix any surfaced errors.

**Notes:**
- Manifest-only flip — zero source changes. The `TimeRange` `@MainActor` annotation from T5 already satisfied the Strings isolation. Branch `feature/f17/t8-statistics-swift6`, merged PR #68.

---

### F17-T9 — Recordings → v6 + .defaultIsolation(MainActor)

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Done |
| Started | 2026-11-04 |
| Completed | 2026-11-04 |

**Acceptance Criteria:**
- [x] `Package.swift`: tools 6.2 + v6 + `.defaultIsolation(MainActor.self)`
- [x] `Task.detached` in `PlayerSheetView` audited
- [x] `@escaping` playback callbacks in `SessionDetailMiniPlayerView` compile under v6
- [x] Zero `@unchecked Sendable` introduced
- [x] Package builds standalone with zero errors

**Prompt Used:**
Migrate Recordings to Swift 6 with `.defaultIsolation(MainActor.self)`; fix any surfaced errors.

**Notes:**
- One error: `Task.detached` called MainActor-isolated `WaveformGenerator.generateSamples` (package default isolation made the pure utility actor-isolated). Fix: both static methods marked `nonisolated`; `event.snoreDuration` hoisted to a Sendable local so the detached task no longer captures the non-Sendable `SnoreEvent`. Branch `feature/f17/t9-recordings-swift6`, merged PR #69.

---

### F17-T10 — Personalization → v6 + .defaultIsolation(MainActor)

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Done |
| Started | 2026-11-04 |
| Completed | 2026-11-04 |

**Acceptance Criteria:**
- [x] `Package.swift`: tools 6.2 + v6 + `.defaultIsolation(MainActor.self)`
- [x] `@escaping` callbacks in `BriefingSurveyCard`, `ProfilePromptCard`, `ProfileEditorView`, `SleepBriefingView` compile under v6
- [x] Package builds standalone with zero errors

**Prompt Used:**
Migrate Personalization to Swift 6 with `.defaultIsolation(MainActor.self)`; fix any surfaced errors.

**Notes:**
- Manifest-only flip — zero source changes; `@escaping` view callbacks compile fine under package default isolation. Noted: this package has the project's only test target (`PersonalizationTests`, 23 BriefingEngine tests) — flipped to v6 + default isolation too; builds clean. Running the tests needs a test action wired into a scheme (out of scope here; flagged for T14). Branch `feature/f17/t10-personalization-swift6`, merged PR #70.

---

### F17-T11 — Settings → v6 + .defaultIsolation(MainActor)

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Done |
| Started | 2026-11-04 |
| Completed | 2026-11-04 |

**Acceptance Criteria:**
- [x] `Package.swift`: tools 6.2 + v6 + `.defaultIsolation(MainActor.self)`
- [x] Package builds standalone with zero errors (depends on Personalization from F17-T10)

**Prompt Used:**
Migrate Settings to Swift 6 with `.defaultIsolation(MainActor.self)`; fix any surfaced errors.

**Notes:**
- Manifest-only flip — zero source changes. **All 11 packages now on Swift 6.** Branch `feature/f17/t11-settings-swift6`, merged PR #71 (user merged on GitHub).

---

### F17-T12 — Learn → v6 + .defaultIsolation(MainActor)

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Done |
| Started | 2026-11-04 |
| Completed | 2026-11-04 |

**Acceptance Criteria:**
- [x] `Package.swift`: tools 6.2 + v6 + `.defaultIsolation(MainActor.self)`
- [x] `WKNavigationDelegate` `decisionHandler` in `LearnView` compiles under v6 (nonisolated pattern as in AudioEngine delegates)
- [x] Package builds standalone with zero errors

**Prompt Used:**
Migrate Learn to Swift 6 with `.defaultIsolation(MainActor.self)`; fix any surfaced errors.

**Notes:**
- Manifest-only flip — zero source changes. The `decidePolicy` completion handler is not Sendable/sending-checked in the iOS 26 SDK (same as AVFoundation delegate patterns). Flagged for T14 smoke test (Learn tab browsing). Merged locally into integration per the small-change rule.

---

### F17-T13 — App target → Swift 6 + strict concurrency complete

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/overview.md`, `docs/architecture/concurrency.md` |
| Status | Done |
| Started | 2026-11-04 |
| Completed | 2026-11-04 |

**Acceptance Criteria:**
- [x] `SWIFT_VERSION` 5.0 → 6.0 (app target, Debug + Release)
- [x] `SWIFT_STRICT_CONCURRENCY = complete` set (both configs)
- [x] `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES` preserved
- [x] All 9 app-target Swift files compile under v6
- [x] No new Combine/GCD introduced
- [x] Zero `@unchecked Sendable` introduced
- [x] Full app build succeeds with zero errors

**Prompt Used:**
Flip the app target to Swift 6 with strict concurrency complete; fix any surfaced errors.

**Notes:**
- **Compiled clean on the first try** — all 9 app files needed zero changes. Validates the project's IceCubes-style discipline (views already `@MainActor`, env-based DI, no Combine/GCD). Project-level SWIFT_VERSION intentionally left blank (only the 2 app configs carry it). Branch `feature/f17/t13-app-target-swift6`, merged PR #72. **Entire codebase now Swift 6.**

---

### F17-T14 — Full verification: build + tests + simulator smoke test

| Field | Value |
|-------|-------|
| Arch Ref | `AGENTS.md` Build & Report |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] `build_sim` succeeds via XcodeBuildMCP (pinned simulator UDID)
- [ ] `test_sim` passes (no regressions vs F17-T1 baseline)
- [ ] App launches on simulator; smoke test passes: onboarding → start recording → sessions list → session detail → settings
- [ ] `python3 scripts/generate-strings.py` still runs (codegen unaffected)

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_—_

---

### F17-T15 — Docs sync: architecture docs + AGENTS/CLAUDE concurrency rules

| Field | Value |
|-------|-------|
| Arch Ref | `IceCubesApp/docs/architecture/` (reference), `docs/architecture/` |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] `docs/architecture/concurrency.md` — Swift 6 model, strict concurrency, isolation split (explicit in Models/Env/AudioEngine; defaultIsolation in 8 UI packages), no-`@unchecked-Sendable` rule
- [ ] `docs/architecture/INDEX.md` — quick reference updated
- [ ] `docs/architecture/overview.md` — build settings table (verified from project.pbxproj)
- [ ] `docs/architecture/rules.md` — Do/Don't updated to new isolation model
- [ ] `docs/architecture/views.md` — MainActor-by-default nuance
- [ ] `docs/architecture/modules.md` — new-feature checklist includes swiftSettings step
- [ ] `docs/architecture/feature-template.md` + `PROMPTS.md` — Swift 6 targets
- [ ] `AGENTS.md` + `CLAUDE.md` concurrency bullets updated
- [ ] IceCubes-specific content NOT copied (Mastodon clients, StatusKit, window destinations, RevenueCat)
- [ ] SleepGuard-specific content preserved (watchOS platforms, SwiftData rules, localization)

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_—_

---

### F17-T16 — Feature doc + session fragment

| Field | Value |
|-------|-------|
| Arch Ref | `docs/VIBE_CODING_WORKFLOW.md` Phase 3 Step 4 |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] `docs/features/f17-swift6-migration.md` created (files table, build settings changed, package isolation split, edge cases, tasks completed)
- [ ] `docs/sessions/2026-11-03-swift6-migration.md` session fragment created
- [ ] This tracker finalized; FeatureTracker dashboard updated to Done

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_—_

---

## Update Rules (for the AI)

After completing a task in this feature:
1. Check off acceptance criteria boxes
2. Fill Started/Completed dates in task table and detail section
3. Set task Status to **Done**
4. Fill "Prompt Used" with the prompt summary
5. Add any notes about decisions or deviations
6. If ALL tasks are Done → set feature Status to **Done**, fill Completed date
7. Also update the index file (docs/FeatureTracker.md)
