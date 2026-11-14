// The string catalog and the generated `Strings` enum live in the shared
// `SleepGuardShared` repo (`SleepStrings`). Re-exported so `Strings.x` keeps
// working in every file that imports `DesignSystem`: the app and widget targets
// build with member import visibility, where a typealias alone doesn't make the
// enum's members visible.
@_exported import SleepStrings
