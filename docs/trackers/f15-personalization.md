# F15 — Personalization & Sleep Briefing

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P1 |
| **Version** | V4 |
| **Blocked By** | — |
| **Started** | 2026-06-06 |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

Make SleepGuard feel personal: daily "Sleep Briefing" greets the user by name, recaps last night, notices trends, and gently asks what changed. Profile capture is dismissible and optional, reachable anytime from Settings. All data stays on-device.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F15-T1 | Personalization package scaffold | Scaffold | Done | — | Personalization | 2026-06-06 | 2026-06-06 |
| F15-T2 | UserProfile + LifestyleLog models | Model | Done | — | Models | 2026-06-06 | 2026-06-06 |
| F15-T3 | UserPreferences flags | Service | Done | — | Env | 2026-06-06 | 2026-06-06 |
| F15-T4 | BriefingEngine + value types | Engine | Done | F15-T2 | Personalization | 2026-06-06 | 2026-06-06 |
| F15-T5 | QuoteBank + localized strings | Engine | Done | F15-T4 | Personalization | 2026-06-06 | 2026-06-06 |
| F15-T6 | SleepBriefingView + subviews | UI | Done | F15-T4, F15-T5 | Personalization | 2026-06-06 | 2026-06-06 |
| F15-T7 | Profile editor views (4 steps) | UI | Done | F15-T2 | Personalization | 2026-06-06 | 2026-06-06 |
| F15-T8 | ProfilePromptCard | UI | Done | F15-T7 | Personalization | 2026-06-06 | 2026-06-06 |
| F15-T9 | Settings integration (Profile section + briefing toggle) | UI | Done | F15-T3, F15-T7 | Settings | 2026-06-06 | 2026-06-06 |
| F15-T10 | Router wiring (SheetDestination.profileEditor) | Route | Done | F15-T7 | Env | 2026-06-06 | 2026-06-06 |
| F15-T11 | SwiftData schema registration + app-level briefing trigger | App | Done | F15-T2, F15-T6 | SleepGuard | 2026-06-06 | 2026-06-06 |
| F15-T12 | Daily briefing trigger in MainTabView/StatisticsTab | UI | Done | F15-T11 | SleepGuard | 2026-06-06 | 2026-06-06 |
| F15-T13 | Localization strings for all UI | Localization | Done | — | DesignSystem | 2026-06-06 | 2026-06-06 |
| F15-T14 | Unit tests for BriefingEngine | Test | Backlog | F15-T4 | Personalization | — | — |
| F15-T15 | Build & verify | Build | Backlog | F15-T1–F15-T14 | SleepGuard | — | — |
| F15-T16 | Feature doc + tracker finalization | Docs | Backlog | F15-T15 | — | — | — |

## Task Details

### F15-T1 — Personalization Package Scaffold

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/modules.md` |
| Status | In Progress |
| Started | 2026-06-06 |
| Completed | — |

**Acceptance Criteria:**
- [x] `Packages/Personalization/Package.swift` created with deps on Models, Env, DesignSystem
- [x] Directory structure: `Sources/Engine/`, `Sources/Views/`
- [x] Package referenced in `SleepGuard.xcodeproj` as local package
- [x] App target links `Personalization` in Frameworks
- [x] Builds with zero errors

**Prompt Used:**
Implement F15-T1: Personalization package scaffold. Create `Packages/Personalization/Package.swift` with deps Models/Env/DesignSystem, create `Sources/Engine/` and `Sources/Views/` directories, add package reference to `SleepGuard.xcodeproj/project.pbxproj` as local package, add `Personalization` to app target Frameworks. Placeholder `BriefingEngine.swift` and `SleepBriefingView.swift` created for compilation.

**Notes:**
_(decisions, issues, deviations)_

---

### F15-T2 — UserProfile + LifestyleLog Models

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/networking.md` (data models) |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] `UserProfile` SwiftData `@Model` with all fields per plan
- [x] `LifestyleLog` SwiftData `@Model` with all fields per plan
- [x] Both models are `Sendable` with immutable `let` where possible
- [x] Enums defined (biological sex, primary goal, habit levels, occupation)
- [x] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**

