#!/usr/bin/env python3
"""View size check: no view file over 200 lines (AGENTS.md "View Componentization").

Scans every Swift file under `Packages/*/Sources/Views/` and
`Packages/*/Sources/Components/`. A file over the limit fails unless it is in
ALLOWLIST, and an allowlisted file fails if it grows past its recorded ceiling.
An entry whose file is back under the limit (or gone) also fails, so the
allowlist can only shrink: delete the entry when you split the file.

Exits 1 with a listing when any check fails.
"""

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LIMIT = 200

# path -> (ceiling, reason). The ceiling is the line count when the entry was
# added; the file may shrink but never grow.
ALLOWLIST = {
    "Packages/Recordings/Sources/Views/SleepReportPDFGenerator.swift": (
        525,
        "UIKit PDF drawing, not a SwiftUI view; move to Helpers/ and split per page section",
    ),
    "Packages/Recordings/Sources/Views/SessionDetailLoadedView.swift": (
        201,
        "one line over; extract the share/export toolbar section",
    ),
}


def line_count(path: pathlib.Path) -> int:
    with path.open(encoding="utf-8") as handle:
        return sum(1 for _ in handle)


def main() -> int:
    files = sorted(
        path
        for folder in ("Views", "Components")
        for path in ROOT.glob(f"Packages/*/Sources/{folder}/**/*.swift")
    )
    failures = []
    seen = set()

    for path in files:
        rel = path.relative_to(ROOT).as_posix()
        lines = line_count(path)
        if rel in ALLOWLIST:
            seen.add(rel)
            ceiling, _ = ALLOWLIST[rel]
            if lines > ceiling:
                failures.append(f"{rel}: {lines} lines, grew past its allowlisted {ceiling}; split it instead")
            elif lines <= LIMIT:
                failures.append(f"{rel}: {lines} lines, now within {LIMIT}; delete its ALLOWLIST entry")
        elif lines > LIMIT:
            failures.append(f"{rel}: {lines} lines (limit {LIMIT}); split it")

    for rel in sorted(set(ALLOWLIST) - seen):
        failures.append(f"{rel}: allowlisted but not found; delete its ALLOWLIST entry")

    if failures:
        print("View size violations (see AGENTS.md 'View Componentization'):")
        for failure in failures:
            print(f"  {failure}")
        return 1
    print(f"View size check passed ({len(files)} view files, {len(ALLOWLIST)} allowlisted).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
