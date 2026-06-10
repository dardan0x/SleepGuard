# Session Log

The session log is **branch-proof by construction**: each session is its own
file. Branches only ever *add* files here, so session logs can never produce a
merge conflict, and session numbers can never go stale.

## How it works

- **Fragments** (`YYYY-MM-DD-slug.md`) are the source of truth. They are
  committed on every branch. Each one is a single session.
- **`_archive-through-session-77.md`** is the frozen history of Sessions 1–77
  (the old monolithic `SESSION_SUMMARY.md`). Do not edit it.
- **`docs/SESSION_SUMMARY.md`** is a *generated* file (git-ignored). It is the
  archive + all fragments concatenated, with session numbers injected. It is the
  build output — never hand-edit it.

Mental model: **fragments are source, `SESSION_SUMMARY.md` is the build.**

## Session numbers are derived, never authored

Fragments carry **no session number**. When you compile, fragments are sorted by
date and numbered continuing from the archive (78, 79, …). This is why two
branches can't collide on a number — nobody writes one. Whichever merges first
simply gets the lower number.

## Writing a session (end of a coding session)

**One sitting = one fragment**, even if it touched more than one feature (set
`feature:` to the primary one, or `multiple`). The agent writes the fragment and
**does not auto-run the compiler** — run `compile-sessions.py` yourself when you
want to read the combined log.

Create one new file `docs/sessions/YYYY-MM-DD-short-slug.md`:

```markdown
---
date: 2026-06-10
feature: F15            # feature ID, "none" for a standalone fix, or "multiple"
branch: feature/snoring-episodes-confidence-filter
title: Short description of the session
---

### Completed
- [Task ID]: [What was built, in technical detail]

### Technical Details
- [Specific implementation detail / algorithm / formula]

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `path/to/file.swift` | +X/-Y | [Detailed description] |

### Architecture Decisions
- **[Decision name]**: [Why this approach over alternatives]

### Build Status
- **BUILD SUCCEEDED / FAILED** — [if failed, what errors and how resolved]

### Suggested Branch
`feature/[f#]/[t#]-short-description`

### Suggested Commit
`[Task ID] — [Short description]`

### Changes done
- [Change 1]
- [Change 2]
```

Then commit it. No number to pick, no shared file to touch.

## Reading the full log

Run the compiler whenever you want the combined, numbered document:

```bash
python3 scripts/compile-sessions.py
```

It regenerates `docs/SESSION_SUMMARY.md`. You only run this to *read*; writing a
session never requires it.
