
### Completed
- F26-T6: The morning briefing, the profile prompt and the PDF report host the shared content and rules.

### Technical Details
- **Briefing**:
  - `Personalization/BriefingController` (moved from the app's `AppBriefingController`) maps the cached nights, the profile and the stored answers to values for SleepCore's `BriefingEngine`.
  - The briefing is due when `BriefingSchedule` says so (same gates as before).
  - A survey answer is stored as a `LifestyleLog` model with the same flags.
  - `BriefingSheet` hosts the shared `BriefingContent`; `MainTabView` presents it.
- **Engine changes, decided with the owner**:
  - The engine returns values; the content maps them to the same strings.
  - The content mode is picked by the night instead of at random, so a night's briefing is stable.
  - Its 30 tests are SleepCore's now, on values, with exact checks where the random mode forced vague ones.
- **Profile prompt**:
  - `ProfilePromptSection` hosts the shared card, with the rule from SleepCore's `ProfilePrompt`.
  - Its chance is drawn once per appearance (it used to re-roll on every redraw).
- **Report**:
  - The night detail draws SleepCore's `NightReport` with the shared `NightReportPDF` and hands the file to `SessionShareCoordinator`, which keeps audio sharing.
  - All labels are localized now, and dates follow the locale.
  - Long nights continue on more pages.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Personalization/Sources/{Helpers/BriefingController,Views/BriefingSheet,Views/ProfilePromptSection}.swift`, `Package.swift` | New hosts; SleepCore; no test target |
| `SleepGuard/{MainTabView,StatisticsTab}.swift` | Present the briefing; host the prompt |
| `Packages/Recordings/Sources/{Views/SessionDetailLoadedView,Helpers/SessionShareCoordinator}.swift` | Shared report |
| 14 deleted files (approved) | Engine, views, tests, PDF generator, `AppBriefingController`, unused `ActivityView` and `HiddenEventsSection` |
| `scripts/check-view-size.py` | Allowlist emptied (its one entry was the PDF generator) |
| `docs/trackers/f26-shared-settings-content.md`, `docs/FeatureTracker.md` | F26-T6 |

### Build Status
- App builds on the local shared checkout; every package suite passes; layering and view-size checks pass. Re-run on the 0.27.0 release: every package suite passes and the app builds.

### Open Questions
- Four positive survey answers have no `LifestyleLog` field, so they're stored with no flags (as before).
- Not checked on screen yet: the briefing sheet and a real PDF.
