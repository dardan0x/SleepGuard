#!/usr/bin/env python3
"""Import check: every project module a target imports is declared in its manifest.

A module built for another package in the same graph is importable even when the
target doesn't declare it (F27-T9: `Recordings` imported `AudioEngine` through
`Env`). The build can't catch that, so this script does: for each target in each
`Packages/*/Package.swift`, every `import X` where X is a project module (a local
package target, a SleepGuardShared product, Factory) must be a declared
dependency, a target of the same package, or re-exported (`@_exported import`)
by a declared dependency. Apple SDK modules are not checked.

Exits 1 with a file:line listing when any import is undeclared.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Products of external packages the project uses.
EXTERNAL_MODULES = {
    "SleepCore", "SleepStrings", "SleepMelodies", "SleepGuardDesignKit", "SleepGuardContentKit",
    "FactoryKit", "FactoryTesting",
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
        siblings = {other for pkg, other, _, _ in all_targets if pkg == package}
        allowed = declared | siblings | {name}
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

    if violations:
        print("Undeclared imports (add the dependency to the target in Package.swift):")
        for violation in violations:
            print(f"  {violation}")
        return 1
    print(f"Import check passed ({len(all_targets)} targets in {len(packages)} packages).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
