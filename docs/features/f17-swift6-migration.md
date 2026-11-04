# F17 — Swift 6 Migration

Migration of the entire SleepGuard codebase (11 SPM packages + app target) to the Swift 6 language mode with strict concurrency, following the architecture adopted by IceCubesApp (docs sync source). No user-facing behavior changes except one noted animation fallback.

## Files

| File | Change | Purpose |
|------|--------|---------|
| `Packages/*/Package.swift` (×11) | tools 5.9 → 6.2, `swiftLanguageMode(.v6)`; UI packages add `.defaultIsolation(MainActor.self)` | Package manifests (Models/Env/AudioEngine: v6 only; DesignSystem/Onboarding/SleepSession/Statistics/Recordings/Personalization/Settings/Learn: v6 + default isolation; Personalization also on its test target) |
| `SleepGuard.xcodeproj/project.pbxproj` | `SWIFT_VERSION` 5.0 → 6.0, `SWIFT_STRICT_CONCURRENCY = complete` (Debug + Release) | App target build settings |
| `Packages/Models/Sources/Data/SnoreEpisode.swift` | `SnoringEpisode` no longer `Sendable` | Held `[SnoreEvent]` @Model refs; consumed only in MainActor UI |
| `Packages/AudioEngine/Sources/Engine/AudioClipExtractor.swift` | `ClipResult: Sendable`; `extractSingleClip` takes Sendable params | `withTaskGroup` + `addTask` sending rules |
| `Packages/Env/Sources/Services/StorageLimitEnforcer.swift` | Class `Sendable`; `enforceLimits` `@MainActor`, `MainActor.run` removed | Static-singleton safety; wrapper closure sent `ModelContext` |
| `Packages/Env/Sources/Services/WatchConnectivityManager.swift` | `nonisolated` delegate methods, MainActor hops for state | WCSessionDelegate conformance isolation |
| `Packages/Statistics/Sources/Views/TrendsView.swift` | `TimeRange` annotated `@MainActor` | Nonisolated enum referenced now-MainActor `Strings` |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | `EventCategoryFilter` annotated `@MainActor` | Same Strings isolation fallout |
| `Packages/SleepSession/Sources/Views/MelodyPickerSheet.swift` | `PreviewSpeakerIcon` extracted with `#available(iOS 18, *)` | Conformance availability: bounce repeating is iOS 18+; pulse fallback on 17 |
| `Packages/Recordings/Sources/Helpers/WaveformGenerator.swift` | Static methods `nonisolated` | Pure utility called off-main from `Task.detached` |
| `Packages/Recordings/Sources/Views/PlayerSheetView.swift` | `event.snoreDuration` hoisted before `Task.detached` | Non-Sendable @Model capture |
| `AGENTS.md`, `CLAUDE.md` | Concurrency rules updated | Swift 6 isolation split, delegate pattern, capture rules |
| `docs/architecture/{concurrency,overview,modules,rules,INDEX,views,feature-template,PROMPTS}.md` | Rewritten/updated for Swift 6 | Local-only (gitignored) reference |

## Routes

None — no navigation changes.

## State / Build Settings

| Setting | Before | After | Scope |
|---------|--------|-------|-------|
| `SWIFT_VERSION` | 5.0 | 6.0 | App target Debug+Release |
| `SWIFT_STRICT_CONCURRENCY` | — | complete | App target Debug+Release |
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | MainActor | MainActor (unchanged) | App target |
| Language mode | Swift 5 | v6 (`swiftLanguageMode(.v6)`) | All 11 packages + test target |
| Package isolation | — | `.defaultIsolation(MainActor.self)` | 8 UI packages |

## Edge Cases / Lessons (encoded in `docs/architecture/concurrency.md`)

- **@Model classes are never Sendable** — destructure Sendable fields before `@Sendable`/detached/task-group closures.
- **`MainActor.run` wrappers send their captures** — non-Sendable `ModelContext`/@Model objects can't ride along; restructure the function's isolation instead.
- **Delegate protocols are nonisolated** — `nonisolated` methods + synchronous payload parsing + `Task { @MainActor in }` for state.
- **SDK gaps**: `installTap`, `requestMediaDataWhenReady`, `decidePolicy` blocks are not Sendable-checked — compiled unchanged, flagged for on-device verification.
- **Conformance availability**: `.bounce.repeating` is iOS 18+ by conformance annotation; gate with `#available`.
- **`.defaultIsolation` makes all package API MainActor** — non-view consumers (enums/extensions referencing `Strings`) may need `@MainActor`.

## Tasks Completed

F17-T1 … F17-T16 (see `docs/trackers/f17-swift6-migration.md`).

## Follow-up

- On-device recording test (mic tap path + AAC encode + melody playback) — SDK-unchecked blocks.
- `PersonalizationTests` not wired into any scheme.
- WatchApp modernization when integrated as a target.
