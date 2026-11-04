---
date: 2026-11-04
feature: none
branch: chore/ci-quality-workflows (merged to main)
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
- CI-4: Merged `origin/main` (40 F18 commits: view restructuring, SessionManager
  decomposition) into the branch. 15 conflicts (14 content + 1 modify/delete)
  resolved by taking origin/main and re-applying formatting mechanically after;
  38 newly-merged files formatted in a follow-up commit. Build green after merge.

### Merge Details
- Conflict resolution strategy: F18 restructuring is semantic, ours was
  formatting-only → theirs always wins; formatting is re-runnable, so after
  the merge `swiftformat .` re-normalized everything (lint exit 0).
- `SessionManager.swift` accepted deleted (origin/main split it into a facade
  + 3 types); our formatting-only edit to it discarded.
- User's uncommitted AGENTS.md/CLAUDE.md "AI Skills" sections were stashed
  during the merge and popped back cleanly (no overlap with incoming F18 doc
  edits). Left uncommitted — they are the user's to commit.

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

### Final History (on main)
```
ac31230 [CI] — Format files introduced by origin/main merge (38 files)
81ecd06 Merge origin/main into CI quality branch
432a3f3 [CI] — Repo-wide SwiftFormat pass (160 files)
ea1ba28 [CI] — Add quality gates: swiftformat lint, hardcoded-string check, strings sync
```

### Build Status
- **BUILD SUCCEEDED** before merge (52.9s) and **after merge** (38.1s,
  zero warnings) — F18 restructuring compiled with the format pass applied.

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
- `main` is 4 commits ahead of `origin/main` and ready to push; pushing will
  trigger the new quality workflow for the first time (live fire test).
- The user's uncommitted AGENTS.md/CLAUDE.md "AI Skills" sections are in the
  working tree — commit them separately when ready.
