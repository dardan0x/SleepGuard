### Completed
- F21-T3: a `tests` GitHub Actions workflow runs `scripts/run-tests.sh` (all 7 packages, 45 tests) on pull requests and on manual dispatch.

### Technical Details
- `.github/workflows/tests.yml`, job `packages`:
  - `runs-on: macos-26`, `timeout-minutes: 60`
  - selects the newest `/Applications/Xcode_26*.app` with `xcode-select`
  - runs the script with `DESTINATION=platform=iOS Simulator,name=iPhone 17 Pro,OS=latest`
  - uploads `.build/test-derived-data/logs` with `actions/upload-artifact@v4` on failure
- Checked locally: `DESTINATION='…name=iPhone 17 Pro,OS=latest' sh scripts/run-tests.sh Models` passes, and the YAML parses.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `.github/workflows/tests.yml` | +28 (new) | CI test job |
| `docs/trackers/f21-test-coverage.md`, `docs/FeatureTracker.md` | — | T3 Done |

### Architecture Decisions
- **PR + manual trigger, not every push**: a cold simulator build takes 10+ minutes. Task PRs target the feature branch, so every task still gets tested before merge.
- **`macos-26`, not `macos-latest`**: the packages need Swift 6.2. `macos-latest` may still point at an image without Xcode 26.
- **No derived-data cache yet**: keeps it simple. Add one if CI time becomes a problem.

### Build Status
- No Swift changes. YAML is valid, and the local run with the CI destination passes. The first GitHub run happens when the T3 PR opens.

### Changes done
```
- Add tests.yml: run-tests.sh on macos-26 / Xcode 26, PR + workflow_dispatch, logs on failure
- Update F21 tracker + FeatureTracker; add session fragment
```

### Next Session
- F21-T4: shared fixtures (in-memory SwiftData container, session/event builders) in the Models, Env, Recordings and Statistics tests.

### Open Questions
- Is the `macos-26` runner label available on this repo's GitHub plan? If the job can't find a runner, switch to `macos-latest` and check its Xcode version.
