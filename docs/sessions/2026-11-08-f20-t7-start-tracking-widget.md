### Completed
- F20-T7: Start Tracking widget (small), a one-tap tile styled after `StartRecordingButton` that deep-links to the live session screen.

### Technical Details
- **`StartTrackingWidgetView`**: `VStack(spacing: 14)` of a record dot (`Circle` 44pt `scoreRed.opacity(0.25)` + `Circle` 22pt `scoreRed`) and `Text(Strings.actionStartRecording)` (17pt semibold, `textPrimary`, centered).
- **Background**: `containerBackground(for: .widget) { ZStack { bgSecondary; LinearGradient(scoreRed 0.35 → 0, .top → .center) } }`, the widget version of the button's red inner glow.
- **Tap**: `.widgetURL(WidgetDeepLink.startTracking.url)` → T4 routes to `.liveSession`.
- **Provider**: reuses `WidgetSnapshotProvider` and ignores the entry.
- **Simulator verification (BD630AD5)**: the gallery shows 4 pages (LN small, LN medium, Trend, Start). Placed the tile; tap → live session pre-start screen ✔︎. Extension `phys_footprint_peak` 25 MB with 3 widgets.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuardWidgets/StartTrackingWidget.swift` | +57 (new) | Widget config + view + preview |
| `SleepGuardWidgets/SleepGuardWidgetsBundle.swift` | +1 | Registers `StartTrackingWidget` |
| `Packages/DesignSystem/Sources/Resources/Strings.txt` / `Localizable.xcstrings` / `Strings.swift` | +2 keys | `widget.start.name/description` |
| `docs/trackers/f20-home-screen-widgets.md`, `docs/FeatureTracker.md` | — | T7 done, 7/9, currently active → T8 |

### Architecture Decisions
- **Tokens over the button's hardcoded colors**: `StartRecordingButton`/`RecordingActionButton` use `Color(hex: "#FF453A")` and a non-token `#22232B` fill. The widget uses `scoreRed` (same hex) and `bgSecondary`, matching the other widgets and the token rule.
- **Static dot**: WidgetKit doesn't run repeat-forever animations, so the pulsing dot is drawn at rest (halo + dot).
- **No App Intent button**: a `widgetURL` on the whole tile is the simplest working tap target, and the live session screen still needs the user to confirm "Start Recording".

### Build Status
- **BUILD SUCCEEDED**: zero errors, zero warnings. Layering check passed. No hardcoded user-facing strings.

### Not included in this commit
- `SleepGuard.xcodeproj/project.pbxproj`: Xcode self-reference junk again.

### Changes done
```
- Add StartTrackingWidget (small): record dot + "Start Recording" on red glow, tap → sleepguard://start
- Register it in the widget bundle
- Add widget.start strings
- Update F20 tracker, FeatureTracker; add session fragment
```

### Next Session
- F20-T8: Lock Screen accessories (`accessoryCircular` score gauge, `accessoryRectangular` score + snoring, `accessoryInline`) on the Last Night widget, checked in vibrant rendering mode.

### Open Questions
- Carry-overs: briefing covering deep-linked screens; widget background color; empty-state string key naming.
