
### Completed
- F26-T3: The Snore Interrupter's screens host the shared content. Its rules come from SleepCore and its sounds from the shared `SleepMelodies`.

### Technical Details
- `RecordingPrestartView` puts the shared `PrestartOptions` (delay + interrupter row) in the prestart slot; the row shows when the remote flag is on.
- Three thin hosts over the shared content:
  - `SnoreInterrupterSheet` → `SnoreInterrupterSettingsContent`
  - `MelodyPickerSheet` → `MelodyPickerContent`
  - `RecordCustomMelodySheet` → `RecordMelodyContent`
- `BedsideClockView` uses the shared `BedsideMelodyDisclaimer` and `BedsideMelodyOverlay`.
- Env:
  - `UserPreferences.SnoreInterrupterMode` is SleepCore's mode, with the same raw values and keys, so nothing stored changes.
  - `SnoreInterrupterPlaying.currentMelodyName` became `currentMelody`; the view names it.
  - The player and the preview find files through `CustomMelodyStoring.url(for:)`: a recording from the store, a built-in from `SleepMelodies`. This replaces two copies of the bundle lookup.
  - `CustomMelodyStorage` uses `CustomMelodies` for ids and file names, so an id is never reused.
- `RealtimeDetectionTracker` adds and marks gaps with SleepCore's helpers. Detection output is unchanged: the characterization tests, melody cases included, and the replay goldens pass as before.
- `SleepSession` now depends on `SleepCore` directly.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/SleepSession/Sources/Views/{RecordingPrestartView,BedsideClockView,SnoreInterrupterSheet,MelodyPickerSheet,RecordCustomMelodySheet}.swift` | Host the shared content |
| `Packages/SleepSession/Sources/Helpers/{CustomMelodyRecorder,MelodyPreviewPlayer}.swift`, `Package.swift` | SleepCore rules; one file lookup |
| `Packages/Env/Sources/Services/{UserPreferences,SnoreInterrupterPlayer,SnoreInterrupterPlaying,CustomMelodyStorage,CustomMelodyStoring}.swift`, `Session/RealtimeDetectionTracker.swift`, `Package.swift` | SleepCore mode, catalog, rules; `SleepMelodies` |
| `Packages/Env/TestSupport/{FakeStores,FakeSessionServices}.swift`, `Tests/DetectionCharacterizationTests.swift` | `Melody` and `currentMelody` |
| 23 deleted files (approved) | 10 views, `Models/Melody.swift`, `MelodyGapsBannerView`, 11 sounds |
| `docs/trackers/f26-shared-settings-content.md`, `docs/FeatureTracker.md` | F26-T3 |

### Build Status
- App builds; every package suite passes on the local shared checkout; layering and view-size checks pass. Re-run on the 0.24.0 release: every package suite passes and the app builds.

### Open Questions
- Not checked on screen yet. The duration wheel can't be rendered in the shared kit's tests.
- `sounds/` keeps two files no melody uses (`calm-outro`, `new-notification-3`).
