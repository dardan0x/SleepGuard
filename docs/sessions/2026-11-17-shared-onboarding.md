
### Completed
- F26-T4: Onboarding hosts the shared content; the page rules come from SleepCore.

### Technical Details
- `OnboardingView` hosts `OnboardingContent`. It owns:
  - the page (an `OnboardingPage`);
  - the microphone and Health requests, with "granted" shown for 0.8 s before the next page;
  - the rule that grants Health sync and enhanced tracking unless the person already chose;
  - finishing, which sets `presentRecordingAfterOnboarding` (on "Start recording") and `hasCompletedOnboarding`.
- `OnboardingPages(hasHealth:)` decides the pages, Next, Skip (to the last page) and Back. The Health page follows the `healthSync` remote flag (a fix: it used to show regardless).
- Same pages, texts and animations as before; the views moved to `SleepGuardContentKit`.
- `Onboarding` depends on `SleepCore` now.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Onboarding/Sources/Views/OnboardingView.swift` | Hosts the shared content |
| `Packages/Onboarding/Package.swift` | `SleepCore` |
| 6 deleted page views (approved) | Moved to the shared repo |
| `docs/features/f1-onboarding.md` | Facts brought up to date |
| `docs/trackers/f26-shared-settings-content.md`, `docs/FeatureTracker.md` | F26-T4 |

### Build Status
- App builds; every package suite passes on the local shared checkout; layering and view-size checks pass. Re-run on the 0.25.0 release: every package suite passes and the app builds.

### Open Questions
- The onboarding string keys are named for other pages (page 1's body is `onboarding.page4.body`); the values are right, so they stay.
- Not checked on screen yet (the page renders in the shared kit match).
