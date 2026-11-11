#!/usr/bin/env python3
"""Cut a replay fixture for DetectionReplayTests out of a rawlog_<id>.json (F22-T9).

Usage:
  python3 scripts/make-replay-fixture.py <rawlog.json> <name> <start-min> <end-min>

Writes Packages/AudioEngine/Tests/Fixtures/Replay/<name>.csv with one row per
sample in [start, end): elapsed (rebased to 0 at the excerpt start), db,
spectralScore, snoreConfidence, state. Values are rounded to keep the files
small; the goldens are generated from the rounded fixture, so rounding never
causes a mismatch.

Reads both raw log formats (format 1: bare sample array; format 2: object with
metadata). Only detection levels are kept: no audio leaves the device.

After adding a fixture, record its golden on purpose:
  sh scripts/record-replay-goldens.sh
"""

import csv
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "Packages/AudioEngine/Tests/Fixtures/Replay"
STATES = {"none", "quiet", "light", "loud", "epic"}


def main() -> int:
    if len(sys.argv) != 5:
        print(__doc__)
        return 2
    source, name = pathlib.Path(sys.argv[1]), sys.argv[2]
    start, end = float(sys.argv[3]) * 60, float(sys.argv[4]) * 60

    log = json.loads(source.read_text(encoding="utf-8"))
    samples = log["samples"] if isinstance(log, dict) else log
    excerpt = sorted(
        (s for s in samples if start <= s["elapsed"] < end),
        key=lambda s: s["elapsed"],
    )
    if not excerpt:
        print(f"No samples between {sys.argv[3]} and {sys.argv[4]} minutes.")
        return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / f"{name}.csv"
    with out.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(["elapsed", "db", "spectralScore", "snoreConfidence", "state"])
        for s in excerpt:
            if s["state"] not in STATES:
                raise ValueError(f"unknown state {s['state']!r} at {s['elapsed']}")
            writer.writerow([
                f"{s['elapsed'] - start:.4f}",
                f"{s['db']:.2f}",
                f"{s['spectralScore']:.3f}",
                f"{s['snoreConfidence']:.3f}",
                s["state"],
            ])
    print(f"Wrote {out.relative_to(ROOT)}: {len(excerpt)} samples, {out.stat().st_size // 1024} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
