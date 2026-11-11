#!/usr/bin/env python3
"""Layering check: UI dependencies must not leak into non-view code.

Rules (see AGENTS.md "UI Dependencies in Non-View Code"):
  1. `import DesignSystem` is only allowed in view files (Sources/Views/,
     Sources/Components/) and in the explicit content-engine allowlist
     (engines whose output IS user-facing text).
  2. Core packages (Models, AudioEngine) must not import SwiftUI/UIKit/
     DesignSystem at all.
  3. Env (services) must not import SwiftUI: navigation lives in the
     `Routing` package (docs/adr/0001-routing-package.md).
  4. Feature packages and DesignSystem never touch an app service's
     `.shared`: they resolve it from the container (`@Injected` in views,
     `Container.shared.x()` in state owners), so tests/previews can swap it.

Exits 1 with a file:line listing when any violation is found.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

DESIGNSYSTEM_ALLOWLIST = {
    "Packages/Personalization/Sources/Engine/BriefingEngine.swift",
    "Packages/Personalization/Sources/Engine/QuoteBank.swift",
}

# UIKit is allowed here: audio-session interruption/route observation behind
# `#if canImport(UIKit)` — system infrastructure, not UI chrome.
CORE_UIKIT_ALLOWLIST = {
    "Packages/AudioEngine/Sources/Engine/AudioRecorder.swift",
}

CORE_PREFIXES = (
    "Packages/Models/",
    "Packages/AudioEngine/",
)

ENV_PREFIX = "Packages/Env/Sources/"

# Packages above Env: everything except the core/service/navigation layers.
SERVICE_CONSUMER_EXCLUDED = ("Packages/Models/", "Packages/AudioEngine/", "Packages/Env/", "Packages/Routing/")

SERVICE_SINGLETON = re.compile(
    r"\b(AppConfig|AudioRecorder|CustomMelodyStorage|HealthKitSync|HapticManager|"
    r"NotificationPermissionManager|PendingSessionStore|RecordingDelayManager|"
    r"SessionCheckpointStore|SessionCommitter|SessionManager|SnoreInterrupterPlayer|SoundAnalysisDetector|"
    r"UserPreferences|WatchConnectivityManager|SessionRawLogWriter|StorageLimitEnforcer|"
    r"TabCoordinator|Theme)\.shared\b")


def main() -> int:
    violations = []
    for swift in sorted(ROOT.glob("Packages/**/*.swift")):
        rel = swift.relative_to(ROOT).as_posix()
        in_view_code = "/Views/" in rel or "/Components/" in rel
        in_core = rel.startswith(CORE_PREFIXES)
        in_env = rel.startswith(ENV_PREFIX)
        consumes_services = (
            "/Sources/" in rel
            and not rel.startswith(SERVICE_CONSUMER_EXCLUDED)
            and not rel.endswith("/Container.swift")
        )
        for number, line in enumerate(swift.read_text().splitlines(), 1):
            stripped = line.strip()
            if stripped == "import DesignSystem" and not in_view_code and rel not in DESIGNSYSTEM_ALLOWLIST:
                violations.append(f"{rel}:{number}: DesignSystem import outside view code")
            if in_core and stripped in ("import SwiftUI", "import DesignSystem"):
                violations.append(f"{rel}:{number}: '{stripped.split()[1]}' import in core package")
            if in_core and stripped == "import UIKit" and rel not in CORE_UIKIT_ALLOWLIST:
                violations.append(f"{rel}:{number}: 'UIKit' import in core package")
            if in_env and stripped == "import SwiftUI":
                violations.append(f"{rel}:{number}: 'SwiftUI' import in Env (navigation belongs in Routing)")
            if consumes_services and not stripped.startswith("//") and (match := SERVICE_SINGLETON.search(line)):
                violations.append(f"{rel}:{number}: '{match.group(0)}' — resolve from the container instead")

    if violations:
        print("Layering violations (see AGENTS.md 'UI Dependencies in Non-View Code'):")
        for violation in violations:
            print(f"  {violation}")
        return 1
    print(f"Layering check passed ({len(list(ROOT.glob('Packages/**/*.swift')))} files scanned).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
