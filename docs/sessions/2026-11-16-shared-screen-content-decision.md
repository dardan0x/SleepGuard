
### Completed
- F25-T1: decided with the owner which views are shared. Screen content (a screen's loaded layout) moves to a new shared product, `SleepGuardContentKit`; screens, feature packages and `DesignSystem` stay.

### Architecture Decisions
- ADR 0006. Three layers: components (shared kit), screen content (shared content kit), screens (this app). The test: renderable from plain values alone → shared.
- `DesignSystem` stays as the bridge to the shared code (it depends on `Models` and Factory).

### Files Changed
| File | What Changed |
|------|--------------|
| `docs/adr/0006-shared-screen-content.md` | New ADR |
| `AGENTS.md`, `CLAUDE.md` | The three-layer rule; where a values-only view goes |
| `docs/trackers/f25-shared-screen-content.md` | New tracker (6 tasks) |
| `docs/FeatureTracker.md` | F25 row, activity log |

### Build Status
- Docs only.

### Next Session
- F25-T2: the four Statistics screens host the shared content (after the shared release that adds it).
