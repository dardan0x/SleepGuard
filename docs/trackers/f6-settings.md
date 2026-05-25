# F6 — Settings

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P2 |
| **Version** | V1.0 |
| **Blocked By** | — |
| **Started** | 2026-05-06 |
| **Completed** | 2026-05-06 |
| **Feature Doc** | — |

## Summary

Configure detection sensitivity, recording options, data management (delete all recordings), appearance settings, and about section.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F6-T1 | Settings model + UserPreferences extensions | State | Done | — | Env | 2026-05-06 | 2026-05-06 |
| F6-T2 | SettingsView form UI | UI | Done | F6-T1 | Settings | 2026-05-06 | 2026-05-06 |
| F6-T3 | Data management + about | UI | Done | F6-T2 | Settings | 2026-05-06 | 2026-05-06 |

## Task Details

### F6-T1 — Settings model + UserPreferences extensions

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/state.md, docs/architecture/dependencies.md |
| Status | Done |
| Started | 2026-05-06 |
| Completed | 2026-05-06 |

**Acceptance Criteria:**
- [x] `UserPreferences` extended with: sensitivity (low/medium/high), recording options
- [x] All settings backed by `@AppStorage` (manual UserDefaults with access/withMutation)
- [x] `@MainActor @Observable` singleton pattern maintained
- [x] Builds with zero errors

**Prompt Used:**
Resume SnoreGuard. Read AGENTS.md, docs/FeatureTracker.md, docs/ProjectArchitecture.md, and the active feature tracker from docs/trackers/. Report state including which architecture doc the feature tracker references, then proceed with the next unblocked task following the workflow exactly — including Design Compliance: always reference designs/SnoreGuard.pen before building or modifying any view.

**Notes:**
Added `minSnoreDuration` (default 2s) and `maxClipLength` (default 30s) to UserPreferences to match design. Existing properties (`detectionSensitivity`, `saveAudioClips`, `appearance`) were already scaffolded in Phase 0.

---

### F6-T2 — SettingsView form UI

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-06 |
| Completed | 2026-05-06 |

**Acceptance Criteria:**
- [x] `SettingsView` with form sections
- [x] Detection sensitivity picker (low/medium/high)
- [x] Recording options toggles
- [x] Appearance settings (light/dark/system)
- [x] All controls bound to `UserPreferences`
- [x] Builds with zero errors

**Prompt Used:**
Same as F6-T1.

**Notes:**
Built complete SettingsView matching designs/SnoreGuard.pen:
- Title row with gear icon in accent circle
- Detection card: sensitivity slider (3-position), min snore duration stepper
- Recording card: save audio clips toggle, max clip length picker (confirmationDialog)
- Appearance card: theme picker (confirmationDialog)
- Data card: delete all recordings button
- About card: version static text, rate on App Store button
Applied `.preferredColorScheme` in SnoreGuardApp based on UserPreferences.appearance.

---

### F6-T3 — Data management + about

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-06 |
| Completed | 2026-05-06 |

**Acceptance Criteria:**
- [x] "Delete All Data" button with confirmation alert
- [x] Deletes all `SleepSession` and `SnoreEvent` records from SwiftData
- [x] About section with app version, privacy policy link, credits
- [x] Builds with zero errors

**Prompt Used:**
Same as F6-T1.

**Notes:**
Delete All uses `@Environment(\.modelContext)` with `FetchDescriptor<SleepSession>` and cascade delete via SwiftData relationship. Includes confirmation alert with destructive button. About section shows app version from Bundle and "Rate on App Store" link.

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
