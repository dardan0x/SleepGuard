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

## SwiftUI Rules

These are non-negotiable. They come from production patterns in apps like IceCubesApp.

### State

- **No ViewModels.** Use `@State` with a `ViewState` enum directly in the view. The view IS the view model.
- Every data-loading view defines: `.loading`, `.loaded`, `.error`. No boolean soup (`isLoading`, `hasError`, `isEmpty`).
- `@State` for view-local. `@Environment` for shared. Nothing in between.
- Never nest `@Observable` inside another `@Observable`. It breaks observation.
- Wrap state transitions in `withAnimation` when they affect the UI.

### Dependencies

- All dependencies flow through `@Environment`. Never init-inject.
- Shared services are `@MainActor @Observable` singletons with `.shared`.
- Wire everything through one `withAppDependencyGraph()` function at the app root.
- Sheets live in a separate window — they lose environment. Always call `.withEnvironments()`.

### Navigation

- All navigation goes through `RouterPath`. No manual `NavigationLink(destination:)`.
- Every screen is a case in `RouterDestination` (push) or `SheetDestination` (modal).
- Each tab owns its own `RouterPath`. Navigation never leaks across tabs.

### Concurrency

- `async/await` everywhere. No Combine, no GCD, no completion handlers.
- `.task { }` for data loading. `.task(id:)` when load depends on a changing value.
- `Task { }` only in event handlers (`onChange`, button actions).
- Always check `Task.isCancelled` before setting error state.
- All views and `@Observable` classes are `@MainActor`.
- All models are `Sendable` with immutable `let` properties.

### Views

- Views are small, focused, and composable. Extract when a view does two things.
- Container views load data. Child views are presentational (receive data via init).
- Loading states use redacted placeholders, not spinners.
- Pull-to-refresh fires haptics via `HapticManager`.
- Platform branching: `#if !os(visionOS)` for custom backgrounds.

### Packages

- Feature packages never import other feature packages. Only: Models, Network, Env, DesignSystem.
- The app target is the only place that imports everything.
- One endpoint enum per API resource. One file per enum.
- 2-space indentation. Enforced by `.swiftformat`.

## Architecture Reference

Read these docs when building features. Reference only what you need per prompt.

| Doc | When to Read | Lines |
|-----|-------------|-------|
| `docs/architecture/INDEX.md` | Quick orientation | 28 |
| `docs/architecture/feature-template.md` | Building any new feature | 242 |
| `docs/architecture/navigation.md` | Adding routes, sheets, deep links | 137 |
| `docs/architecture/state.md` | State management questions | 116 |
| `docs/architecture/networking.md` | Models, endpoints, API calls | 154 |
| `docs/architecture/dependencies.md` | DI, shared services, environment | 114 |
| `docs/architecture/views.md` | UI composition, styling | 121 |
| `docs/architecture/concurrency.md` | Async patterns, cancellation | 95 |
| `docs/architecture/modules.md` | Package structure, isolation | 60 |
| `docs/architecture/rules.md` | Audit code against rules | 52 |

## Workflow

Follow `docs/VIBE_CODING_WORKFLOW.md` for the full development process. The core loop:

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

```
# Build
mcp__XcodeBuildMCP__build_sim_name_proj projectPath: "[path]" scheme: "[scheme]" simulatorName: "iPhone 16e"

# Test
mcp__XcodeBuildMCP__test_sim scheme: "[TestScheme]"
```

End every task with:
- **Files changed:** [list every file touched]
- **What changed:** [one line per file]
- **Follow-up needed:** [anything requiring a decision]

## These Guidelines Are Working If

- Diffs are small and traceable to the request.
- No rewrites due to overcomplication.
- Clarifying questions come before implementation, not after mistakes.
- Every view has a `ViewState` enum, not boolean flags.
- No feature package imports another feature package.
- Notion and FeatureTracker always agree.
