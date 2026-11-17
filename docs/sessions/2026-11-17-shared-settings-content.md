
### Completed
- F26-T1: Settings, the profile editor, the start delay row and the countdown host the shared content; three rules move to SleepCore.

### Technical Details
- `SettingsView` is now the container over `SettingsContent`, in three files (`SettingsView`, `+Values`, `+Actions`). Feature flags pass sections or rows as optional values.
- `ProfileEditorView` hosts `ProfileEditorContent` over `$profile.sleepProfile` (`UserProfile+SleepProfile.swift`, mapped by raw value; no schema change). `age` and `completionPercentage` use SleepCore's rules.
- `StorageLimitEnforcer` measures and deletes as before; SleepCore's `StoragePlan` picks the nights.
- `RecordingDelayManager` and `UserPreferences` use `RecordingDelay`. The raw log types come from SleepCore.
- Worked around a Swift 6.3 compiler crash: methods passed as closures in `SettingsView+Values` are wrapped in closures.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Settings/Sources/Views/SettingsView{,+Values,+Actions}.swift` | Container over the shared content |
| `Packages/Personalization/Sources/Views/ProfileEditorView.swift` | Hosts the shared editor |
| `Packages/SleepSession/Sources/Views/{PrestartOptions,RecordingCountdownView}.swift` | Shared delay row and countdown |
| `Packages/Env/Sources/Services/{StorageLimitEnforcer,RecordingDelayManager,UserPreferences}.swift`, `Session/SessionRecordingController.swift` | SleepCore rules and types |
| `Packages/Models/Sources/Data/{UserProfile,UserProfile+SleepProfile}.swift`, `Tests/ModelsTests/UserProfileSleepProfileTests.swift` | Profile mapping and its test |
| 18 deleted files (approved) | Moved to the shared repo |
| `docs/trackers/f26-shared-settings-content.md`, `docs/FeatureTracker.md` | F26 |

### Build Status
- App builds; every package suite passes on the local shared checkout. To be re-run on 0.22.0 after the tag.

### Open Questions
- `RecordingDelayManager`'s notification text is English-only; the shared key exists, but using `Strings` from `Env` is a layering call.
- Not checked on screen yet.
