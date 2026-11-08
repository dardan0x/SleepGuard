
### Completed
- F20-T8 (partial): the Last Night widget now supports `accessoryCircular`, `accessoryRectangular` and `accessoryInline`. It builds clean, but the Lock Screen render in vibrant mode has **not** been verified.

### Technical Details
- `LastNightWidget.supportedFamilies` += the 3 accessory families (same widget kind, so the gallery shows them under Last Night on the Lock Screen).
- `LastNightWidgetView` switches on `widgetFamily`: accessory families → `LastNightCircularView` / `LastNightRectangularView` / `LastNightInlineView` (each handles `night == nil`); system families keep the T5 behavior.
- Circular: `Gauge(value: score, in: 0...100)` + `.accessoryCircularCapacity`, current value = score, `widgetAccentable()`; empty = `AccessoryWidgetBackground` + `moon.zzz.fill`.
- Rectangular: headline "Last Night" (accentable) / score title2 bold + "SLEEP SCORE" caption / "Snoring <duration · %>"; empty = "No nights yet" / "Tap to start tracking".
- Inline: `Label(String(format: Strings.widgetLastNightInline, score, snoringDuration), systemImage: "moon.zzz.fill")` → "Score 82 · 51 mins snoring"; empty = "No nights yet".
- No Theme colors in accessories (the system renders them monochrome/vibrant).
- **Verification attempt**: AppleScript `Device → Lock` on the Simulator app didn't lock BD630AD5, because 3 simulators are booted (iPhone 16e, iphone 15, iPhone 17), even after raising the 16e window with `AXRaise`. Stopped after 2 attempts instead of looping. The clicks may have locked one of the other simulators.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuardWidgets/LastNightAccessoryViews.swift` | +75 (new) | Circular, rectangular, inline views |
| `SleepGuardWidgets/LastNightWidgetView.swift` | +11/−4 | Family switch routes accessory families |
| `SleepGuardWidgets/SleepGuardWidgets.swift` | +8/−1 | Accessory families + rectangular preview |
| `Packages/DesignSystem/Sources/Resources/Strings.txt` / `Localizable.xcstrings` / `Strings.swift` | +1 key | `widget.lastNight.inline` |
| `docs/trackers/f20-home-screen-widgets.md` | — | T8 In Progress, notes, blocker |

### Architecture Decisions
- **Accessories on the existing Last Night widget** instead of a separate widget: same data and tap target, one gallery entry. Splitting later would change kinds and drop placed widgets.
- **System gauge style** (`accessoryCircularCapacity`) instead of `SleepScoreGauge`: the custom gradient ring would be flattened in vibrant mode, and the system style matches other Lock Screen widgets.

### Build Status
- **BUILD SUCCEEDED**: zero errors, zero warnings. Layering check passed. No hardcoded user-facing strings.

### Changes done
```
- Add accessoryCircular / accessoryRectangular / accessoryInline to LastNightWidget
- New LastNightAccessoryViews (system gauge, vibrant-safe, empty states)
- Add widget.lastNight.inline string
- Update F20 tracker; add session fragment
```

### Next Session
- Finish F20-T8: manual Lock Screen check (lock iPhone 16e → long-press → Customize → Lock Screen → add SleepGuard Last Night circular + rectangular + inline above the clock). Then mark Done and update FeatureTracker counts.
- F20-T9: verification pass, feature doc, merge `feature/f20-home-screen-widgets` → `main`.

### Open Questions
- Carry-overs: briefing covering deep-linked screens; widget background color; empty-state string key naming.
