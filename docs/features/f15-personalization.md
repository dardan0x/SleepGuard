# F15 — Personalization & Sleep Briefing

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Backlog |
| **Priority** | P1 |
| **Version** | V4.0 |
| **Blocked By** | — |
| **Started** | — |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

Personal, on-device sleep concierge. After a few recorded nights the app greets the user by name with a
once-per-day full-screen Sleep Briefing (recap → trend insight → motivational nudge → optional "what
changed?" micro-survey), driven by a pure, testable BriefingEngine. A dismissible prompt (after ≥3
recordings) and a Settings entry open an optional multi-step profile editor (identity, goals, lifestyle
baseline, hobbies). All data stored on-device only. New `Personalization` package (deps Models, Env,
DesignSystem); two new SwiftData models (`UserProfile`, `LifestyleLog`).

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F15-T1 | Create Personalization SPM package + Xcode/app wiring | Setup | Backlog | — | Personalization | — | — |
| F15-T2 | UserProfile + LifestyleLog models + schema registration | Model | Backlog | — | Models | — | — |
| F15-T3 | UserPreferences flags ×4 | State | Backlog | — | Env | — | — |
| F15-T4 | BriefingEngine + value types + QuoteBank (pure) | Engine | Backlog | T1, T2 | Personalization | — | — |
| F15-T5 | BriefingEngine unit tests | Test | Backlog | T4 | Personalization | — | — |
| F15-T6 | Briefing localization keys + Strings regen | Localization | Backlog | — | DesignSystem | — | — |
| F15-T7 | SleepBriefingView container + Greeting/Recap/Insight cards | UI | Backlog | T4, T6 | Personalization | — | — |
| F15-T8 | Once-per-day fullScreenCover trigger in MainTabView | Navigation | Backlog | T7 | App | — | — |
| F15-T9 | Settings Daily Briefing toggle | UI | Backlog | T3, T6 | Settings | — | — |
| F15-T10 | SheetDestination.profileEditor route + StatisticsTab wiring | Navigation | Backlog | — | Env / App | — | — |
| F15-T11 | ProfileEditorView + 4 optional steps + privacy banner | UI | Backlog | T2, T6, T10 | Personalization | — | — |
| F15-T12 | ProfilePromptCard + Statistics trigger (≥3 sessions) | UI | Backlog | T11 | Personalization | — | — |
| F15-T13 | Settings Profile section row | UI | Backlog | T10, T11 | Settings | — | — |
| F15-T14 | BriefingSurveyCard chips → LifestyleLog | UI | Backlog | T7, T2 | Personalization | — | — |
| F15-T15 | Build + simulator verification + feature doc | Verify | Backlog | T1-T14 | — | — | — |
| F15-T16 | Correlation insights after ~10 logs | Engine | Backlog | T14 | Personalization | — | — |

## Task Details

### F15-T1 — Create Personalization SPM package + Xcode/app wiring
| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/modules.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] `Packages/Personalization/Package.swift` mirrors Statistics (deps Models, Env, DesignSystem; no Charts)
- [ ] Package added to Xcode project; app target links Personalization; `AppRegistry` imports it
- [ ] Empty package builds with zero errors

### F15-T2 — UserProfile + LifestyleLog models + schema registration
| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/networking.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] `UserProfile` @Model (all optional fields, Codable enums) in Models
- [ ] `LifestyleLog` @Model (date, 6 Bool flags, note, sessionID) in Models
- [ ] Both registered in `Schema([...])` in `SleepGuardApp.swift`
- [ ] Builds; existing sessions migrate without loss

### F15-T3 — UserPreferences flags ×4
| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/state.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] `lastBriefingShownDate`, `hasCompletedProfile`, `profilePromptDismissCount`, `briefingEnabled` added
- [ ] Each uses the `access`/`withMutation` pattern; `briefingEnabled` defaults true
- [ ] Builds with zero errors

### F15-T4 — BriefingEngine + value types + QuoteBank (pure)
| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/concurrency.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] `BriefingEngine.make(profile:recentSessions:lifestyleLogs:now:)` pure, `import Models` only
- [ ] Returns `Briefing` with greeting/headline/stats/insight/nudge/survey/scoreContext
- [ ] Day-grouped trend computed internally (no Statistics/Recordings import)
- [ ] Survey gated on `|todayScore − rolling7dayAvg| ≥ 15` AND no log for that night
- [ ] Builds with zero errors

