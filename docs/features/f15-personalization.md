# Feature: F15 — Personalization & Sleep Briefing

> **Historical record (F15).** Later moves: route enums now live in `Packages/Routing/Sources/Router.swift` (F22-T4, ADR 0001).

## Status: Done
## Completed: 2026-06-06

## Summary

Make SleepGuard feel personal: daily "Sleep Briefing" greets the user by name, recaps last night, notices trends, and gently asks what changed. Profile capture is dismissible and optional, reachable anytime from Settings. All data stays on-device only.

## Files

| File | Package | Purpose |
|------|---------|---------|
| `Packages/Personalization/Package.swift` | Personalization | Package manifest (deps: Models, Env, DesignSystem) |
| `Packages/Personalization/Sources/Engine/Briefing.swift` | Personalization | Value types: `Briefing`, `BriefingStat`, `SurveyPrompt`, `ScoreTrend` |
| `Packages/Personalization/Sources/Engine/BriefingEngine.swift` | Personalization | Pure rules engine: greeting by time, score context, trend insight, survey gate |
| `Packages/Personalization/Sources/Engine/QuoteBank.swift` | Personalization | Motivational quote selector by `ScoreTrend` |
| `Packages/Personalization/Sources/Views/SleepBriefingView.swift` | Personalization | Full-screen daily briefing container with scrollable cards |
| `Packages/Personalization/Sources/Views/BriefingGreetingHeader.swift` | Personalization | Time-appropriate greeting with optional name |
| `Packages/Personalization/Sources/Views/BriefingRecapCard.swift` | Personalization | Last-night recap with stat chips |
| `Packages/Personalization/Sources/Views/BriefingInsightCard.swift` | Personalization | Trend insight pill (improving/declining/steady) |
| `Packages/Personalization/Sources/Views/BriefingSurveyCard.swift` | Personalization | Micro-survey with context-aware chips |
| `Packages/Personalization/Sources/Views/ProfileEditorView.swift` | Personalization | 4-step profile editor container (TabView page style) |
| `Packages/Personalization/Sources/Views/ProfileStepIdentityView.swift` | Personalization | Step 1: Name, birth year, biological sex, height, weight |
| `Packages/Personalization/Sources/Views/ProfileStepGoalsView.swift` | Personalization | Step 2: Target bedtime, sleep hours, primary goal |
| `Packages/Personalization/Sources/Views/ProfileStepHabitsView.swift` | Personalization | Step 3: Caffeine, alcohol, exercise, stress, screen habits |
| `Packages/Personalization/Sources/Views/ProfileStepPersonalView.swift` | Personalization | Step 4: Hobbies, occupation |
| `Packages/Personalization/Sources/Views/ProfileChipSelector.swift` | Personalization | Reusable multi-select chip grid |
| `Packages/Personalization/Sources/Views/ProfilePromptCard.swift` | Personalization | Dismissible profile nudge card for Statistics tab |
| `Packages/Personalization/Tests/BriefingEngineTests.swift` | Personalization | 23 unit tests covering all trends, greetings, survey gate |
| `Packages/Models/Sources/Data/UserProfile.swift` | Models | SwiftData `@Model` for user identity, goals, lifestyle baseline |
| `Packages/Models/Sources/Data/LifestyleLog.swift` | Models | SwiftData `@Model` for per-night deviation log |
| `Packages/Env/Sources/Services/UserPreferences.swift` | Env | Added `lastBriefingShownDate`, `hasCompletedProfile`, `profilePromptDismissCount`, `briefingEnabled` |
| `Packages/Env/Sources/Services/Router.swift` | Env | Added `SheetDestination.profileEditor` |
| `Packages/Settings/Sources/Views/SettingsProfileSection.swift` | Settings | Settings section with Profile row + Daily Briefing toggle |
| `Packages/Settings/Package.swift` | Settings | Added `Personalization` dependency |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | DesignSystem | 39+ briefing/profile localized keys |
| `Packages/DesignSystem/Sources/Strings.swift` | DesignSystem | Auto-generated accessors (382+ total) |
| `SleepGuard/SleepGuardApp.swift` | App | SwiftData schema includes `UserProfile.self` and `LifestyleLog.self` |
| `SleepGuard/MainTabView.swift` | App | Daily briefing `.fullScreenCover` trigger on both tab view paths |
| `SleepGuard/StatisticsTab.swift` | App | `ProfilePromptCard` integration + router-based profile editor sheet |
| `SleepGuard/SettingsTab.swift` | App | Router-based profile editor sheet handling |

