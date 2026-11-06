---
date: 2026-11-05
feature: none
branch: fix/ci-swiftformat-container-curl
title: CI — Fix SwiftFormat build step (curl missing in swift container)
---

### Completed
- CI hotfix: quality workflow `swiftformat` job failed on push and pull_request with `curl: not found` inside the `swift:6.0.3` container. The 5494d44 fix (build from source) was correct but used `curl | tar` to fetch the source, and the official Swift Docker image ships no curl. Replaced with `git clone --depth 1 --branch ${SWIFTFORMAT_VERSION}`, which stays inside the existing cache guard and targets the same `/tmp/SwiftFormat-${SWIFTFORMAT_VERSION}` path `swift build` expects.

### Technical Details
- Root cause chain: prebuilt SwiftFormat 0.55.x Linux binary segfaults on GH runners → 5494d44 switched to source build in `swift:6.0.3` container → that image has no curl (`curl: not found`, then `tar` fails on empty stdin) → clone via git instead.
- git is guaranteed present in the Swift container: SwiftPM shells out to it for dependency resolution (and `actions/checkout@v4` already succeeded in the same container).
- Clone command verified locally against the real repo: `git clone --depth 1 --branch 0.55.5 https://github.com/nicklockwood/SwiftFormat.git` — tag exists, `Package.swift` present at clone root.
- Cache behavior unchanged: clone and build still skip entirely when `swiftformat-build-0.55.5` cache restores `/tmp/swiftformat-build/release/swiftformat`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `.github/workflows/quality.yml` | +2/-1 | curl+tar download replaced with `git clone --depth 1 --branch`; comment noting the container has no curl |

### Architecture Decisions
- **git clone over `apt-get install curl`**: no per-run apt update cost, no dependency on image package state, and git is a stronger guarantee in this image than any apt package.

### Build Status
- Not buildable locally (workflow change only; no Docker on this machine for an end-to-end container test). YAML indentation preserved (single line swap inside the existing block scalar); clone command tested against the live repo.

### Suggested Branch
`fix/ci-swiftformat-container-curl`

### Suggested Commit
`[CI] — Fetch SwiftFormat source via git clone (no curl in swift container)`

### Changes done
```
- .github/workflows/quality.yml: curl|tar download → git clone --depth 1 --branch 0.55.5
```

### Next Session
- Watch the next push/PR run: first run on a branch will do a full release build of SwiftFormat (~several minutes); once the `swiftformat-build-0.55.5` cache populates, subsequent runs reuse it.
- Confirm the `Lint` step output matches local `swiftformat --lint .` results.

### Open Questions
- None.
