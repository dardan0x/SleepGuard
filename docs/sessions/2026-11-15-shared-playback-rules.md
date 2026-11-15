
### Completed
- F5-T2 (tracked in SleepGuardUIKitWay): `ClipPlaybackController` uses `SleepCore`'s `ClipPlaylist`, `PlaybackGain` and `PlaybackEnhancement`. Its audio engine code is unchanged.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Recordings/Sources/Helpers/ClipPlaybackController.swift` | Clip index, durations, seek and after-clip from `ClipPlaylist`; boost from `PlaybackGain`; filter frequencies from `PlaybackEnhancement` |
| `AGENTS.md`, `CLAUDE.md`, `docs/adr/0004-shared-repo.md` | Playback rules are shared |

### Build Status
- All package suites pass against the local shared checkout; app builds through the workspace; format and layering pass.
- The controller has no tests. Needs a listen: play, pause, seek across clips, next/previous, auto-advance to the end, enhanced audio on/off.
- Bumped to shared `0.10.0` (from `0.8.0`): all 8 suites pass and the project (release) builds.
