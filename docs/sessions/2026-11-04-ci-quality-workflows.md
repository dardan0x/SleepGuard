---
date: 2026-11-04
feature: none
branch: main
title: CI quality workflows — SwiftFormat lint, hardcoded-string gate, Strings.sync
---

### Completed
- CI-1: Added `.github/workflows/quality.yml` with three PR/push gates:
  `swiftformat --lint .`, `scripts/check-hardcoded-strings.py`, and a
  `Strings.swift` regeneration-sync check.
- CI-2: Fixed `.swiftformat`, which had four options that no longer exist in
  SwiftFormat 0.55.5 (the installed version) — every `swiftformat` run errored
  out. Repo then formatted in full (160 files).
- CI-3: Whole-repo SwiftFormat pass: 160/180 files reformatted, lint now clean.

### Technical Details
- `.swiftformat` fixes for 0.55.5: `--yodaconditions preserve` →
  `--disable yodaConditions`; `--fractiongrouping ignore` → `disabled`;
  `--exponentgrouping ignore` → `disabled`; `--redundanttype infer` →
  `inferred`; added `--swiftversion 6.0` (matches `SWIFT_VERSION = 6.0`,
  silences the "no Swift version" lint warning).
- Workflow design: `quality.yml` runs on `[push, pull_request, workflow_dispatch]`,
  same trigger style as `layering.yml`. swiftformat job installs the pinned
  0.55.5 linux binary from the GitHub release (ubuntu runner, seconds);
  version must be bumped in the workflow when local swiftformat is upgraded.
- `check-hardcoded-strings.py` is diff-based (added lines only, vs merge-base
  with the base ref) so pre-existing literals never block a PR. It tracks
  `#if DEBUG` regions (DebugConfigView strings are intentionally unlocalized),
  skips decorative literals (≤2 chars, no letters, e.g. "Z", "·", emoji) and
  interpolations (`Text("\(count)")`), and flags `String(localized: "key")`
  bypasses anywhere except generated `Strings.swift`.
- CI base resolution: PR events diff against `origin/<base_ref>`; push events
  diff against `github.event.before` (falls back to `origin/main`, then
  `HEAD~1`).
- `strings-sync` job runs `generate-strings.py` and fails if
  `git diff` on `Packages/DesignSystem/Sources/Strings.swift` is non-empty.
- Verified end-to-end on this change set: lint exit 0, hardcoded-string check
  exit 0 (no false positives from the 160-file reformat diff), strings-sync
  exit 0 (swiftformat left the generated file untouched).

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `.github/workflows/quality.yml` | +47 | New workflow: swiftformat / hardcoded-strings / strings-sync jobs |
| `scripts/check-hardcoded-strings.py` | +158 | New diff-based localization gate script |
| `.swiftformat` | ~9 | Four dead options fixed for 0.55.5; `--swiftversion 6.0` added |
| 160 `.swift` files across Packages/, SleepGuard/, WatchApp/ | +4489/−4568 | Whole-repo swiftformat pass (whitespace/wrapping only; zero semantic change) |

### Architecture Decisions
- **Whole-repo format instead of changed-files lint**: user decision. Lint
  covers everything going forward; alternative (diff-scoped lint) was offered
  and declined. Tradeoff: this commit conflicts with any branch that predates
  it until rebased.
- **Ubuntu runners with pinned release binary**: ~seconds per job vs ~10-20 min
  macOS runners; same lint ruleset. Tradeoff: version pinned in the workflow
  must track local swiftformat upgrades (noted in the workflow comment).
- **Diff-based string check**: matches AGENTS.md "grep the changed files"
  verification rule and avoids a big-bang cleanup of legacy literals.

### Build Status
- **BUILD SUCCEEDED** (XcodeBuildMCP build_sim, 52.9s, iPhone 16e iOS 26.2
  simulator) — proves the mass reformat broke nothing. One pre-existing
  warning: `latestSession` defined-but-unused in `MainTabView.swift:200`
  (untouched by this change; flagged, not fixed, per surgical-changes rule).

### Suggested Branch
`chore/ci-quality-workflows` (standalone infra — no feature number; branched
from `main`. User directed this land on `main`.)

### Suggested Commit
`[CI] — Add quality.yml gates (swiftformat lint, hardcoded strings, strings sync) + repo-wide format`

### Changes done
```
- Add .github/workflows/quality.yml (3 jobs, pinned SwiftFormat 0.55.5)
- Add scripts/check-hardcoded-strings.py (diff-based, #if DEBUG-aware)
- Fix 4 dead .swiftformat options for 0.55.5 + pin --swiftversion 6.0
- swiftformat whole repo (160 files)
```

### Next Session
- Optional follow-ups from the original suggestion list: build+test CI job
  (macos runner), Danger for PR conventions, per-package `swift test` matrix.
- Consider a one-time pass localizing legacy hardcoded strings so the
  hardcoded-strings check could become whole-repo instead of diff-based.

### Open Questions
- Local swiftformat is 0.55.5 today; the workflow pins it. Bump the pin in
  `quality.yml` whenever local swiftformat is upgraded — should this be
  documented in AGENTS.md or left as the workflow comment?
- Notion/FeatureTracker were not updated for this task (no feature number).
  Add an infra row to the tracker if you want CI work tracked there.
- Note: mid-session, work was re-anchored from `feature/f18/t12-shared-viewstate`
  to `main` per user instruction; all changes are currently uncommitted on
  `main`.
