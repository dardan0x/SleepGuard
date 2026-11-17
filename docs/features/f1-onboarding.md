# Feature: F1 — Onboarding

## Status: Done
## Completed: 2026-05-06

## Summary
First-launch onboarding flow that introduces the app, explains features, requests microphone permission with a visual pulsing animation, and gathers user motivation before routing to the main app.

## Files

> Updated 2026-11-17 (F26-T4): the pages are the shared `OnboardingContent` (`SleepGuardContentKit`), and the page rules are SleepCore's `OnboardingPages`. The table below is the code as it is now; the original F1 files are in git history.

| File | Purpose |
|------|---------|
| `Packages/Env/Sources/Services/UserPreferences.swift` | `hasCompletedOnboarding` and `presentRecordingAfterOnboarding` (UserDefaults keys of the same names) |
| `Packages/Onboarding/Sources/Views/OnboardingView.swift` | Hosts the shared content: the current page, the microphone and Health requests, finishing |
| `../SleepGuardShared/Sources/SleepGuardContentKit/Onboarding/*` | The pages, Skip, Back and the dots |
| `../SleepGuardShared/Sources/SleepCore/Onboarding/OnboardingPages.swift` | Which pages show, Next, Skip (to the last page), Back |
| `SleepGuard/SleepGuardApp.swift` | Gate: `OnboardingView` until `hasCompletedOnboarding`, then `MainTabView` (a root swap, no sheet) |

## Routes

None: the app root swaps between `OnboardingView` and `MainTabView`.

## State

| Property | Location | Scope |
|----------|----------|-------|
| `hasCompletedOnboarding` | `UserPreferences.shared` | App-wide (UserDefaults) |
| `presentRecordingAfterOnboarding` | `UserPreferences.shared` | Read once by `StatisticsTab` to open a night |
| page, permission states | `OnboardingView` @State | View-local |

## Edge Cases
- **Health page**: only when the `healthSync` remote flag is on. Granted turns on Health sync and enhanced tracking unless already chosen.
- **Permission already granted**: the page shows it granted on appear; no auto-advance.
- **Permission denied**: moves to the next page at once (no Open Settings button).
- **Granted**: "granted" shows for 0.8 s, then the next page.
- **Skip**: goes to the last page; onboarding finishes only from its buttons ("Start recording" or "Just browsing").
- **Back**: hidden on the first and the last page.

## Tasks Completed

| Task ID | Name |
|---------|------|
| F1-T1 | Onboarding state + UserPreferences flag |
| F1-T2 | Onboarding screens 1-3 UI |
| F1-T3 | Onboarding screen 4 mic permission with pulsing rings |
| F1-T4 | Onboarding screen 5 motivation + routing |
| F1-T5 | Route registration + app entry gate |
