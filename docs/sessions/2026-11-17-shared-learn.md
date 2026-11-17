
### Completed
- F26-T5: Learn hosts the shared content, and the tab order bug is fixed.

### Technical Details
- `LearnTab` hosts `LearnContent(url:)` with the `feature_learn` URL. It keeps its `NavigationStack` and tab-reset behaviour.
- The page's web view is shared now (`LearnWebView`). It loads when the URL changes; SleepGuard's reloaded on every view update. External links (`data-open-external`) still open in Safari, through SwiftUI's `openURL`.
- Bug fix (agreed with the owner): `AppConfig.visibleTabsInOrder` places Learn only from `learnTabConfig`.
  - Before: the tab list's defaults (first launch, empty remote `tabs`) included Learn, so it showed with `feature_learn` off.
  - Before: with `feature_learn` on, Learn was inserted a second time, giving a duplicate tab id.
  - Now: the empty fallback is every other tab.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Learn/Sources/Views/LearnTab.swift` | Hosts the shared content |
| `Packages/Learn/Sources/Views/LearnView.swift` | Deleted (approved): now shared |
| `Packages/Env/Sources/Services/AppConfig.swift`, `Tests/LearnTabOrderTests.swift` | Learn placed only by its config; tests |
| `docs/features/f16-learn-tab.md` | Facts brought up to date |
| `docs/trackers/f26-shared-settings-content.md`, `docs/FeatureTracker.md` | F26-T5 |

### Build Status
- App builds; every package suite passes on the local shared checkout (Env 63, with the 4 tab-order tests); layering and view-size checks pass. Re-run on the 0.26.0 release: every package suite passes and the app builds.

### Open Questions
- Not checked on screen with a live `feature_learn` URL.
