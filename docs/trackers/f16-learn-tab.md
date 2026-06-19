# F16 — Learn Tab

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P2 |
| **Version** | V4 |
| **Blocked By** | — |
| **Started** | 2026-06-18 |
| **Completed** | 2026-06-18 |
| **Feature Doc** | [f16-learn-tab.md](../features/f16-learn-tab.md) |

## Summary

A new **Learn** tab that loads a remote-configured URL in a web view. Visibility,
URL, and tab order are controlled by the Firebase Remote Config key
`feature_learn`. Links tapped inside the web view open externally in Safari
instead of navigating within the app.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F16-T1 | Learn tab with remote config + external links | Feature | Done | — | Learn | 2026-06-18 | 2026-06-18 |

## Task Details

### F16-T1 — Learn tab with remote config + external links

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/navigation.md`, `docs/architecture/state.md`, `docs/remote-config-schema.md` |
| Status | Done |
| Started | 2026-06-18 |
| Completed | 2026-06-18 |

**Acceptance Criteria:**
- [x] `AppTab` includes `.learn` with `book.fill` icon
- [x] `LearnTabConfig` model carries `isVisible`, `url`, and `order`
- [x] `RemoteConfigLoader` parses the top-level `feature_learn` key (JSON object or boolean)
- [x] `AppConfig.visibleTabsInOrder` inserts `.learn` when `feature_learn.visibility` is true
- [x] New `Packages/Learn` feature package with `LearnView`/`LearnTab`
- [x] Web view intercepts clicks on `<a data-open-external="true">` and opens them via `UIApplication.shared.open(_:)`; other links browse inside the web view
- [x] `tab.learn` and `learn.error.noContent` localized
- [x] Debug config panel can override visibility, URL, and order
- [x] Build succeeds with zero errors

**Prompt Used:**
Create a new Learn tab whose visibility and URL are driven by Firebase Remote Config key `feature_learn` (JSON with `visibility` and `url`, or boolean). The tab renders a web view; links inside open externally via `UIApplication.shared.open(url)`.

**Notes:**
- `feature_learn` supports both `{"visibility": true, "url": "...", "order": 2}` and plain `true`/`false`.
- Default order is `2` (after Media, before Settings).
- Learn tab is hidden by default when the key is missing or malformed.
- Package follows project rule: depends only on Models, Env, DesignSystem.
