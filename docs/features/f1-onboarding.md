# Feature: F1 — Onboarding

## Status: Done
## Completed: 2026-05-06

## Summary
First-launch onboarding flow that introduces the app, explains features, requests microphone permission with a visual pulsing animation, and gathers user motivation before routing to the main app.

## Files

| File | Purpose |
|------|---------|
| `Packages/Env/Sources/Env/UserPreferences.swift` | `@AppStorage` flags (`hasCompletedOnboarding`, `detectionSensitivity`, `recordAudioClips`, `appearance`) |
| `Packages/Env/Sources/Env/Router.swift` | `SheetDestination.onboarding` case added |
| `Packages/Onboarding/Sources/Onboarding/OnboardingView.swift` | Main container: `TabView` paging, progress dots, skip/back controls |
| `Packages/Onboarding/Sources/Onboarding/OnboardingPage1View.swift` | Hook screen: problem statement + hero animation |
| `Packages/Onboarding/Sources/Onboarding/OnboardingPage2View.swift` | Features screen: what the app does |
| `Packages/Onboarding/Sources/Onboarding/OnboardingPage3View.swift` | Privacy screen: data stays on device |
| `Packages/Onboarding/Sources/Onboarding/OnboardingPage4View.swift` | Mic permission: pulsing concentric rings + `AVAudioSession.requestRecordPermission()` |
| `Packages/Onboarding/Sources/Onboarding/OnboardingPage5View.swift` | Motivation screen: CTA to start recording or browse stats |
| `SleepGuard/SleepGuard/SleepGuardApp.swift` | Onboarding gate: shows `OnboardingView` if `!hasCompletedOnboarding`, else `MainTabView` |
| `SleepGuard/SleepGuard/AppRegistry.swift` | `SheetDestination.onboarding` mapped, `withEnvironments()` for sheets |

## Routes

| Type | Destination | Trigger |
|------|------------|---------|
| Sheet | `.onboarding` | App launch when `!hasCompletedOnboarding` |

## State

| Property | Location | Scope |
|----------|----------|-------|
| `hasCompletedOnboarding` | `UserPreferences.shared` | App-wide @AppStorage |
| `currentPage` | `OnboardingView` @State | View-local |

## Edge Cases
- **Permission already granted**: Page 4 auto-advances after 0.5s if `recordPermission == .granted`
- **Permission denied**: Page 4 shows "Open Settings" button linking to app settings
- **Skip anywhere**: Sets `hasCompletedOnboarding = true` immediately, routes to `MainTabView`
- **Back navigation**: Hidden on page 0, shown on pages 1-4

## Tasks Completed

| Task ID | Name |
|---------|------|
| F1-T1 | Onboarding state + UserPreferences flag |
| F1-T2 | Onboarding screens 1-3 UI |
| F1-T3 | Onboarding screen 4 mic permission with pulsing rings |
| F1-T4 | Onboarding screen 5 motivation + routing |
| F1-T5 | Route registration + app entry gate |