### F15-T5 — BriefingEngine unit tests
| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/concurrency.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] Test target on Personalization
- [ ] Synthetic sessions assert each ScoreTrend (improving/declining/steady/firstNight/noData/returningAfterGap)
- [ ] Survey offered/suppressed cases asserted
- [ ] All tests pass

### F15-T6 — Briefing localization keys + Strings regen
| Field | Value |
|-------|-------|
| Arch Ref | CLAUDE.md (Localization) |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] Keys added under briefing.* namespaces; interpolations use `*Format`
- [ ] `generate-strings.py` run; `Strings.swift` updated
- [ ] No raw literals introduced

### F15-T7 — SleepBriefingView container + cards
| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] Container ≤100 lines, `ViewState` switch (.loading/.loaded/.welcome/.error)
- [ ] Greeting/Recap/Insight cards reuse SleepScoreGauge / StatCard / SessionStatsGrid
- [ ] All strings via `Strings.`; builds with zero errors

### F15-T8 — Once-per-day fullScreenCover trigger
| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/navigation.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] `MainTabView` presents briefing once per day on first open
- [ ] Gate: `briefingEnabled && lastBriefingShownDate not today && !sessions.isEmpty`
- [ ] Sets `lastBriefingShownDate = today` on present; `.withEnvironments()` applied
- [ ] Builds with zero errors

### F15-T9 — Settings Daily Briefing toggle
| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] Toggle bound to `briefingEnabled` in a Settings section
- [ ] Localized; builds with zero errors

### F15-T10 — profileEditor route + StatisticsTab wiring
| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/navigation.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] `SheetDestination.profileEditor` case (+ `id`) in Router
- [ ] `StatisticsTab` `.sheet` switch handles it with `.withEnvironments()`
- [ ] Builds with zero errors

### F15-T11 — ProfileEditorView + 4 optional steps + privacy banner
| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] 4 TabView `.page` steps (Identity / Goals / Habits / Personal), each Skip-able, nothing mandatory
- [ ] Persistent on-device privacy banner (lock icon, OnboardingPage3 styling)
- [ ] Saves/creates the single `UserProfile`; sets `hasCompletedProfile`
- [ ] Each step file <200 lines; all strings localized; builds with zero errors

### F15-T12 — ProfilePromptCard + Statistics trigger
| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] Dismissible card shows when `completedSessions ≥ 3 && !hasCompletedProfile && profilePromptDismissCount < 3`
- [ ] Opens editor sheet; dismiss increments `profilePromptDismissCount`
- [ ] Hidden once `hasCompletedProfile`; localized; builds with zero errors

### F15-T13 — Settings Profile section row
| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] Profile row in Settings opens the editor (always available)
- [ ] Localized; builds with zero errors

### F15-T14 — BriefingSurveyCard chips → LifestyleLog
| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/state.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] Chip taps (context-specific up/down swing sets) persist a `LifestyleLog` for the night
- [ ] "Skip" dismisses with no nag; survey not re-shown for a night with an existing log
- [ ] Localized; builds with zero errors

### F15-T15 — Build + simulator verification + feature doc
| Field | Value |
|-------|-------|
| Arch Ref | docs/VIBE_CODING_WORKFLOW.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] Full simulator walkthrough (welcome / prompt→editor / daily briefing / survey / toggle-off) passes
- [ ] Zero hardcoded user-facing literals in changed views
- [ ] `docs/features/f15-personalization.md` created (Files / Routes / State / Edge cases / Tasks)

### F15-T16 — Correlation insights after ~10 logs
| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/concurrency.md |
| Status | Backlog |

**Acceptance Criteria:**
- [ ] When ≥10 `LifestyleLog` rows exist, engine surfaces a correlation line (e.g. "exercise nights +8")
- [ ] Pure + unit-tested; builds with zero errors

## Update Rules (for the AI)

After completing a task in this feature:
1. Check off acceptance criteria boxes
2. Fill Started/Completed dates in task table and detail section
3. Set task Status to **Done**
4. Fill "Prompt Used" with the prompt summary
5. Add any notes about decisions or deviations
6. If ALL tasks are Done → set feature Status to **Done**, fill Completed date
7. Also update the index file (docs/FeatureTracker.md)