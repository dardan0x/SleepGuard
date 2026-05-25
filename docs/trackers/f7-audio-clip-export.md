# F7 — Audio Clip Export

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P1 |
| **Version** | V1.1 |
| **Blocked By** | — |
| **Started** | 2026-05-07 |
| **Completed** | 2026-05-07 |
| **Feature Doc** | — |

## Summary

Allow users to export and share their recorded sleep audio. Supports sharing the full session recording or individual snore event clips via the native iOS share sheet.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F7-T1 | Share full session audio | UI | Done | — | Recordings | 2026-05-07 | 2026-05-07 |
| F7-T2 | Export individual event clips | UI | Done | F7-T1 | Recordings | 2026-05-07 | 2026-05-07 |

## Task Details

### F7-T1 — Share full session audio

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-07 |
| Completed | 2026-05-07 |

**Acceptance Criteria:**
- [x] Share button added to SessionDetailView toolbar
- [x] Tapping share presents UIActivityViewController with the session's .caf file
- [x] File is shareable to Messages, Mail, Files, and other standard destinations
- [x] Builds with zero errors

**Prompt Used:**
Wired existing share button in SessionDetailView toolbar to present UIActivityViewController via ActivityView UIViewControllerRepresentable. Share button only visible when audioFileURL exists.

**Notes:**
- Used `UIViewControllerRepresentable` wrapping `UIActivityViewController` instead of `ShareLink` for full control over file sharing
- Share button is conditionally rendered only when `session.audioFileURL != nil`
- No design reference in .pen file for share UI; used existing toolbar button placement

---

### F7-T2 — Export individual event clips

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-07 |
| Completed | 2026-05-07 |

**Acceptance Criteria:**
- [x] Each event row in SessionDetailView has an export/share button
- [x] Tapping export generates a short audio clip (event timestamp ± 2 seconds)
- [x] Clip is shared via UIActivityViewController
- [x] Builds with zero errors

**Prompt Used:**
Added share button to EventRow, exportAndShare function using AVAssetExportSession to trim .caf to .m4a clip (event ± 2s), shared via ActivityView sheet.

**Notes:**
- Used AVAssetExportSession with AppleM4A preset to export trimmed clips as .m4a for better compatibility
- Clip trim range: max(0, eventTime - 2s) to min(duration, eventTime + event.duration + 2s)
- Temp file cleaned up by system automatically; named with event UUID to avoid collisions
- EventRow now takes both onPlay and onShare closures

---

## Update Rules (for the AI)

After completing a task in this feature:
1. Check off acceptance criteria boxes
2. Fill Started/Completed dates in task table and detail section
3. Set task Status to **Done**
4. Fill "Prompt Used" with the prompt summary
5. Add any notes about decisions or deviations
6. If ALL tasks are Done → set feature Status to **Done**, fill Completed date
7. Also update the index file (docs/FeatureTracker.md)
