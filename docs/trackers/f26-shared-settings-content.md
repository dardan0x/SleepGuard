# F26 — Shared Settings content

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P2 |
| **Version** | — |
| **Blocked By** | F25 |
| **Started** | 2026-11-17 |
| **Completed** | 2026-11-17 |
| **Feature Doc** | — |

## Summary

Settings, the profile editor, the prestart's start delay and the countdown host their layouts from the shared `SleepGuardContentKit` (ADR 0006), and three rules move to `SleepCore`: which nights the storage limits empty (`StoragePlan`), the delay's options and countdown text (`RecordingDelay`), and the raw log format (`RawLog`, `SnoreSample`, `RawLogMetadata`). The profile maps to the shared `SleepProfile` value. No schema change, no visible change. Mirrors SleepGuardUIKitWay's F8-T1, which builds its Settings on the same content.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F26-T1 | Settings, profile editor, delay row and countdown host the shared content; storage, delay and raw log rules from SleepCore; `UserProfile` ↔ `SleepProfile` | Refactor | Done | F25 | Settings, Personalization, SleepSession, Env, Models, AudioEngine | 2026-11-17 | 2026-11-17 |

## Notes

- 18 files deleted with the owner's approval (the Settings sections and their helpers, the four profile pages and the chip selector, `PrestartDelaySection`, `SnoreSample.swift` and its tests, now in the shared repo).
- `SettingsView` is split in three files (`+Values`, `+Actions`) for the 200-line limit.
- The shared day rule chooses every night past the limit, as `StorageLimitEnforcer` did, so stale references are still cleared.
- Open: `RecordingDelayManager`'s notification text is English-only. The shared key `session.countdown.notificationBody` exists; using it from `Env` needs a layering decision (non-view code and `Strings`).
