
### Completed
- F24-T1: SleepGuard's theme starts from the shared design kit. `DesignSystem` depends on and re-exports `SleepGuardDesignKit`; the root view puts the kit theme in the SwiftUI environment for kit components (F24-T2 onwards).

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/DesignSystem/Package.swift` | Depends on `SleepGuardDesignKit` |
| `Packages/DesignSystem/Sources/Strings.swift` | Re-exports the kit |
| `Packages/DesignSystem/Sources/Components/AppTheme.swift` | Was `Theme.swift`; class renamed; tokens from `Theme.sleepGuard`; `designKitTheme`; duplicate `Color(hex:)` removed |
| `Packages/DesignSystem/Sources/Components/ThemeProviding.swift`, `Container.swift` | Comments name `AppTheme` |
| `Packages/DesignSystem/Tests/ThemeOverrideTests.swift` | `AppTheme()`; defaults equal the kit's theme; overrides reach it |
| `SleepGuard/SleepGuardApp.swift` | `.environment(\.theme, AppTheme.shared.designKitTheme)` |
| `SleepGuard/*.swift`, `SleepGuardWidgets/*.swift` | `Theme.shared` → `AppTheme.shared` |
| `AGENTS.md`, `CLAUDE.md` | `AppTheme`; tokens come from the kit |

### Technical Details
- Why the rename: with the kit re-exported, `Theme` would name both SleepGuard's class and the kit's value in every view.
- No visual change: the values are identical (tested).

### Open Questions
- `bg-card`: `#22232B` in code and kit, `#2C2C2E` in AGENTS.md. Needs the design file (Pencil) to decide.

### Build Status
- All 8 package suites pass; app (with widgets) builds; format, layering, view size pass. Still on shared `0.10.0` (the kit's `Theme` exists since `0.2.0`).
