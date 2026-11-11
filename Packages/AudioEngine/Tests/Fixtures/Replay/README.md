# Detection replay fixtures (F22-T9)

`DetectionReplayTests` feeds each `<name>.csv` through `DetectionStateMachine`
and compares the result with `<name>.golden.txt`.

## Source

All four excerpts come from one 37-minute scripted recording made on an
iPhone on 2026-11-11, with snoring imitated at varying loudness and
spacing, separated by pauses. Only per-sample
detection levels are kept, no audio. The log is raw log format 1 (recorded
before F22-T1), so it has no `peakDB`, `speechConfidence`, or settings
metadata. That is why the replay runs with sleep talking off.

| Fixture | Minutes of the recording | What it covers |
|---|---|---|
| `sustained-snoring` | 0–7.5 | One long event with short pauses (20 bursts); a separate loud spike right after it |
| `sparse-snores` | 7–15 | Isolated snores split by gaps over 10 s; short events kept or dropped by the confidence gate |
| `loud-onset` | 15–21 | Onset from silence; quiet→epic intensity; a short low-confidence event discarded |
| `short-bursts-and-quiet` | 23–32 | One short episode, then minutes of silence and room noise |

The excerpts overlap by 30 s (7–7.5) on purpose: the same spike is seen once
mid-event and once from a cold start.

## What the goldens mean

They pin what the machine decides **today**. They are a regression net for
refactors such as F22-T10, not proof that detection is accurate. The
recording was imitated snoring, and `spectralScore` is 0 throughout because
the classifier path was active.

## Changing them

- Normal test runs never write goldens.
- When a change is meant to alter detection, run
  `sh scripts/record-replay-goldens.sh`, then explain every changed line of
  the golden diff in the PR.
- To add an excerpt from another raw log:
  `python3 scripts/make-replay-fixture.py <rawlog.json> <name> <start-min> <end-min>`,
  add `<name>` to `DetectionReplayTests.fixtures`, then record.
