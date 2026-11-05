---
date: 2026-11-05
feature: f19
branch: feature/f19/t3-ui-packages-migration
title: Factory DI Migration — T3 UI Packages Fan-out
---

### Completed
- F19-T3: All remaining UI packages migrated from `@Environment(X.self)` to `@Injected(\.x)` — 91 view files across SleepSession (28), Recordings (24), Personalization (12), Settings (11), Onboarding (7), DesignSystem components (7), Learn (2). App-target wiring reduced: `withAppDependencyGraph()` deleted, `withEnvironments()` now injects RouterPath only.

### Technical Details
- Bulk conversion via a deterministic python script (`@Environment(Type.self)` → `@Injected(\.lowerFirstType)`, RouterPath lines skipped, `import FactoryKit` inserted alphabetically); grep-verified zero remaining uppercase-type `@Environment` sites.
- Factory SPM dependency added to 6 Package.swift files (SleepSession, Recordings, Settings, Personalization, Onboarding, Learn). DesignSystem already had it from T1.
- **Found during build (missed by catalog): `LearnTab` consumed `TabCoordinator` via environment.** T1 had deliberately not registered it. Resolution: `TabCoordinator` gained `public static let shared` + `.singleton` container registration; `MainTabView` and all tabs now reference the same instance. This is the same aliasing pattern as the other 16 singletons.
- **Also missed by the initial (broken-regex) app-target grep: 12 `@Environment` sites in the app target** (StatisticsTab ×6, SettingsTab, SessionsTab, CustomTabBarView, SessionProcessingOverlay, NotificationSoftAskView ×3). Fixed by converting app-target views to direct `.shared` holdings (`let theme = Theme.shared`) — composition-root style, consistent with MainTabView/SleepGuardApp, avoids adding FactoryKit to the app target's pbxproj.
- `MainTabView`: 4 service environments → `@State` `.shared` holdings (composition root). `SleepGuardApp`: `withAppDependencyGraph` call removed; orphaned `theme` @State and `import AudioEngine` removed. `AppRegistry`: `withAppDependencyGraph` deleted; `withEnvironments()` reduced to `environment(RouterPath())`; 5 orphaned imports removed.
- `SettingsView` preview stripped of `.environment(...)` service injections (self-resolving now); DEBUG sheet's dead AppConfig/Theme injections removed.
- First launch crashed: `No Observable object of type Theme found` — the app-target sites above. Caught by runtime log inspection, fixed, re-verified.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| 91 package view files | ~2 each | `@Environment(X.self)` → `@Injected(\.x)`; `import FactoryKit` |
| 6 × `Packages/*/Package.swift` | +2 each | Factory SPM dependency + FactoryKit product |
| `Packages/Env/Sources/Services/Router.swift` | +2 | `TabCoordinator.shared` static |
| `Packages/Env/Sources/Services/Container.swift` | +1 | `tabCoordinator` singleton registration |
| `SleepGuard/MainTabView.swift` | ±8 | 4 env services → `@State` `.shared`; `TabCoordinator.shared` |
| `SleepGuard/StatisticsTab.swift` | ±6 | 6 env services → `let` `.shared` |
| `SleepGuard/SettingsTab.swift`, `SessionsTab.swift`, `CustomTabBarView.swift`, `SessionProcessingOverlay.swift`, `PushNotifications/NotificationSoftAskView.swift` | ~1-3 each | env services → `let` `.shared` |
| `SleepGuard/AppRegistry.swift` | −32 | `withAppDependencyGraph` deleted; `withEnvironments()` → RouterPath-only; orphaned imports removed |
| `SleepGuard/SleepGuardApp.swift` | −13 | `withAppDependencyGraph` call removed; orphaned `theme`/`import AudioEngine` removed |

### Architecture Decisions
- **App target holds `.shared` directly instead of `@Injected`**: the app target is the composition root; direct singleton references match the existing SleepGuardApp/MainTabView pattern and avoid a pbxproj change to link FactoryKit. Feature packages (reusable, previewed, tested) use `@Injected`. T5 will codify this split in the rules.
- **Single-commit fan-out**: one mechanical transformation across 91 files; per-package commits would add noise without review value (the diff is one repeated pattern).
- **Noted, not fixed (pre-existing)**: `MainTabView` injects `.environment(tabCoordinator)` but no view reads `TabCoordinator` from the environment anymore (all consumers now use `.shared`/container) — the injection is dead weight for T5 to remove. Hardcoded `Button("Debug Config")` in SettingsView (DEBUG-only, bypasses Strings) also predates this task.

### Build Status
- **BUILD SUCCEEDED** after fixes (first attempt failed on LearnTab — TabCoordinator unregistered; runtime then exposed the app-target env sites; both fixed, re-verified)
- `python3 scripts/check-layering.py` — passed (219 files scanned)
- Runtime verified on simulator: dashboard → recordings list → session detail → settings (live notification-permission state) → Learn web tab (appConfig-driven) → pop-to-root via tab re-tap (resetSignal through singleton TabCoordinator) → Profile editor sheet presented with RouterPath-only `withEnvironments()`

### Suggested Branch
`feature/f19/t3-ui-packages-migration` (work committed and pushed)

### Suggested Commit
`[F19-T3] — UI packages: @Environment -> @Injected fan-out` (already committed)

### Changes done
```
- 91 package views: @Environment(X.self) -> @Injected(\.x)
- 6 Package.swift: Factory dependency
- Env: TabCoordinator.shared + container registration
- App target: composition-root .shared holdings; withAppDependencyGraph deleted;
  withEnvironments() reduced to RouterPath
```

### Next Session
- F19-T4 (`feature/f19/t4-service-composition`): move internal hand-wired sub-components (SessionManager's SessionRecordingController/RealtimeDetectionTracker, etc.) into container factories; nonisolated delegates → `dependency(\.…)` global function.

### Open Questions
- T5 candidates discovered: dead `.environment(tabCoordinator)` in MainTabView; hardcoded DEBUG button string; direct `.shared` accesses in views (e.g. `UserPreferences.shared` in StatisticsTab closure, `HapticManager.shared`) that could become `@Injected` — decide scope in T5.
