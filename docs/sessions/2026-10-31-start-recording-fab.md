---
date: 2026-10-31
feature: none
branch: ui/start-recording-fab
title: Start Recording Button Redesign + Surface Recolor
---

### Completed
- **StartRecordingButton → centered gradient CTA (final design)**: Full-width 56pt button pinned to the bottom of each screen — blue gradient fill (`#5E9CFF` → `#0A84FF`), white moon icon + "Start Recording" label, soft blue glow shadow, 16pt corner radius. Press feedback via `ScaleButtonStyle`, haptic via `HapticManager`. The red "alarm" styling was dropped in favor of the calm blue accent. API: `init(height:action:)`.
- **Iterated twice based on user feedback**: v1 was a circular red FAB bottom-right (rejected — felt alarm-like, action too hidden); v2 is the centered blue gradient CTA (accepted direction: user-friendly, elegant, modern).
- **Positioned on all 4 call sites**: Statistics (loaded + empty) pin the CTA below the scroll content above the tab bar; Recording prestart and Onboarding page 5 use a centered CTA with a small text button beneath (Cancel / "I'll do it later").
- **surface2 recolored**: `#2C2C2E` → `#22232B` (cool graphite with a subtle blue undertone harmonizing with the `#5E9CFF` accent). Single-token change in `Theme`; propagates everywhere via the `bgCard` alias — all cards, calendar day cells, calendar/header pills.

### Technical Details
- Tab-bar clearance needs no special handling on any OS: the CTA sits in the VStack below the ScrollView, and `MainTabView.customTabView` already pads tab content `.bottom, 60` above the custom floating tab bar; on iOS 26+ the system tab bar contributes safe-area insets. A 10pt bottom padding keeps the CTA off the screen edge.
- `RecordingActionButton` and `StopRecordingButton` are unchanged — only the start button was redesigned.
- Verified on iPhone 16e simulator (iOS 26.2 runtime, custom tab bar path): Statistics empty state and Recording prestart both render the new CTA correctly, clearing the tab bar; Recording prestart cards render in the new graphite surface.
- `build_sim` compiles only — after it, the new bundle must be installed via `get_sim_app_path` + `install_app` before relaunching, otherwise the simulator keeps running the old build.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Components/StartRecordingButton.swift` | rewritten (twice) | Final: blue gradient CTA, moon icon, glow shadow; v1 circular FAB with pulse ring was replaced after user feedback |
| `Packages/SleepSession/Sources/Views/RecordingPrestartView.swift` | ±10 | Bottom bar: centered CTA with Cancel beneath (was Cancel-left/FAB-right HStack in v1) |
| `Packages/Statistics/Sources/Views/StatisticsLoadedView.swift` | ±14 | Reverted FAB overlay to pinned bottom CTA in outer VStack; removed `fabBottomPadding` |
| `Packages/Statistics/Sources/Views/StatisticsEmptyView.swift` | ±13 | Reverted FAB overlay to pinned bottom CTA; removed `fabBottomPadding` |
| `Packages/Onboarding/Sources/Views/OnboardingPage5View.swift` | ±6 | Bottom row: centered CTA with secondary text button beneath |
| `Packages/DesignSystem/Sources/Components/Theme.swift` | +1/-1 | `surface2` `#2C2C2E` → `#22232B` (cool graphite) |

### Architecture Decisions
- **Centered bottom CTA over FAB / tab-bar center**: most discoverable for the app's single primary action; always above the tab bar; consistent across Statistics loaded/empty states without OS-conditional positioning.
- **Blue accent over red for the start action**: red is reserved for stop/destructive and snore-loud semantics; blue matches the sleep/calm branding and the `#5E9CFF` accent.
- **Stop button untouched**: the stop button keeps its wide red pill so it stays unmissable on the bedside clock screen.

### Build Status
- **BUILD SUCCEEDED** — verified via XcodeBuildMCP `build_sim` + reinstall + visual check on simulator.

### Suggested Branch
`ui/start-recording-fab`

### Suggested Commit
`[UI] — Redesign Start Recording as centered blue gradient CTA, recolor surface2 to graphite`

### Changes done
```
- StartRecordingButton rewritten as blue gradient CTA (#5E9CFF → #0A84FF), moon icon + label, glow shadow
- Pinned centered at bottom on Statistics loaded/empty, Recording prestart, Onboarding page 5
- v1 circular red FAB replaced after user feedback (kept in git history)
- surface2 recolored to cool graphite #22232B (propagates to all cards via bgCard alias)
```

### Open Questions
- The new CTA and graphite surface are not in `designs/SleepGuard.pen` — they deviate from the design file per user request. Design file not updated.
