# Sleep Score Calculation

> Source of truth: `Packages/Models/Sources/Data/SleepSession.swift` — `sleepScore`
> Last updated: 2026-06-19

SleepGuard produces a single `0–100` sleep score per session. Higher is better. The score is computed after a session ends and is cached in `SleepSession.cachedSleepScore` / `cachedSnoringDuration` to avoid SwiftData relationship faulting.

---

## 1. High-level formula

```swift
score = max(0, 100
    - snoringPenalty
    - eventsPenalty
    - intensityPenalty
    - sleepTalkingPenalty
    - stagePenalty)
```

Each penalty is capped independently, so the theoretical maximum total deduction is `150`, but the score floors at `0`.

---

## 2. Inputs used

| Input | How it is derived |
|-------|-------------------|
| `totalDuration` | `endDate - startDate` |
| `snoringDuration` | Sum of snoring event spans + countable melody/recording gaps where snoring resumed |
| `eventCount` | `displayableSnoringEpisodes.count` (episodes merged from adjacent events ≤ 5 min apart, min display duration 3 s) |
| `intensityDurations` | Detected burst durations per event, bucketed by `.quiet`/`.light`/`.loud`/`.epic` |
| `sleepTalkingDuration` / `sleepTalkingEvents` | Events classified as sleep talking |
| `stageStats` | Apple Health / Watch sleep-stage percentages (`awake`, `rem`, `light`, `deep`) if available |

---

## 3. Penalty details

### 3.1 Snoring penalty

```swift
let snoringPercentage = (snoringDuration / totalDuration) * 100
snoringPenalty = min(Int(snoringPercentage * 0.7), 70)
```

| Snoring % of session | Penalty |
|---------------------|---------|
| 10% | 7 |
| 30% | 21 |
| 50% | 35 |
| 100% | 70 (cap) |

### 3.2 Events-per-hour penalty

```swift
eventsPenalty = min(Int(Double(eventCount) / (totalDuration / 3600) * 2), 20)
```

| Events / hour | Penalty |
|---------------|---------|
| 5 | 10 |
| 10 | 20 (cap) |

### 3.3 Intensity penalty

Intensity ratios use **detected burst duration** as the denominator (not full session time). Gaps/melody pauses have no spectral data, so this avoids over-penalizing.

```swift
lightRatio  = lightDuration  / detectedSnoringDuration
loudRatio   = loudDuration   / detectedSnoringDuration
epicRatio   = epicDuration   / detectedSnoringDuration

intensityPenalty = min(Int(lightRatio * 10 + loudRatio * 20 + epicRatio * 30), 30)
```

| Intensity mix | Penalty |
|---------------|---------|
| 100% light | 10 |
| 100% loud | 20 |
| 100% epic | 30 (cap) |
| 50% light / 50% loud | 15 |

### 3.4 Sleep talking penalty

Only applied when `sleepTalkingEvents > 0`.

```swift
sleepTalkingPenalty = min(Int(sleepTalkingPercentage * 0.35
                            + sleepTalkingEventsPerHour * 0.8), 15)
```

### 3.5 Sleep stage penalty

Only applied when Watch/HealthKit stage data is available. Thresholds are evidence-based: deep ≥ 15%, REM ≥ 18%, awake ≤ 8%.

```swift
deepDeficit  = max(0, (15 - deepPct) * 0.6)
remDeficit   = max(0, (18 - remPct) * 0.4)
awakeExcess  = max(0, (awakePct - 8) * 1.0)

stagePenalty = min(Int(deepDeficit + remDeficit + awakeExcess), 15)
```

---

## 4. Edge cases

| Scenario | Behavior |
|----------|----------|
| `totalDuration <= 0` | Returns `100` |
| No snoring events | `snoringPenalty`, `eventsPenalty`, `intensityPenalty` are `0` |
| No sleep talking | `sleepTalkingPenalty` is `0` |
| No Watch stage data | `stagePenalty` is `0` |
| `hasCachedScore == true` | Returns `cachedSleepScore` without recomputation |
| Gap-only inferred snoring | Uses `countableGapDuration / totalDuration` for the snoring penalty |

---

## 5. Example

A 8-hour session:
- Snoring duration: 1 h 36 m → 20% of session
- 4 displayable episodes
- Intensity mix: 50% light / 50% loud (detected)
- 6 sleep talking events, 10 min total, 0.75 events/hr
- Watch stages: deep 12%, REM 15%, awake 6%

```
snoringPenalty  = min(20 * 0.7, 70)              = 14
eventsPenalty   = min(4 / 8 * 2, 20)             = 1
intensityPenalty= min(0.5*10 + 0.5*20, 30)       = 15
sleepTalkPenalty= min((10/480)*100*0.35 + 0.75*0.8, 15) ≈ 1
stagePenalty    = min((15-12)*0.6 + (18-15)*0.4 + 0, 15) = 3

score = 100 - 14 - 1 - 15 - 1 - 3 = 66
```

---

## 6. Related concepts

- Snoring events use **epoch time** (first→last snore, including breathing pauses < 10 s), not net burst time.
- Recording/melody gaps count toward snoring only when `RecordingGap.snoringResumed == true`.
- `SleepSession.snoringDuration` is the canonical snoring duration used by the score.
- For the live detection pipeline that produces these events, see `docs/snore-detection-algorithm.md`.
