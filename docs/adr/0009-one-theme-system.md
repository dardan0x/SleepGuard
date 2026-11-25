# ADR 0009: One theme system: the kit's `Theme` in the environment

- **Status:** Accepted
- **Date:** 2026-11-26
- **Task:** F27-T13 (principal review Q21, Q24, Q67); supersedes the bridge part of ADR 0005

## Context

When the design kit moved to the shared repo (ADR 0005), 131 call sites read SleepGuard's own theme service, so the service was kept: `AppTheme` (`@Observable`, built from `Theme.sleepGuard`) behind a 40-member `ThemeProviding` protocol, resolved with `@Injected(\.theme)`. The kit's components read a `Theme` value from `@Environment(\.theme)`, and the app root bridged the two with `AppTheme.shared.designKitTheme`.

Two systems for one job:
- A preview or test that swapped one didn't restyle the other. Registering a custom theme in the container never reached the kit's components, because the bridge read `.shared`.
- `ThemeProviding` was a 40-requirement protocol that nothing faked (an Interface Segregation violation the review called out).
- Readers had to learn two ways to colour a view.

## Decision

- Every view reads `@Environment(\.theme) private var theme` (the kit's `Theme`): `theme.palette.x`, `theme.radii.card` / `.small`, `theme.scoreColor(_:)`, and `theme.intensityColor(_:)` (a DesignSystem extension).
- The app root sets `.environment(\.theme, .sleepGuard)`. Widgets get the environment default, which is the same theme.
- Deleted: `AppTheme`, `ThemeProviding`, DesignSystem's `Container` registration and `ThemeOverrideTests` (replaced by `ThemeEnvironmentTests`). DesignSystem no longer depends on Factory.
- The rule "`@Environment` only for `RouterPath` and system values" now includes `theme`: a value that varies by host (preview, render test, brand) belongs in the environment, not in a service.

## Consequences

**Better:** one way to theme, the same one the shared kit and UIKitWay use. A preview restyles every view by setting one value. Removing 40 mirrored properties means adding a kit token no longer needs an app-side edit.

**Limits, honestly:**
- The environment default is a real theme (`.sleepGuard`), so a host that forgets to set it still looks right. That's fine for a single-theme app, but it would hide a missing injection in a multi-brand one (the review's Q51 suggests a loud Debug default there).
- No visual change was intended or seen: content pixels are identical on Settings, and the dashboard and detail match by eye. The token values come from the same `Theme.sleepGuard`.

## Alternatives

- **Keep `AppTheme` as the environment's source:** two names for one value, which is the problem itself.
- **Kit components read a service:** impossible; the kit has no DI and serves UIKit hosts.
