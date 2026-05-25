# F13 — CloudKit Sync

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Backlog |
| **Priority** | P2 |
| **Version** | V2.0 |
| **Blocked By** | — |
| **Started** | — |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

Sync sleep sessions across all user's devices via CloudKit. Enables seamless access to recordings and statistics on iPhone, iPad, and (future) Mac.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F13-T1 | CloudKit container + capability setup | Setup | Backlog | — | App Target | — | — |
| F13-T2 | SwiftData CloudKit integration | Backend | Backlog | F13-T1 | Models | — | — |
| F13-T3 | Sync status / conflict UI | UI | Backlog | F13-T2 | Settings | — | — |

## Task Details

### F13-T1 — CloudKit container + capability setup

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/dependencies.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] CloudKit capability added to app target
- [ ] CloudKit container identifier configured
- [ ] Background remote notifications enabled
- [ ] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_(decisions, issues, deviations)_

---

### F13-T2 — SwiftData CloudKit integration

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/state.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] Model container configured with `.cloudKitDatabase(.private("..."))`
- [ ] SleepSession and SnoreEvent models are CloudKit-compatible
- [ ] Data syncs across devices automatically
- [ ] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_(decisions, issues, deviations)_

---

### F13-T3 — Sync status / conflict UI

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] Sync status indicator in Settings (last sync time, pending changes)
- [ ] Manual "Sync Now" button
- [ ] Conflict resolution strategy documented (last-write-wins)
- [ ] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_(decisions, issues, deviations)_

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
