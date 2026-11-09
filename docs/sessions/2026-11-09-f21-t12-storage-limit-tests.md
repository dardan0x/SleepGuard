### Completed
- F21-T12: `StorageLimitEnforcer` tests (6 new). The suite is now 145 tests, all passing.

### Technical Details
- Seam: public `enforceLimits(modelContext:)` → internal `enforceLimits(modelContext:maxDays:maxMB:)`. Each limit is `nil` when its preference toggle is off. Plan building, URL clearing and off-main deletion are unchanged.
- `StorageLimitEnforcerTests` (`@MainActor final class`, so `deinit` can remove the files it created):
  - **day limit 7**: a 10-day-old session with 4 files → 4 files / 4,000 bytes removed, every reference nil, sessions and events kept, cached score 77 kept; a 1-day-old session untouched
  - **size limit 2 MB** with 3 × 1 MB sessions → only the oldest removed (1 MB)
  - **under the limit** → nothing
  - **day + size**: the day plan clears the old session first, so the size plan sees 2 MB and removes nothing (`sizeLimitSessions` 0)
  - **no limits** → nothing
  - **missing file**: the reference is cleared, 0 files, 0 sessions affected

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/StorageLimitEnforcer.swift` | +15/−4 | Internal overload with explicit limits |
| `Packages/Env/Tests/StorageLimitEnforcerTests.swift` | +150 (new) | 6 cleanup tests |
| `docs/trackers/f21-test-coverage.md`, `docs/FeatureTracker.md` | — | T12 Done |

### Architecture Decisions
- **Explicit-limits overload instead of writing to `UserDefaults` in tests**: same reasoning as T11. No shared global state, and tests can run in parallel.
- **Real files in Documents**: the enforcer resolves everything through `AudioFileURLResolver.documentsDirectory`. Unique names + `deinit` cleanup keep the simulator clean (verified: 0 leftovers).

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5). `run-tests.sh`: 145/145 pass. SwiftFormat lint is clean and the layering check passes.

### Changes done
```
- StorageLimitEnforcer: internal enforceLimits(modelContext:maxDays:maxMB:) used by the public entry point
- Add StorageLimitEnforcerTests (6): day plan, size plan, under limit, combined, no limits, stale refs
- Update F21 tracker + FeatureTracker; add session fragment
```

### Next Session
- F21-T13: `SessionCheckpointStore` (write/load/clear, non-recoverable snapshot) and `RecordingDelayManager` (remaining time, completion).

### Open Questions
- None new.
