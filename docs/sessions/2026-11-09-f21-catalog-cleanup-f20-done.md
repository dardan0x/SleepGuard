# F21 follow-up: catalog cleanup + F20 marked Done

## Completed

- Removed the malformed catalog keys `localizations` and `stringUnit` (a "5 seconds" entry flattened into two top-level keys by `22ea853`, 2026-05-12). Nothing in code used them.
- Regenerated `Strings.swift` (`python3 scripts/generate-strings.py`), which dropped the unused `Strings.localizations` / `Strings.stringUnit` accessors.
- `LocalizableCatalogTests`: removed `knownMalformedKeys` and the `knownMalformedKeysStillExist` reminder test. Tests now total 179 (was 180).
- F20 marked Done at the user's request: T8 and T9 Done, feature 9/9, merged to `main` in PR #105. The Lock Screen accessory render is still unverified; this is noted in the F20 tracker and the feature doc.

## Technical Details

- The catalog was rewritten with the same settings `generate-xcstrings.py` uses (`indent=2`, `ensure_ascii=False`, trailing newline), so the diff is just the 12 removed lines.
- FeatureTracker: V5 is 3 Done, 0 In Progress. Tasks Done 118 → 120, Backlog 18 → 16, progress 88%. "Currently Active" is now empty.

## Files Changed

| File | Change |
|------|--------|
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | Removed `localizations` / `stringUnit` |
| `Packages/DesignSystem/Sources/Strings.swift` | Regenerated (2 accessors removed) |
| `Packages/DesignSystem/Tests/LocalizableCatalogTests.swift` | Dropped the malformed-key list and reminder test |
| `docs/features/f21-test-coverage.md` | 179 tests; DesignSystem 5; follow-up removed |
| `docs/trackers/f21-test-coverage.md` | T16 note: keys removed |
| `docs/trackers/f20-home-screen-widgets.md` | F20, T8, T9 Done |
| `docs/FeatureTracker.md` | Dashboard, F20 row, activity log, currently active |

## Architecture Decisions

- None.

## Build Status

- App build succeeds (`xcodebuild`; XcodeBuildMCP failed to connect this session).
- `run-tests.sh DesignSystem`: 5/5 pass.
- Layering check passes.

## Changes done

- Catalog cleanup and F20 status, on top of `feature/f21-test-coverage`.

## Next Session

- Merge `feature/f21-test-coverage` into `main`.

## Open Questions

- Notion sync for F20/F21 (not done).
- Lock Screen accessories still need a visual check on a device.