---

### F15-T3 — UserPreferences Flags

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/state.md` |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] `lastBriefingShownDate: Date?` added to `UserPreferences`
- [x] `hasCompletedProfile: Bool` added
- [x] `profilePromptDismissCount: Int` added
- [x] `briefingEnabled: Bool` added (default true)
- [x] Follows existing `access`/`withMutation` getter/setter pattern
- [x] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**

---

### F15-T4 — BriefingEngine + Value Types

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/state.md`, `docs/architecture/views.md` |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] `Briefing` struct with greeting, headline, stats, insight, nudge, survey, scoreContext
- [x] `BriefingStat`, `ScoreTrend`, `SurveyPrompt` value types
- [x] `BriefingEngine.generate(profile:recentSessions:lifestyleLogs:now:)` pure function
- [x] Greeting by time-of-day, recap from latest session, insight from trends
- [x] No UI code; fully unit-testable
- [x] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**

---

### F15-T5 — QuoteBank + Localized Strings

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` (localization) |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] `QuoteBank` selects quote key by `ScoreTrend`
- [x] All keys added to `Localizable.xcstrings`
- [x] `Strings.swift` regenerated
- [x] No hardcoded strings in engine or views
- [x] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**

---

### F15-T6 — SleepBriefingView + Subviews

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] `SleepBriefingView` container ≤100 lines with `ViewState` enum
- [x] `BriefingGreetingHeader`, `BriefingRecapCard`, `BriefingInsightCard`, `BriefingSurveyCard`
- [x] Full-screen cover design matching app theme
- [x] All strings localized via `Strings.`
- [x] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**

---

### F15-T7 — Profile Editor Views (4 Steps)

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] `ProfileEditorView` container with 4-step TabView (page style)
- [x] `ProfileStepIdentityView`, `ProfileStepGoalsView`, `ProfileStepHabitsView`, `ProfileStepPersonalView`
- [x] Each step skippable; persistent privacy banner
- [x] All strings localized
- [x] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**

---

### F15-T8 — ProfilePromptCard

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] `ProfilePromptCard` dismissible card for Statistics tab
- [x] Shows after 3+ sessions, not completed, dismissed < 3 times
- [x] Taps open `ProfileEditorView` sheet
- [x] All strings localized
- [x] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**

---

### F15-T9 — Settings Integration

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] New "Profile" section in Settings with row to open editor
- [x] "Daily Sleep Briefing" toggle in Settings
- [x] Uses existing `SettingsSection`/`SettingsRow` patterns
- [x] All strings localized
- [x] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**

---

### F15-T10 — Router Wiring

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/navigation.md` |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] `SheetDestination.profileEditor` added to `Router.swift`
- [x] Handled in `AppRegistry.swift` `withAppRouter()`
- [x] Sheet wrapped with `.withEnvironments()`
- [x] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**

---

