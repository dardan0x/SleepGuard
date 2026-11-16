
### Completed
- F25-T4b: the player sheet hosts the shared player content; the waveform's math comes from SleepCore.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Recordings/Sources/Views/ClipPlayerContent.swift` | Hosts `PlayerContent` |
| `Packages/Recordings/Sources/Views/LegacyPlayerContent.swift` | Hosts `PlayerCard` (legacy skip and scrub kept) |
| `Packages/Recordings/Sources/Helpers/WaveformGenerator.swift` | `generateSamples` feeds `WaveformAccumulator` |
| `Packages/Recordings/Sources/Views/PlayerLoadingSkeleton.swift` | Comment names the shared card |
| `Packages/DesignSystem/Sources/Components/SleepGuardKitAdapters.swift` | `PlayerClip(event:)` |
| Package manifests, `Package.resolved` | Shared `0.20.0` |
| Deleted (approved): `EventPlayerView`, `EventWaveformView`, `PlayerEventListSection` | Drawing is shared |

### Build Status
- Against the local shared checkout, then on shared `0.20.0`: all 8 suites pass, the app builds, layering, view size, format pass.
- Not checked on screen (morning briefing sheet at launch).
