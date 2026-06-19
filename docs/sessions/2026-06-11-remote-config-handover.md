---
date: 2026-06-11
feature: none
branch: feature/remote-config/firebase-flags-tabs-update-gating
title: Remote Config — Compact Handover
---

# Remote Config — Compact Handover

Firebase Remote Config drives **feature flags**, **tab visibility/order**, and **soft/hard update gating**. Build green. Full detail: `2026-06-11-remote-config.md` + `docs/remote-config-schema.md`.

## Model (resolution order: debug override → remote/cache → baked-in default)
- `AppConfig` (`Packages/Env/.../AppConfig.swift`) — Firebase-free `@MainActor @Observable .shared`. API: `isEnabled(_:FeatureFlag)`, `visibleTabsInOrder`, `updateGate`, `apply(...)`. Caches last fetch in UserDefaults.
- `RemoteConfigLoader` (`SleepGuard/RemoteConfig/`) — **only** Firebase importer; decodes RC → `AppConfig.apply`. Refreshes on launch + every `scenePhase==.active`. `minimumFetchInterval`: 0 DEBUG / 3600 release.
- Models (`Packages/Models/.../AppConfigModels.swift`): `FeatureFlag` (13 cases, default true), `AppTab` (statistics/media/settings), `TabConfig`, `UpdateGate`.

## RC keys (Firebase project `sleepguard-a7ca0`)
`feature_flags` (JSON obj), `tabs` (JSON array TabConfig), `minimum_version`, `recommended_version` (Strings). Console: console.firebase.google.com/project/sleepguard-a7ca0/config → edit → **Publish**.

## UI
- Tabs data-driven from `visibleTabsInOrder` in `MainTabView` (both iOS26 + legacy). `TabCoordinator.selectedTab` is now `AppTab` (was Int).
- `UpdateGateView` (DesignSystem) overlay in `SleepGuardApp`: app ver < min → hard block; < recommended → soft (once per version via `@AppStorage`).
- **DebugConfigView** (`#if DEBUG`, Settings→bottom→"Debug Config"): toggle flags, edit tabs, **Mock Soft/Hard Update**, Clear, Reset.

## How to test update gate (app ver = 1.0.0)
- In-app: Debug Config → Mock Soft/Hard → dismiss sheet to see overlay. (Override beats Firebase — Clear it before testing console.)
- Firebase: set `minimum_version`=2.0.0 (hard) or `recommended_version`=2.0.0 (soft) → Publish → background+reopen.

## Flag gating wired
✅ `sleepBriefing` (MainTabView), `watchApp` (SettingsView). Others: keys exist + `isEnabled` works, UI gating is follow-up — file map in `docs/remote-config-schema.md`.

## ⚠️ Open / TODO
- **Bundle id mismatch**: plist `com.dardan.SleepGuard` vs Xcode `com.daki.exampleProject.SleepGuard`. RC works anyway; fix for Analytics/Crashlytics.
- App Store URL in `SleepGuardApp.openAppStore()` is placeholder `id000000000`.
- Decide: `snoringDetection` off = kill-switch or UI-only? (currently UI-only intent, not yet wired)
- Commit vs gitignore `GoogleService-Info.plist` (currently committed at `SleepGuard/Configuration/`).
- Not yet committed; suggested branch `feature/remote-config/firebase-flags-tabs-update-gating`.
