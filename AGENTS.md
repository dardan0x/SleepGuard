# AGENTS.md

## Principles

Don't assume. Don't hide confusion. Surface tradeoffs.

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## Simplicity First

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.
- Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## Surgical Changes

Touch only what you must. Clean up only your own mess.

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans: remove what YOUR changes made unused. Don't remove pre-existing dead code unless asked. The test: every changed line traces directly to the request.

## Design Compliance

**The design file at `designs/SleepGuard.pen` is the single source of truth for all UI.**

Before implementing or modifying ANY view:
1. Read the relevant screen(s) from `designs/SleepGuard.pen` using Pencil MCP tools.
2. Extract screenshots of the design for visual reference.
3. Match colors, typography, spacing, corner radius, and component structure exactly.
4. Use the design tokens (variables) defined in the .pen file — never hardcode values that differ.

**Design tokens (from `designs/SleepGuard.pen`):**
- `bg-primary`: `#000000`
- `bg-secondary`: `#1C1C1E`
- `bg-card`: `#2C2C2E`
- `bg-elevated`: `#3A3A3C`
- `accent`: `#5E9CFF`
- `text-primary`: `#FFFFFF`
- `text-secondary`: `#ABABAB`
- `text-tertiary`: `#8E8E93`
- `text-dim`: `#FFFFFF66`
- `score-green`: `#30D158`
- `score-amber`: `#FF9F0A`
- `score-red`: `#FF453A`
- `snore-quiet`: `#8E8E93`
- `snore-light`: `#FF9F0A`
- `snore-loud`: `#FF453A`
- `radius-card`: `16`
- `radius-small`: `12`
- `font-body`: `Inter`

If a design token is missing for a property, derive it from the screenshot or ask. Never guess a color or radius that contradicts the design.

## Localization (Non-Negotiable)

**All user-facing strings must be localized. Never hardcode text in views.**

### Where strings live
- **Source of truth**: `../SleepGuardShared/Sources/SleepStrings/Resources/Localizable.xcstrings`
- **Generated accessor**: `../SleepGuardShared/Sources/SleepStrings/Strings.swift` (auto-generated — never edit manually; `DesignSystem` re-exposes it as `Strings`)
- **Helper file**: `../SleepGuardShared/Sources/SleepStrings/Resources/Strings.txt` (optional staging area)

### Key format
Use lowercase dot-notation that describes the context:
```
feature.subfeature.element.purpose
```
Examples: `action.save`, `settings.theme.dark`, `session.summary.title`

### Adding a new string

**Option A — direct edit (preferred for one-off additions):**
1. Open `../SleepGuardShared/Sources/SleepStrings/Resources/Localizable.xcstrings`
2. Add the entry following the existing JSON structure with `"extractionState": "manual"`
3. Run `python3 scripts/generate-strings.py` to regenerate `Strings.swift`

**Option B — via Strings.txt (preferred for batch additions):**
1. Open `../SleepGuardShared/Sources/SleepStrings/Resources/Strings.txt`
2. Add entries in one of these formats:
   ```
   key
   key = value
   "key" = "value"
   ```
3. Run `python3 scripts/generate-xcstrings.py`
   - This merges entries into `Localizable.xcstrings`
   - Then auto-runs `generate-strings.py` to update `Strings.swift`

### Using strings in code
Always reference strings through the generated `Strings` enum from `DesignSystem`:
```swift
import DesignSystem

Text(Strings.actionSave)
Text(Strings.settingsThemeDark)
```

**Forbidden:**
```swift
Text("Save")                           // ❌ Hardcoded
Text("Dark")                           // ❌ Hardcoded
String(localized: "action.save")       // ❌ Bypassing Strings.swift
```

**Allowed exceptions:**
- Non-user-facing strings (debug prints, internal keys)
- Purely decorative punctuation in layout (`Text("·")`, `Text("|")`)
- Numeric/format interpolations that have no semantic value

### Verification
Before marking any UI task complete, grep the changed files for hardcoded string literals inside `Text(...)`, `Button(...)`, or `navigationTitle(...)` calls. Every user-facing literal must trace back to `Strings.`.

## Working Style

