#!/usr/bin/env python3
"""Compile per-session fragment files into a single SESSION_SUMMARY.md.

Source of truth = the frozen archive + the fragment files in docs/sessions/.
This script is a READ-TIME convenience: it concatenates them into a generated
docs/SESSION_SUMMARY.md (git-ignored). Never hand-edit the generated file.

Session numbers are DERIVED here, not authored in fragments:
  - The archive already contains Sessions 1..N (frozen).
  - Fragments carry no number; they are sorted by date (then filename) and
    numbered continuing from the archive's max.

Fragment format (docs/sessions/YYYY-MM-DD-slug.md):

    ---
    date: 2026-06-10
    feature: F15            # or "none" for a standalone fix
    branch: feature/...
    title: Short description
    ---

    ### Completed
    - ...

Run:  python3 scripts/compile-sessions.py
"""

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SESSIONS_DIR = REPO / "docs" / "sessions"
ARCHIVE = SESSIONS_DIR / "_archive-through-session-77.md"
OUTPUT = REPO / "docs" / "SESSION_SUMMARY.md"

SESSION_RE = re.compile(r"Session\s+(\d+)")
FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n?(.*)$", re.DOTALL)


def parse_frontmatter(text):
    """Return (meta_dict, body). Body is everything after the frontmatter."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}, text.strip()
    meta = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            key, _, val = line.partition(":")
            meta[key.strip()] = val.strip()
    return meta, m.group(2).strip()


def max_session_number(archive_text):
    nums = [int(n) for n in SESSION_RE.findall(archive_text)]
    return max(nums) if nums else 0


def fragment_files():
    return sorted(
        p
        for p in SESSIONS_DIR.glob("*.md")
        if p.name != ARCHIVE.name and p.name != "README.md"
    )


def sort_key(path):
    meta, _ = parse_frontmatter(path.read_text(encoding="utf-8"))
    # Prefer frontmatter date; fall back to the YYYY-MM-DD filename prefix.
    date = meta.get("date") or path.name[:10]
    return (date, path.name)


def main():
    if not ARCHIVE.exists():
        sys.exit(f"Archive not found: {ARCHIVE}")

    archive_text = ARCHIVE.read_text(encoding="utf-8").rstrip()
    next_num = max_session_number(archive_text) + 1

    parts = [archive_text]
    for path in sorted(fragment_files(), key=sort_key):
        meta, body = parse_frontmatter(path.read_text(encoding="utf-8"))
        date = meta.get("date") or path.name[:10]
        title = meta.get("title") or path.stem[11:].replace("-", " ").title()
        header = f"## {date} — Session {next_num}: {title}"
        parts.append(f"\n\n---\n\n{header}\n\n{body}")
        next_num += 1

    OUTPUT.write_text("\n".join(parts).rstrip() + "\n", encoding="utf-8")
    frag_count = len(fragment_files())
    latest = next_num - 1
    print(
        f"Wrote {OUTPUT.relative_to(REPO)} "
        f"({frag_count} fragment(s), latest = Session {latest})"
    )


if __name__ == "__main__":
    main()