### F15-T11 — SwiftData Schema + App-Level Trigger

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/state.md` |
| Status | Done |
| Started | 2026-06-06 |
| Completed | 2026-06-06 |

**Acceptance Criteria:**
- [x] `UserProfile` and `LifestyleLog` registered in SwiftData schema in `SleepGuardApp.swift`
- [x] App-level `fullScreenCover` for briefing wired in `MainTabView` on both iOS 26+ and legacy paths
- [x] Briefing gate: `briefingEnabled && lastBriefingShownDate not today && hasAnySession`
- [x] Builds with zero errors

**Prompt Used:**
Implement F15-T11: Register `UserProfile.self` and `LifestyleLog.self` in SwiftData schema in `SleepGuardApp.swift`. Add `.fullScreenCover` to `MainTabView` (both system and custom tab paths) with briefing generation on `.task`. Gate: `briefingEnabled`, `lastBriefingShownDate` not today, at least one session exists. `onDismiss` saves the shown date. Chip tap creates and persists a `LifestyleLog` linked to the latest session.

**Notes:**
- `SleepGuardApp.swift` schema already had `UserProfile.self` and `LifestyleLog.self` from earlier (pre-registered).
- Fixed `Packages/Settings/Package.swift` to explicitly declare `Personalization` dependency, eliminating build warning.
- `saveLifestyleLog` maps chip text to bool fields by string comparison against localized keys.

---

### F15-T12 — Daily Briefing Trigger

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Done |
| Started | 2026-06-06 |
| Completed | 2026-06-06 |

**Acceptance Criteria:**
- [x] Trigger check on `MainTabView` appear (via `.task`)
- [x] Sets `lastBriefingShownDate = today` when shown (via `fullScreenCover` `onDismiss`)
- [x] Welcome variant for no sessions / first session (handled by `BriefingEngine` in T4)
- [x] Returning-after-gap variant (>3 days) (handled by `BriefingEngine` in T4)
- [x] Builds with zero errors

**Prompt Used:**
Merged into F15-T11 implementation.

**Notes:**
- `BriefingEngine` already handles `ScoreTrend.firstNight` and `ScoreTrend.returningAfterGap(days:)` from T4.

---

### F15-T13 — Localization Strings

| Field | Value |
|-------|-------|
| Arch Ref | AGENTS.md Localization section |
| Status | Done |
| Started | 2026-06-06 |
| Completed | 2026-06-06 |

**Acceptance Criteria:**
- [x] All `briefing.*`, `profile.*`, `settings.profile.*` keys in `Localizable.xcstrings`
- [x] `Strings.swift` regenerated
- [x] Grep confirms zero hardcoded user-facing strings in changed views
- [x] Builds with zero errors

**Prompt Used:**
Verification pass: grepped `Packages/Personalization/Sources/Views/`, `SleepGuard/StatisticsTab.swift`, `SleepGuard/SettingsTab.swift`, and `Packages/Settings/Sources/Views/SettingsProfileSection.swift` for `Text("[A-Z]` and `navigationTitle("` — zero hits. All user-facing strings trace to `Strings.*` accessors.

**Notes:**
- All 39+ briefing/profile strings were added in T5 and T7. No additional keys needed for T11/T12.

---

### F15-T14 — Unit Tests for BriefingEngine

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/state.md` |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] Tests for each `ScoreTrend` case
- [ ] Tests for greeting by time-of-day
- [ ] Tests for survey prompt gate (score swing + no log)
- [ ] Tests for returning-after-gap variant
- [ ] All tests pass

**Prompt Used:**
_(filled after task completion)_

**Notes:**

---

### F15-T15 — Build & Verify

| Field | Value |
|-------|-------|
| Arch Ref | AGENTS.md Build & Report section |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] Zero build errors
- [ ] Zero new warnings
- [ ] Simulator run: fresh install → no briefing; 3+ sessions → profile prompt; next day → briefing
- [ ] Score swing → survey chips → LifestyleLog persisted

**Prompt Used:**
_(filled after task completion)_

**Notes:**

---

### F15-T16 — Feature Doc + Tracker Finalization

| Field | Value |
|-------|-------|
| Arch Ref | AGENTS.md Session End Requirements |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] `docs/features/f15-personalization.md` created with full template
- [ ] Tracker status set to Done
- [ ] `FeatureTracker.md` updated: F15 Done, 16/16 tasks

**Prompt Used:**
_(filled after task completion)_

**Notes:**

---

## Update Rules (for the AI)

After completing a task in this feature:
1. Check off acceptance criteria boxes
2. Fill Started/Completed dates in task table and detail section
3. Set task Status to **Done**
4. Fill "Prompt Used" with the prompt summary
5. Add any notes about decisions or deviations
6. If ALL tasks are Done → set feature Status to **Done**, fill Completed date
7. Also update the index file (`docs/FeatureTracker.md`)