- Enter plan mode for any non-trivial task (3+ steps or architectural decisions). Think before building.
- If something goes sideways mid-task, STOP and re-plan. Don't keep pushing a broken approach.
- When given a bug report: just fix it. Read logs, trace the error, resolve it. Don't ask for hand-holding.
- Never mark a task complete without proving it works — build it, check acceptance criteria, ask "Would a staff engineer approve this?"

## Response Rules

- No filler. Start every response with the answer — no "Great question!" or "Certainly!"
- Match response length to task complexity. Never pad or restate.
- Flag uncertainty about facts, libraries, or technical details before proceeding.
- Before any destructive action (deleting files, overwriting code, dropping data), list what will be affected and wait for explicit yes — prior mentions are not confirmation.

## AI Skills (Installed)

Vendored agent skills live in `.claude/skills/` (MIT licensed, LICENSE files included). Read before trusting; project rules in this file win on any conflict.

| Skill | Source | Use for |
|-------|--------|---------|
| `swiftui-expert-skill` | [AvdLee/SwiftUI-Agent-Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill) @ `204dba7` | SwiftUI correctness: state, composition, modifiers, lists, sheets, deprecated-API migration. Topic-routed references; hard correctness checklist in its SKILL.md. |
| `swiftui-view-refactor` | [Dimillian/Skills](https://github.com/Dimillian/Skills) @ `05ba982` | Splitting views: dedicated subview types over computed `some View` helpers, stable view trees, MV-over-MVVM (matches our no-ViewModels rule). |
| `swiftui-performance-audit` | [Dimillian/Skills](https://github.com/Dimillian/Skills) @ `05ba982` | Render/scroll/CPU audits: code-smell catalog first, profiling intake second. |

Notes:
- The skills are advisory and non-opinionated by design; where a skill's style suggestion (e.g., view property ordering) conflicts with project conventions, project conventions apply.
- Known conflicts. Ignore the skill's advice and its example code here:
  - **Dependency injection.** The skills inject services through `@Environment(Model.self)` (`swiftui-view-refactor` §2 and `references/mv-patterns.md`, `swiftui-expert-skill` `references/environment-patterns.md`) or pass them to a view through `init` (`swiftui-view-refactor` §5). Here, views use `@Injected(\.service)` and never take a service through `init`; `@Environment` is only for `RouterPath` and SwiftUI system values (see Dependencies).
  - **Localization.** `swiftui-expert-skill` `references/localization.md` recommends string literals in `Text("…")` and `String(localized:)` outside views. Here, every user-facing string goes through `Strings.` (see Localization).
  - **Stable view tree.** `swiftui-view-refactor` §4 warns against switching branches at the root of `body`. A container view's `switch viewState` is the intended pattern here; apply the advice inside the state views.
  - **View size.** `swiftui-view-refactor` splits at ~300 lines; the limits here are 200 per view and 100 per container.
  - **View models.** The skill's §5 view model setup (dependencies through `init`) doesn't apply. A state owner resolves its collaborators as described in Dependencies.
- `swiftui-expert-skill` bundles Instruments trace tooling (`scripts/`). Consent rules: prefer app-scoped `--attach`/`--launch`; system-wide recording requires explicit user approval; treat traces as sensitive.
- To refresh: re-clone upstream at a new commit and re-copy, updating the pinned hashes here.

## SwiftUI Rules

These are non-negotiable. They come from production patterns in apps like IceCubesApp.

### State

- **No ViewModels by default.** Use `@State` with a `ViewState` enum directly in the view. The view IS the view model.
- The deliberate exception is an `@Observable` state owner (`SessionDetailModel`, `ClipPlaybackController`): add one only when the state owns an imperative resource (audio engine, timers, callbacks), or when a screen's state and side effects can't fit in a view under 200 lines. Never one per screen by reflex. It holds the `ViewState`, doesn't import `DesignSystem`, and is unit-tested.
- A view that loads asynchronously defines a `ViewState` enum: `.loading`, `.loaded`, `.error`, plus `.empty` when the screen has an empty state. No boolean soup (`isLoading`, `hasError`, `isEmpty`). A view backed only by `@Query` has no loading phase, so it reads the query directly and needs no enum.
- `@State` for view-local. Shared services resolve from the container (`@Injected`). `@Environment` only for `RouterPath` and SwiftUI system values. Nothing in between.
- Never nest `@Observable` inside another `@Observable`. It breaks observation.
- Wrap state transitions in `withAnimation` when they affect the UI.

### Dependencies

- **Views** (`Sources/Views/`, `Sources/Components/`) resolve shared services with `@Injected(\.service)` from the Factory container and never take a service through `init`, not even to pass it down to a child (e.g. `theme`). Why: views aren't unit-tested, the container already lets previews and tests swap a service, and one way to get a dependency keeps 100+ views consistent. Enforced by `check-layering.py` (rule 6).
- **Non-view types with logic worth testing** (Env services, `@Observable` state owners like `SessionDetailModel`, helpers like `CustomMelodyRecorder`) do the opposite: they take collaborators as `init` parameters that default to the container, so a test passes fakes directly (see `SessionCommitterTests`).
- Shared services are singletons with `.shared`, usually `@MainActor @Observable` (the exceptions are `SessionRawLogWriter`, an actor, and `StorageLimitEnforcer`, which is `Sendable`: their factories aren't `@MainActor`). They are registered in the container (`Packages/Env/Sources/Services/Container.swift`; DesignSystem registers `Theme` in its own). Feature packages and DesignSystem never access an app service's `.shared` (enforced by `check-layering.py`). Env services take collaborators as init parameters defaulting to the container (`init(preferences: any UserPreferencesStoring = Container.shared.userPreferences())`), so dependencies are visible and replaceable in tests.
- **Every service sits behind a protocol** (ADR 0002) named for its role (`HealthKitSyncing`, `AudioRecording`, `UserPreferencesStoring`, …), declared in its own file named after the protocol, next to the concrete type (`AudioRecording.swift` beside `AudioRecorder.swift`). Factories are typed `Factory<any P>` and resolve `.shared`. The one exception is Env's internal session composition (`sessionRecordingController`, `realtimeDetectionTracker`): these are concrete types owned only by `SessionManager`, so they are constructed in the factory and never used outside Env. Inits are public, never `private`. Pass services around as `any P`, never as the concrete type.
- **Every protocol has a test double** in `EnvTestSupport` (`FakeX`). The exceptions are the `UserDefaults`-backed stores (`UserPreferences.isolated()`, `AppConfig.isolated()`, the real type on a throwaway suite) and `Theme` (a separate `Theme()`). Tests override with `Container.shared.x.register { fake }` inside `@Suite(.container)` / `@Test(.container)` from `FactoryTesting`, so registrations are scoped per test.
- `@Observable` classes must NOT use `@Injected` — both macros synthesize underscore backing storage and collide (compile error). Resolve via `Container.shared.service()` in init.
- Nonisolated code (Apple delegate methods, detached tasks) resolves via Factory's global `dependency(\.service)` — property wrappers are MainActor-bound.
- The app target is the composition root: `SleepGuardApp`/`MainTabView` hold `.shared` references directly. FactoryKit is not an app-target dependency.
- `RouterPath` is the deliberate exception — it stays SwiftUI `.environment` (tab-owned navigation stacks). Sheets receive it via `.withEnvironments()` (RouterPath-only).

### Navigation

- All navigation goes through `RouterPath`. No manual `NavigationLink(destination:)`.
- Every screen is a case in `RouterDestination` (push) or `SheetDestination` (modal).
- Each tab owns its own `RouterPath`. Navigation never leaks across tabs.

### Concurrency

- `async/await` everywhere. No Combine, no GCD, no completion handlers.
- `.task { }` for data loading. `.task(id:)` when load depends on a changing value.
- `Task { }` only in event handlers (`onChange`, button actions).
- Always check `Task.isCancelled` before setting error state.
- **Swift 6 everywhere**: language mode v6 + strict concurrency complete. Sendable/isolation violations are compile errors — fix them properly (value types, `let`, `nonisolated`), never `@unchecked Sendable`.
- **Isolation split**: explicit `@MainActor` on all `@Observable` classes in Models/Env/AudioEngine (load-bearing — no package default isolation); the 8 UI packages declare `.defaultIsolation(MainActor.self)` and the app target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
- Value types are `Sendable` with immutable `let` properties. SwiftData `@Model` classes are never Sendable — destructure their Sendable fields (`id`, `Date`, bursts) before crossing into `@Sendable`/detached closures.
- Apple delegates (WCSession, SNResultsObserving, AVAudioPlayerDelegate) are nonisolated: mark methods `nonisolated`, parse payloads synchronously, `Task { @MainActor in }` for state mutation. See `docs/architecture/concurrency.md`.
- **Live detection is one ordered stream into an actor** (ADR 0003). Detection rules live only in the pure `DetectionStateMachine` (`SleepCore`, in the shared `SleepGuardShared` repo): no clock, no singletons, no SwiftData. Anything that changes detection state (sample, melody start/stop, settings, session end) goes into the `DetectionEngine` stream as a timestamped `Message`; never mutate detection state from a side path. Side effects stay on the main actor in `RealtimeDetectionTracker.perform`. Thresholds are durations, not sample counts. A change to detection output must re-record the replay goldens on purpose (`scripts/record-replay-goldens.sh`) and explain the diff.
- **Logging: never `print`.** Use `Log.<category>` (`audio`, `detection`, `session`, `interrupter`, `storage`, `playback`, `app`; `os.Logger`, in `Models/Sources/Helpers/Log.swift`). `.debug` for traces, `.info` milestones, `.notice` notable state, `.error` failures, `.fault` should-never-happen. Strings are private by default; add `privacy: .public` only for values that can't identify the user. Logger interpolations are autoclosures, so instance properties need `self.` (SwiftFormat keeps it via `--selfrequired`). Enforced by `check-layering.py`.

### Views

- Views are small, focused, and composable. Extract when a view does two things.
- Container views load data. Child views are presentational (receive data via init).
- Loading states use redacted placeholders, not spinners.
- Pull-to-refresh fires haptics via `HapticManager`.
- Platform branching: `#if !os(visionOS)` for custom backgrounds.
- **Accessibility (F23-T11):** icon-only buttons use `Label(Strings.x, systemImage:).labelStyle(.iconOnly)`, never a bare `Image`. A custom-drawn view (`Canvas`, shapes, gauges) gets one element with `.accessibilityLabel` + `.accessibilityValue`; a card that shows a value and a title reads as one element (`.accessibilityElement(children: .ignore)`). Purely decorative visuals are `.accessibilityHidden(true)`. Spoken text lives under `a11y.*` keys.

### View Componentization (Hard Limits)

These thresholds prevent monolithic views. Enforce them during implementation and code review.

**File size limits:**
- No view file should exceed **200 lines**. If it does, split it.
  Enforced in CI by `scripts/check-view-size.py` (`Sources/Views/`, `Sources/Components/`). Existing offenders sit in its `ALLOWLIST` with a reason and a line ceiling; they may shrink, never grow. Never add a new entry to get a PR through: split the file.
- A container view (with `switch viewState`) should be **≤100 lines**. State views (`.loading`, `.empty`, `.loaded`, `.error`) live in separate files.

**What to extract into separate files:**
- State-specific views: `[Feature]EmptyView`, `[Feature]ErrorView`, `[Feature]LoadedView`
- Reusable rows/cards: `[Feature]RowView`, `[Feature]StatCard`, `[Feature]EventRow`
- Full-screen overlays: `AlarmOverlayView`, `PermissionOverlayView`
- Shared visualization components used by 2+ packages: move to `DesignSystem`

**What stays inline (fine as private computed properties):**
- Simple headers, badges, or labels under 10 lines
- One-off buttons that are not reused
- Private helper formatting functions

**Computed `some View` boundaries (review rule):**
- A computed `some View` property shares its parent's invalidation boundary — it reorganizes code but does not reduce re-evaluation cost. Prefer a dedicated `View` struct when the section is complex (> ~20 lines), reads `@State`/`@Observable`/environment values, or is built per-item inside a `ForEach` (changing parameters per call).
- Small, static sections (no state reads, no parameters) may stay as computed properties.
- During review, run: `grep -rnE '^\s+(private )?var \w+: some View' Packages --include='*.swift'` and check new/changed hits against this rule.

**Duplication rule:**
- If the same view struct appears in 2+ files, extract it to `DesignSystem` immediately. Do not copy-paste view code.

### Packages

- Feature packages never import other feature packages. Only: Models, AudioEngine, Env, Routing, DesignSystem (the one existing edge: Settings → Personalization).
- **Shared repo.** `../SleepGuardShared` (its own git repo, checked out next to this one) holds code shared with the other SleepGuard apps: `SleepCore` (sleep score, detection state machine, the plain value types stored in the models) and `SleepStrings` (the string catalog). Packages depend on it by path and `import SleepCore` where they name its types. A change there changes every app, so run its tests (`sh scripts/run-tests.sh` in that repo) as well as this repo's. See `docs/adr/0004-shared-repo.md`.
- Navigation types (`RouterDestination`, `SheetDestination`, `RouterPath`) live in the leaf `Routing` package, not `Env`. `Env` must not import `SwiftUI` (enforced by `check-layering.py`). See `docs/adr/0001-routing-package.md`.
- Architecture decisions are recorded in `docs/adr/` (`NNNN-slug.md`: context, decision, consequences with honest limits, alternatives). Write one when a task changes a boundary, a rule in this file, or a trade-off a reviewer would question.
- The app target is the only place that imports everything.
- 2-space indentation. Enforced by `.swiftformat`.

### UI Dependencies in Non-View Code

View files (`Sources/Views/`, `Sources/Components/`) own everything visual:
`Theme`, `Strings` label mappings, colors, fonts. Non-view code must not.

- State owners, helpers, services, and models must NOT import `DesignSystem`
  for UI chrome. Helpers expose logic (enums, predicates, state); the view
  maps to `Strings`/`Theme`.
- Core packages (`Models`, `AudioEngine`) must not import `SwiftUI`/`UIKit`/
  `DesignSystem` at all.
- Allowed exceptions: content engines whose output IS user-facing text
  (`Personalization/Engine/BriefingEngine.swift`, `QuoteBank.swift`) may use
  `Strings`; audio infrastructure
  (`AudioEngine/Sources/Engine/AudioRecorder.swift`) may import `UIKit` for
  session-interruption observation.
- Enforced by `scripts/check-layering.py` on every push/PR
  (`.github/workflows/layering.yml`). Run locally before committing non-view
  code: `python3 scripts/check-layering.py`.

## SwiftData Schema Rules

SwiftData lightweight migration is automatic for additive changes, but **removing or renaming properties will crash on launch** for existing users. Follow these rules to keep the schema future-proof without migration plans.

### Safe changes (no migration needed)
- **Add new stored properties with default values** — SwiftData auto-migrates
- **Add new optional properties** — auto-migrates
- **Add new model types** — auto-migrates
- **Add new `@Relationship` properties** — auto-migrates

### Breaking changes (will crash existing installs)
- **Removing a property** from a `@Model` class
- **Renaming a property**
- **Changing a property's type** (e.g. `Int` → `Double`)
- **Changing non-optional to optional** without a default
- **Removing a model class entirely**

### Defensive schema policy
> **Never remove or rename a `@Model` property. Only add new ones with defaults. If a property is no longer needed, deprecate it in code but leave it in the schema.**

SwiftData ignores unused columns in the persistent store. This is the only zero-migration way to evolve schemas.

### Versioned schema (F22-T11)
Every `ModelContainer` (app and `TestStore`) opens through `SleepGuardSchema.container(_:)`, which attaches `SleepGuardMigrationPlan` (`Packages/Models/Sources/Data/SleepGuardSchema.swift`). Today the plan has one version (`SleepGuardSchemaV1`, pointing at the live `@Model` classes) and no stages. Additive changes still need nothing: keep following the policy above.

**Adding V2** (only for a change the policy above forbids, e.g. dropping `@Attribute(.unique)`):
1. Freeze V1: copy the current `@Model` classes into `SleepGuardSchemaV1` as nested types, unchanged, and make `models` list those copies.
2. Declare `SleepGuardSchemaV2` (version `2.0.0`) listing the live classes, then make the change on the live classes.
3. Append V2 to `SleepGuardMigrationPlan.schemas` and add a `MigrationStage` (`.lightweight` if SwiftData can infer it, `.custom` otherwise). Point `SleepGuardSchema.Current` at V2.
4. Add a test in `SleepGuardSchemaTests` that writes a V1 store on disk and opens it through the plan with every row intact.
5. Verify on a simulator that holds real pre-change data before merging. The app's container fallback deletes the store when opening fails.

### Cached computed properties on `SleepSession`
`SleepSession` carries four defensive cached properties to avoid relationship faulting crashes:

```swift
public var hasCachedScore = false
public var cachedSleepScore = 0
public var cachedSnoringDuration: TimeInterval = 0
public var cachedScoreVersion = ""   // SleepScore.cacheVersion(for:) of the formula + config
```

These are **necessary** — do not remove them. `sleepScore` and `snoringDuration` are computed from `events`, and faulting `session.events` has crashed in production. The cached values provide a zero-faulting read path. The version stamp makes a cache stale when the formula or `SleepScoreConfig` changes; `SleepSession.refreshStaleCachedScores(in:config:)` recomputes stale sessions at launch.

**Rules when modifying sessions:**
- Never write the cached fields by hand. `refreshCachedScore(using:)` (`Packages/Models/Sources/Data/SleepScoreCache.swift`) is their single writer: it recomputes from events and stamps the version.
- Call it **after** `modelContext.insert(session)`, never before. SwiftData snapshots at insertion time; pre-insertion mutations on `@Model` objects are **not tracked**. The caller saves.
- Saving a finished night goes through `SessionCommitter` only. Any code that changes a session after its initial save (e.g. `SessionDetailModel` adding `sleepStageSegments` from HealthKit) calls `refreshCachedScore(using:)` before `modelContext.save()`.

## Architecture Reference

Read these docs when building features. Reference only what you need per prompt. `docs/TECHNICAL_OVERVIEW.md` (in the repo) is the verified whole-system reference; the `docs/architecture/` notes are local only (gitignored). If a note disagrees with this file, this file wins.

| Doc | When to Read |
|-----|-------------|
| `docs/TECHNICAL_OVERVIEW.md` | Whole-system reference: packages, detection, score, DI, CI |
| `docs/architecture/INDEX.md` | Quick orientation |
| `docs/architecture/feature-template.md` | Building any new feature |
| `docs/architecture/navigation.md` | Adding routes, sheets, deep links |
| `docs/architecture/state.md` | State management questions |
| `docs/architecture/dependencies.md` | DI, shared services, environment |
| `docs/architecture/views.md` | UI composition, styling |
| `docs/architecture/concurrency.md` | Swift 6 isolation, async patterns, cancellation |
| `docs/architecture/modules.md` | Package structure, isolation |
| `docs/architecture/rules.md` | Audit code against rules |

## Workflow

Follow `docs/CODING_WORKFLOW.md` for the full development process. The core loop:

```
SESSION START
  1. Read docs/FeatureTracker.md — know project state instantly
  2. Read Notion tasks (Kanban, blockers, Sprint Log)
  3. Pick highest priority unblocked task

PER TASK (one prompt does all of this)
  4. Write prompt with BEFORE CODING + IMPLEMENTATION + AFTER VERIFIED
     ├─ Before:  Local tracker + Notion → "In Progress"
     ├─ Code:    Build the thing, verify with XcodeBuildMCP
     └─ After:   Local tracker + Notion → "Done", check unblocked
  5. Review output, fix if needed

FEATURE COMPLETE
  9. Create docs/features/f#-name.md
  10. Update ProjectArchitecture.md
  11. Set feature "Done" in Notion

SESSION END
  12. Update Sprint Log in Notion
  13. Final sync FeatureTracker with Notion
```

## Local Tracker (Auto-Updated)

Kimi auto-updates `docs/FeatureTracker.md` and `docs/trackers/*.md` after every task.
Local tracker updates happen FIRST — they survive session loss and are the primary source of truth.
Templates: `docs/templates/FeatureTracker.md` and `docs/templates/feature-tracker-detail.md`.

## Build & Report

After every task: build the project. Zero errors before moving on.

Use XcodeBuildMCP for builds:

**Session defaults** (project, scheme, simulator) are already pinned in `.xcodebuildmcp/config.yaml`. Check them once per session with `mcp__XcodeBuildMCP__session_show_defaults`; set them only if they're missing:
```
mcp__XcodeBuildMCP__session_set_defaults simulatorId: "BD630AD5-5A05-4663-8F1B-A17283EBCBF5" simulatorPlatform: "iOS Simulator"
```

**Then build/test:**
```
# Build
mcp__XcodeBuildMCP__build_sim

# Or build + run
mcp__XcodeBuildMCP__build_run_sim

# Test
mcp__XcodeBuildMCP__test_sim
```

**Why `simulatorId`:** device names are ambiguous across runtimes (e.g. `iPhone 17 Pro` exists on iOS 18.3, 26.0, and 26.2). The UDID pins one simulator (iPhone 16e, iOS 26.2) and eliminates flakiness.

**Package tests:** `sh scripts/run-tests.sh` (all packages) or `sh scripts/run-tests.sh Models Env`. It runs them on the iOS Simulator; don't use `swift test`, which builds for macOS.

**Fallback (Shell):**
```bash
xcodebuild -project SleepGuard.xcodeproj -scheme SleepGuard -destination 'platform=iOS Simulator,id=BD630AD5-5A05-4663-8F1B-A17283EBCBF5' build
```

## Session End Requirements

At the end of every coding session — even if mid-feature — you MUST produce detailed documentation. This is non-negotiable. The user reviews this to understand what was built and why.

Include:
- **Files changed:** [list every file touched]
- **What changed:** [one line per file]
- **Follow-up needed:** [anything requiring a decision]
- **Suggested branch**: `feature/[f#]/[t#]-short-description`
- **Suggested commit**: `[Task ID] — [Short description]` with bullet list of changes

> ⚠️ **Never omit Suggested branch and Suggested commit.** The user relies on these for git bookkeeping. This is part of the handoff.

### 1. Write a new session fragment in `docs/sessions/`

**Never append to a single shared file.** Create one new fragment file
`docs/sessions/[Date]-[short-slug].md` (e.g. `docs/sessions/2026-06-10-snore-filter.md`).
One session = one file. This is what keeps the log branch-proof: branches only
ever add files, so session logs can never merge-conflict.

**Do not write a session number.** Numbers are derived at compile time
(`python3 scripts/compile-sessions.py` continues numbering from the frozen
archive). The fragment only needs `date`, `feature`, `branch`, and `title` in
frontmatter. See `docs/sessions/README.md` for the full convention.

Use the fragment template in `docs/sessions/README.md` (sections: Completed, Technical Details,
Files Changed, Architecture Decisions, Build Status, Suggested Branch, Suggested Commit,
Changes done, Next Session, Open Questions). Read it before writing the fragment.

### 2. Create Feature Doc When Feature Ships

When ALL tasks in a feature are Done, create `docs/features/f[#]-[name].md` with:
- **Files table**: every file created/modified, with purpose
- **Routes table**: push and sheet destinations added
- **State table**: what state, where stored, scope
- **Edge cases**: how they're handled
- **Tasks Completed**: list all task IDs

See `docs/CODING_WORKFLOW.md` Phase 3 Step 4 for the full template.

### 3. Update Trackers

After every task (not just session end):
- `docs/trackers/f#-name.md` — check acceptance criteria, fill "Prompt Used" and "Notes"
- `docs/FeatureTracker.md` — dashboard counts, activity log, currently active, up next

### Why This Matters

The user cannot read your mind. They need to know:
- What code was written and where it lives
- Why architectural decisions were made
- What tradeoffs exist
- What's ready to test
- What comes next
- What decisions are blocked on them

**Never end a session with just "Done."** That's a conversation ender, not a handoff.

## These Guidelines Are Working If

- Diffs are small and traceable to the request.
- No rewrites due to overcomplication.
- Clarifying questions come before implementation, not after mistakes.
- Every view that loads asynchronously has a `ViewState` enum, not boolean flags.
- No feature package imports another feature package.
- Notion and FeatureTracker always agree.