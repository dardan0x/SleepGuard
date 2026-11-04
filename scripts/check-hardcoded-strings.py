#!/usr/bin/env python3
"""Hardcoded-string check: user-facing literals must go through Strings.

Rules (see AGENTS.md "Localization (Non-Negotiable)"):
  1. Text("..."), Button("..."), navigationTitle("...") must not receive a
     hardcoded user-facing literal; use Strings.* (generated from
     Localizable.xcstrings).
  2. String(localized: "key") bypasses the generated accessor and is
     forbidden outside Packages/DesignSystem/Sources/Strings.swift.

Diff-based: only lines ADDED since the merge-base with the base ref are
checked, so pre-existing literals don't block PRs. Pass --base to override
the default (origin/main); CI passes the PR base branch or the pre-push SHA.

Allowed exceptions (AGENTS.md):
  - Lines inside `#if DEBUG` regions (dev-only panels, e.g. DebugConfigView).
  - Purely decorative punctuation / single characters ("·", "Z", emoji).
  - Interpolations with no semantic value (Text("\\(count)")).

Exits 1 with a file:line listing when any violation is found.
"""

import argparse
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

GENERATED_STRINGS = "Packages/DesignSystem/Sources/Strings.swift"

CALL_RE = re.compile(r'\b(Text|Button|navigationTitle)\(\s*"((?:[^"\\]|\\.)*)"')
BYPASS_RE = re.compile(r'\bString\(localized:\s*"((?:[^"\\]|\\.)*)"')
HAS_LETTER_RE = re.compile(r"[A-Za-z]")
HUNK_RE = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@")


def run_git(*args: str) -> str:
    return subprocess.run(
        ["git", *args], cwd=ROOT, capture_output=True, text=True, check=True
    ).stdout


def resolve_base(base_ref: str) -> str:
    """Resolve the diff base to a concrete commit."""
    try:
        base = run_git("merge-base", "HEAD", base_ref).strip()
        if base and base != run_git("rev-parse", "HEAD").strip():
            return base
    except subprocess.CalledProcessError:
        pass
    try:
        return run_git("rev-parse", "HEAD~1").strip()
    except subprocess.CalledProcessError:
        return ""


def debug_lines(path: pathlib.Path) -> set[int]:
    """Line numbers inside `#if DEBUG` regions (1-based)."""
    inside: set[int] = set()
    stack: list[bool] = []
    for number, line in enumerate(path.read_text().splitlines(), 1):
        stripped = line.strip()
        if stripped.startswith("#if"):
            cond = stripped[3:].strip()
            stack.append(cond == "DEBUG")
        elif stripped.startswith("#elseif"):
            if stack:
                stack[-1] = stripped[7:].strip() == "DEBUG"
        elif stripped.startswith("#else"):
            if stack:
                stack[-1] = not stack[-1]
        elif stripped.startswith("#endif"):
            if stack:
                stack.pop()
        if any(stack):
            inside.add(number)
    return inside


def is_exempt_literal(literal: str) -> bool:
    if "\\(" in literal:
        return True  # interpolation, no semantic value
    if len(literal) <= 2:
        return True  # decorative: "Z", "z", "·", emoji
    if not HAS_LETTER_RE.search(literal):
        return True  # punctuation / symbols only
    return False


def added_lines(base: str) -> dict[str, list[int]]:
    """Map of changed .swift files -> line numbers of added lines."""
    diff = run_git(
        "diff", "--unified=0", "--diff-filter=AMR", f"{base}..HEAD", "--", "*.swift"
    )
    files: dict[str, list[int]] = {}
    current: str | None = None
    new_line = 0
    for line in diff.splitlines():
        if line.startswith("+++"):
            current = line[len("+++ b/"):]
        elif line.startswith("@@"):
            match = HUNK_RE.match(line)
            new_line = int(match.group(1)) if match else 0
        elif line.startswith("+") and not line.startswith("+++"):
            if current:
                files.setdefault(current, []).append(new_line)
            new_line += 1
        elif not line.startswith("-"):
            new_line += 1
    return files


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", default="origin/main", help="diff base ref")
    args = parser.parse_args()

    base = resolve_base(args.base)
    if not base:
        print("No diff base resolvable; skipping hardcoded-string check.")
        return 0

    violations = []
    for rel, lines in sorted(added_lines(base).items()):
        if rel == GENERATED_STRINGS:
            continue
        path = ROOT / rel
        if not path.exists():
            continue
        skipped = debug_lines(path)
        source = path.read_text().splitlines()
        for number in lines:
            if number in skipped or number > len(source):
                continue
            text = source[number - 1]
            for match in CALL_RE.finditer(text):
                if not is_exempt_literal(match.group(2)):
                    violations.append(
                        f"{rel}:{number}: hardcoded string in {match.group(1)}(\"{match.group(2)}\")"
                    )
            for match in BYPASS_RE.finditer(text):
                violations.append(
                    f"{rel}:{number}: String(localized:) bypasses Strings.swift"
                )

    if violations:
        print("Hardcoded strings (see AGENTS.md 'Localization'): run scripts/generate-xcstrings.py or use Strings.*")
        for violation in violations:
            print(f"  {violation}")
        return 1
    print(f"Hardcoded-string check passed (base {base[:8]}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
