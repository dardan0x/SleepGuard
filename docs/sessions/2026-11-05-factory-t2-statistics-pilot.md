---
date: 2026-11-05
feature: f19
branch: feature/f19/t2-statistics-pilot
title: Factory DI Migration — T2 Statistics Pilot
---

### Completed
- F19-T2: Statistics package converted from `@Environment(Theme.self)` to `@Injected(\.theme)` — 17 view files. Pilot for the T3 fan-out across the remaining 5 feature packages.

### Technical Details
- Statistics' only environment-consumed services were `Theme` (17 sites) and `RouterPath` (5 sites). Theme migrated; **RouterPath deliberately stays `@Environment`** — see decision below.
- Each converted file gained `import FactoryKit` (alphabetical placement); `Packages/Statistics/Package.swift` gained the Factory dependency.
- No `#Preview` blocks exist in Statistics — the preview-mocking acceptance criterion is vacuous here; the pattern will be established where previews exist in T3 packages.
- Verified on simulator (iPhone 16e, iOS 26.2): empty-state dashboard renders; Calendar push via environment `RouterPath` works (Nov 2026 grid, month stats cards, legend); relaunch with `-generateMockData` produced the loaded dashboard (score gauge 84, week strip with session dots, stat cards, sleep stages timeline) — all themed through `@Injected(\.theme)`.
- "Reacts to service state": demonstrated via `RouterPath` navigation (service state → NavigationPath push → UI). Runtime theme switching is not demonstrable — the build hardcodes Always Dark (`SettingsAppearanceSection` is display-only, no picker exists).

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Statistics/Package.swift` | +2 | Factory SPM dependency + FactoryKit product |
| `Packages/Statistics/Sources/Views/*.swift` (17 files) | ~2 each | `@Environment(Theme.self)` → `@Injected(\.theme)`; `import FactoryKit` added |

### Architecture Decisions
- **RouterPath stays in the environment (pilot finding, applies app-wide)**: `@Injected` with Factory's `.unique` scope would give every view its own `RouterPath` — pushed navigation would target orphaned `NavigationPath`s and break. `.shared` scope is equally wrong (weak cache dies with the first requesting view). Tab-owned navigation stacks are exactly what SwiftUI environment propagation is for. Consequence: T3 shrinks `withAppDependencyGraph()`/`withEnvironments()` to inject only `RouterPath` — they do not disappear entirely.
- **sed-based mechanical swap** for the 17 identical one-line sites, then grep-verified: zero `@Environment(Theme` remain; all 5 RouterPath sites untouched; every `Injected` file imports FactoryKit.

### Build Status
- **BUILD SUCCEEDED** — `build_sim` after conversion (first MCP call timed out at 60s; build completed server-side with zero errors, confirmed by a follow-up incremental build in 14.4s)
- `python3 scripts/check-layering.py` — passed (219 files scanned)
- Runtime verified on simulator — see Technical Details

### Suggested Branch
`feature/f19/t2-statistics-pilot` (work committed and pushed)

### Suggested Commit
`[F19-T2] — Statistics pilot: Theme via @Injected` (already committed)

### Changes done
```
- Packages/Statistics/Package.swift (+2)
- 17 Statistics views: @Environment(Theme.self) → @Injected(\.theme)
```

### Next Session
- F19-T3 (`feature/f19/t3-ui-packages-migration`): fan out to SleepSession → Recordings → Settings → Personalization → Onboarding → Learn; shrink `withAppDependencyGraph`/`withEnvironments` to RouterPath-only after the last consumer migrates.

### Open Questions
- None new. (Noted: `RouterPath` env-injection design from the pilot — recorded in T3's task notes.)
