# Feature: F16 — Learn Tab

## Status: Done
## Completed: 2026-06-18

## Summary

A new **Learn** tab that loads a remote-configured URL in a web view. The tab's
visibility, URL, and order are controlled by the Firebase Remote Config key
`feature_learn`. Any link tapped inside the web view opens externally in Safari
via `UIApplication.shared.open(_:)` instead of navigating within the app.

## Files

| File | Package | Purpose |
|------|---------|---------|
| `Packages/Learn/Package.swift` | Learn | Package manifest (deps: Models, Env, DesignSystem) |
| `Packages/Learn/Sources/Views/LearnView.swift` | Learn | `WKWebView` wrapper with external link handling |
| `Packages/Learn/Sources/Views/LearnTab.swift` | Learn | Tab wrapper with `RouterPath`/`TabCoordinator`; empty-state fallback |
| `Packages/Models/Sources/Data/AppConfigModels.swift` | Models | Added `.learn` to `AppTab`; added `LearnTabConfig` |
| `Packages/Env/Sources/Services/AppConfig.swift` | Env | Stores/persists `remoteLearnTab`; exposes `learnTabConfig`; inserts `.learn` into `visibleTabsInOrder` |
| `SleepGuard/RemoteConfig/RemoteConfigLoader.swift` | App | Parses top-level `feature_learn` key (JSON object or boolean) |
| `SleepGuard/MainTabView.swift` | App | Imports `Learn`; maps `.learn` to `LearnTab()` and title |
| `SleepGuard.xcodeproj/project.pbxproj` | App | Local package reference + product dependency for `Packages/Learn` |
| `Packages/Settings/Sources/Views/DebugConfigView.swift` | Settings | Debug override for Learn visibility, URL, and order |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | DesignSystem | `tab.learn`, `learn.error.noContent` |
| `Packages/DesignSystem/Sources/Strings.swift` | DesignSystem | Auto-generated accessors |

## Routes

No new router destinations. The Learn tab is integrated into `AppTab` and
rendered directly by `MainTabView.view(for:)`.

## State

| Property | Type | Scope | Description |
|----------|------|-------|-------------|
| `remoteLearnTab` | `LearnTabConfig?` | `AppConfig` | Last applied/cached remote value |
| `debugLearnTab` | `LearnTabConfig?` | `AppConfig` (DEBUG) | Local override from debug panel |
| `learnTabConfig` | `LearnTabConfig?` | `AppConfig` | Resolved effective config |
| `visibleTabsInOrder` | `[AppTab]` | `AppConfig` | Includes `.learn` when visible |

## Edge Cases

- **Missing `feature_learn` key** → Learn tab hidden; no crash.
- **Malformed JSON** → Decode fails; Learn tab hidden.
- **`feature_learn: true` (boolean)** → Visible with no URL; empty-state shown.
- **`feature_learn: false` (boolean)** → Hidden.
- **URL missing while visible** → `LearnTab` shows empty state with `learn.error.noContent`.
- **Link tap inside web view** → Injected JavaScript watches for clicks on `<a data-open-external="true">` and posts the URL to a `WKScriptMessageHandler`, which calls `UIApplication.shared.open(url)`. Links without the attribute keep browsing inside the web view.
- **Tab hidden while selected** → Existing `ensureValidSelection(among:)` falls back to first visible tab.
- **Debug override** → In DEBUG, `DebugConfigView` can toggle visibility, edit URL, and set order.

## Tasks Completed

| Task ID | Name | Package |
|---------|------|---------|
| F16-T1 | Learn tab with remote config + external links | Learn / Models / Env / App / Settings / DesignSystem |

## Website-Side Integration

The app injects JavaScript into the Learn web view. That script listens for
clicks, walks up to the nearest `<a>` tag, and checks for the attribute
`data-open-external="true"`.

| Markup | Behavior |
|--------|----------|
| `<a href="https://..." data-open-external="true">` | Opens in Safari / system browser via `UIApplication.shared.open(_:)` |
| `<a href="/...">` or `<a href="https://...">` | Navigates inside the app web view |
| `<button data-open-external="true">` | Ignored — the marker must be on an `<a>` tag with an `href` |

### Minimal example

```html
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
  </head>
  <body>
    <h1>Learn</h1>
    <p>
      <a href="https://example.com/article" data-open-external="true">
        Read full article in browser
      </a>
    </p>
    <p>
      <a href="/lesson-2">Next lesson (stays in app)</a>
    </p>
  </body>
</html>
```

### Important details

- The attribute value must be exactly `"true"` (lowercase).
- The link must be a real `<a href="...">` element. Buttons, divs, or
  JavaScript-only `window.location` changes are not intercepted.
- The interception happens at click time. Right now it only covers user taps,
  not programmatic navigation.
- Styling is unchanged — use your normal CSS for `<a>` tags.

## Notes

- `feature_learn` schema: `{"visibility": true, "url": "https://...", "order": 2}`.
- `order` is optional and defaults to `2` (after Sessions, before Settings).
- The `Learn` package only imports `Models`, `Env`, and `DesignSystem`, following the project module rules.
