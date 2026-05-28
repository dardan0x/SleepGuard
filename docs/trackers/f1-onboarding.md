# F1 — Onboarding

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P0 |
| **Version** | V1.1 |
| **Blocked By** | — |
| **Started** | 2026-05-06 |
| **Completed** | 2026-05-27 |
| **Feature Doc** | — |

## Summary

6-screen horizontal swipeable paging flow shown once on first launch. Handles HealthKit permission, microphone permission, sets `hasCompletedOnboarding` flag, and routes to Statistics empty state on completion. Playful/calm tone with subtle native SwiftUI animations.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F1-T1 | Onboarding state + UserPreferences flag | State | Done | — | Env | 2026-05-06 | 2026-05-06 |
| F1-T2 | Onboarding screens 1–3 UI | UI | Done | F1-T1 | Onboarding | 2026-05-06 | 2026-05-06 |
| F1-T3 | Onboarding screen 4 — mic permission | UI | Done | F1-T2 | Onboarding | 2026-05-06 | 2026-05-06 |
| F1-T4 | Onboarding screen 5 — motivation + routing | UI | Done | F1-T3 | Onboarding | 2026-05-06 | 2026-05-06 |
| F1-T5 | Route registration + app entry gate | Wiring | Done | F1-T4 | App | 2026-05-06 | 2026-05-06 |
| F1-T6 | Onboarding screen — Health & Watch permission | UI | Done | F1-T3 | Onboarding | 2026-05-27 | 2026-05-27 |

## Task Details

### F1-T1 — Onboarding state + UserPreferences flag

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/state.md, docs/architecture/dependencies.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] `UserPreferences` has `hasCompletedOnboarding: Bool` backed by `@AppStorage`
- [ ] `UserPreferences` is `@MainActor @Observable` singleton with `.shared`
- [ ] Registered in `withAppDependencyGraph()`
- [ ] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_(decisions, issues, deviations)_

---

### F1-T2 — Onboarding screens 1–3 UI

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] Screen 1: Friendly hook with moon mascot, floating Zs, headline, playful pill, CTA
- [ ] Screen 2: Three feature cards (sleep score, snore detection, sleep trends)
- [ ] Screen 3: Privacy shield animation, headline, subtext, green privacy chip
- [ ] Horizontal swipe paging with progress dots (active dot expands to pill)
- [ ] Skip button top-right, Back link on intermediate pages
- [ ] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_(decisions, issues, deviations)_

---

### F1-T3 — Onboarding screen 4 — mic permission

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] Pulsing concentric rings around mic icon
- [ ] Explanation copy about on-device processing
- [ ] Primary CTA triggers `AVAudioSession.requestRecordPermission`
- [ ] Secondary CTA skips permission (can enable later in Settings)
- [ ] If permission already granted, auto-advance or show confirmation
- [ ] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_(decisions, issues, deviations)_

---

### F1-T4 — Onboarding screen 5 — motivation + routing

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md, docs/architecture/navigation.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] Cozy bed scene with animated Zs
- [ ] Headline: "Ready for your first night?"
- [ ] Primary CTA routes to Live Session recording screen
- [ ] Secondary CTA routes to Statistics empty state
- [ ] Sets `hasCompletedOnboarding = true`
- [ ] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_(decisions, issues, deviations)_

---

### F1-T5 — Route registration + app entry gate

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/navigation.md, docs/architecture/dependencies.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] App entry checks `hasCompletedOnboarding`: false → OnboardingView, true → MainTabView
- [ ] Onboarding routes registered in RouterDestination/SheetDestination if needed
- [ ] Onboarding package properly wired in app target
- [ ] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_(decisions, issues, deviations)_

---

### F1-T6 — Onboarding screen — Health & Watch permission

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-27 |
| Completed | 2026-05-27 |

**Acceptance Criteria:**
- [x] Health & Watch illustration with concentric green rings, bed icon, heart icon, accent dot
- [x] Title: "See your sleep inside and out 🏥⌚"
- [x] Body copy about sleep stage breakdowns and smartwatch pairing
- [x] Privacy pill: "All health data stays on your device"
- [x] Primary CTA requests HealthKit authorization via `HealthKitSync.requestAuthorization()`
- [x] Granted state: button turns green with "Health connected" + white dot
- [x] 0.8 s delay after grant before auto-advance so user sees confirmation
- [x] Secondary CTA: "Skip for now" — advances without requesting
- [x] Progress dots updated to 6 pages (was 5)
- [x] Builds with zero errors

**Prompt Used:**
User requested creating the Health & Watch onboarding screen in the app based on the design in `designs/SleepGuard.pen`. Screen inserts between Privacy (page 3) and Microphone (now page 5) in the onboarding flow.

**Notes:**
- Same 0.8 s grant-delay pattern also added to `OnboardingPage4View` (Microphone permission) for consistency
- Design file `designs/SleepGuard.pen` updated: QtMq1 moved into main onboarding flow, all 7 screen variants now show 6 dots
- `OnboardingView.totalPages` changed from 5 → 6

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
