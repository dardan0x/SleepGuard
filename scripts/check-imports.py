#!/usr/bin/env python3
"""Import check: every project module a target imports is declared in its manifest.

A module built for another package in the same graph is importable even when the
target doesn't declare it (F27-T9: `Recordings` imported `AudioEngine` through
`Services`). The build can't catch that, so this script does: for each target in each
`Packages/*/Package.swift`, every `import X` where X is a project module (a local
package target, a SleepGuardShared product, Factory) must be a declared
dependency; a sibling target of the same package counts only when declared
(the seven features share `Packages/Features`). A feature target also never declares another
feature target (features talk through Routing). Nothing is re-exported here
(`@_exported import` is banned by check-layering.py, F27-T26), so each target
declares every module its files import. Apple SDK modules are not checked.

Exits 1 with a file:line listing when any import is undeclared.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Products of external packages the project uses.
EXTERNAL_MODULES = {
    "SleepCore", "SleepStrings", "SleepMelodies", "SleepGuardDesignKit", "SleepGuardContentKit",
    "SleepStore", "SleepLogging", "SleepAudioKit", "SleepFiles", "SleepNotifications", "SleepSettings",
    "SleepHealthKit", "FactoryKit", "FactoryTesting",
}

TARGET_START = re.compile(r"\.(target|testTarget)\(")
IMPORT = re.compile(r"^\s*(@_exported\s+)?(?:@testable\s+)?(?:public\s+|internal\s+|package\s+|private\s+)?import\s+(\w+)")


def bracket_end(text: str, start: int) -> int:
    """Index just past the bracket that closes the one at `start`."""
    depth = 0
    for index in range(start, len(text)):
        if text[index] in "([":
            depth += 1
        elif text[index] in ")]":
            depth -= 1
            if depth == 0:
                return index + 1
    return len(text)


def targets(package: pathlib.Path):
    """(name, source dir, declared modules) for every target in the manifest."""
    manifest = (package / "Package.swift").read_text()
    for match in TARGET_START.finditer(manifest):
        body = manifest[match.end() - 1:bracket_end(manifest, match.end() - 1)]
        name = re.search(r'name:\s*"(\w+)"', body).group(1)
        path = re.search(r'path:\s*"([^"]+)"', body)
        folder = "Tests" if match.group(1) == "testTarget" else "Sources"
        source = package / (path.group(1) if path else f"{folder}/{name}")
        declared = set()
        deps = re.search(r"dependencies:\s*\[", body)
        if deps:
            block = body[deps.end() - 1:bracket_end(body, deps.end() - 1)]
            declared |= set(re.findall(r'\.product\(\s*name:\s*"(\w+)"', block))
            declared |= set(re.findall(r'(?<![\w:])"(\w+)"', re.sub(r'\.product\([^)]*\)', "", block)))
        yield name, source, declared


def swift_files(folder: pathlib.Path):
    return [path for path in folder.rglob("*.swift") if "/.build/" not in path.as_posix()]


# Xcode targets: their folder and their native-target name in the project.
APP_TARGETS = {"SleepGuard": "SleepGuard", "SleepGuardWidgets": "SleepGuardWidgetsExtension"}


def linked_products(target: str) -> set[str]:
    """The package products an Xcode target links (`packageProductDependencies`)."""
    project = (ROOT / "SleepGuard.xcodeproj/project.pbxproj").read_text()
    start = project.index(f"/* {target} */ = {{\n\t\t\tisa = PBXNativeTarget;")
    block = project[start:project.index("productType", start)]
    deps = block[block.index("packageProductDependencies"):]
    return set(re.findall(r"/\* (\w+) \*/", deps[:deps.index(");")]))


def main() -> int:
    packages = sorted(path.parent for path in ROOT.glob("Packages/*/Package.swift"))
    all_targets = [(package, *target) for package in packages for target in targets(package)]
    project_modules = EXTERNAL_MODULES | {name for _, name, _, _ in all_targets}

    # What each local module re-exports.
    reexports = {}
    for _, name, source, _ in all_targets:
        exported = set()
        for path in swift_files(source):
            for line in path.read_text().splitlines():
                match = IMPORT.match(line)
                if match and match.group(1):
                    exported.add(match.group(2))
        reexports[name] = exported

    violations = []
    for package, name, source, declared in all_targets:
        allowed = declared | {name}
        for module in list(declared):
            allowed |= reexports.get(module, set())
        for path in swift_files(source):
            for number, line in enumerate(path.read_text().splitlines(), 1):
                match = IMPORT.match(line)
                if not match:
                    continue
                module = match.group(2)
                if module in project_modules and module not in allowed:
                    rel = path.relative_to(ROOT).as_posix()
                    violations.append(f"{rel}:{number}: imports {module}, which target {name} doesn't declare")

    # Features never depend on each other (ADR 0001, 0011): they share one
    # package, so the edge would be a single name in its manifest.
    features = ROOT / "Packages/Features"
    feature_names = {name for package, name, _, _ in all_targets if package == features and not name.endswith("Tests")}
    for package, name, _, declared in all_targets:
        if package == features and not name.endswith("Tests"):
            for other in sorted(declared & feature_names - {name}):
                violations.append(f"Packages/Features/Package.swift: feature {name} depends on feature {other}; route through Routing instead")

    # The app and widget targets link products in the Xcode project.
    for folder, target in APP_TARGETS.items():
        linked = linked_products(target)
        for path in swift_files(ROOT / folder):
            for number, line in enumerate(path.read_text().splitlines(), 1):
                match = IMPORT.match(line)
                if match and match.group(2) in project_modules and match.group(2) not in linked:
                    rel = path.relative_to(ROOT).as_posix()
                    violations.append(f"{rel}:{number}: imports {match.group(2)}, which target {target} doesn't link (Xcode project)")

    if violations:
        print("Import violations (declare the dependency in Package.swift or the Xcode project; features never depend on each other):")
        for violation in violations:
            print(f"  {violation}")
        return 1
    print(f"Import check passed ({len(all_targets)} targets in {len(packages)} packages, and the app and widget targets).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