## Routes

| Type | Destination | View | Trigger |
|------|-------------|------|---------|
| Sheet | `.profileEditor` | `ProfileEditorView` | ProfilePromptCard tap, Settings Profile row, StatisticsTab prompt |

## State

| Property | Type | Scope | Description |
|----------|------|-------|-------------|
| `lastBriefingShownDate` | `Date?` | `UserPreferences` | Date of last briefing presentation; compared to calendar day start |
| `hasCompletedProfile` | `Bool` | `UserPreferences` | Set when user saves profile editor; gates prompt card |
| `profilePromptDismissCount` | `Int` | `UserPreferences` | Incremented on prompt card dismiss; max 3 shows |
| `briefingEnabled` | `Bool` | `UserPreferences` | Toggle in Settings; defaults `true` |
| `showBriefing` | `Bool` | `MainTabView` | Drives `.fullScreenCover` for `SleepBriefingView` |
| `currentBriefing` | `Briefing?` | `MainTabView` | Generated by `BriefingEngine` on `.task` |

## Edge Cases

- **No sessions yet** → `BriefingEngine` returns `.noData` context with welcome headline and empty stats; no survey
- **Single session only** → `ScoreTrend.firstNight`; no insight, no survey (needs ≥2 sessions for comparison)
- **Returning after gap (>3 days)** → `ScoreTrend.returningAfterGap(days:)`; special quote from `QuoteBank`
- **Score swing < 15 points** → No survey offered; only trend insight shown
- **Existing LifestyleLog for night** → Survey suppressed even if score swing ≥ 15
- **Profile not completed** → `ProfilePromptCard` shows after ≥3 sessions, dismissible up to 3 times
- **Briefing disabled** → `briefingEnabled = false` blocks generation entirely; toggle in Settings
- **Same-day re-open** → `lastBriefingShownDate` compared with `Calendar.isDateInToday`; briefing shown once per calendar day
- **Chip tap on survey** → Creates `LifestyleLog` linked to latest session via `sessionID`; survey dismissed with briefing
- **On-device only** → `UserProfile` and `LifestyleLog` are SwiftData `@Model`; no network calls; privacy banner reused from onboarding

## Tasks Completed

| Task ID | Name | Package |
|---------|------|---------|
| F15-T1 | Personalization package scaffold | Personalization |
| F15-T2 | UserProfile + LifestyleLog models | Models |
| F15-T3 | UserPreferences flags ×4 | Env |
| F15-T4 | BriefingEngine + value types + QuoteBank | Personalization |
| F15-T5 | Briefing localization keys + Strings regen | DesignSystem |
| F15-T6 | SleepBriefingView + subviews | Personalization |
| F15-T7 | ProfileEditorView (4 steps) + reusable components | Personalization |
| F15-T8 | ProfilePromptCard + Statistics trigger | Personalization |
| F15-T9 | Settings Profile section + briefing toggle | Settings |
| F15-T10 | Router wiring (SheetDestination.profileEditor) | Env / App |
| F15-T11 | SwiftData schema + app-level briefing trigger | App |
| F15-T12 | Daily briefing trigger in MainTabView | App |
| F15-T13 | Localization verification (grep pass) | DesignSystem |
| F15-T14 | BriefingEngine unit tests (23 tests) | Personalization |
| F15-T15 | Build & verify — zero errors, zero warnings | — |
| F15-T16 | Feature doc + tracker finalization | — |

## Notes

- **Test execution**: `PersonalizationTests` target is defined in `Package.swift` and compiles via Xcode's iOS simulator build. Running the tests via CLI (`swift test` / `xcodebuild test`) is blocked because the dependency chain (`Personalization → Env → AudioEngine`) includes iOS-only APIs (`AVAudioSession`, `UIKit`) that fail on macOS. To execute: open Xcode → configure the Personalization scheme's Test Action → run tests on iOS Simulator.
- **Chip-to-log mapping**: `MainTabView.saveLifestyleLog()` maps tapped chip text to `LifestyleLog` bool fields by comparing against localized `Strings.briefingSurveyChip*` keys. This is slightly fragile; a future refactor could use typed identifiers on survey chips.
