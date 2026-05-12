#!/usr/bin/env python3
"""
Scans Swift source files for raw string literals in UI contexts,
adds missing ones to Localizable.xcstrings, replaces them with Strings.xxx accessors,
then regenerates Strings.swift.

Usage:
    python3 scripts/extract-strings.py

Supports:
    Text("...")
    Button("...", ...)
    .alert("...", ...)
    navigationTitle("...")
    Label("...", systemImage: ...)

Skipped:
    - Strings with interpolation \\(...)
    - Empty strings, single chars, pure emojis, pure symbols
    - Strings already using Strings.xxx
    - Strings already present in Localizable.xcstrings (by value)
"""

import json
import os
import re
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SCRIPT_DIR)

XCSTRINGS = os.path.join(ROOT, "Packages/DesignSystem/Sources/Resources/Localizable.xcstrings")
GENERATE_SCRIPT = os.path.join(ROOT, "scripts/generate-strings.py")
SCAN_DIRS = [
    os.path.join(ROOT, "SnoreGuard"),
    os.path.join(ROOT, "Packages"),
]

# Patterns that indicate a localizable UI string.
# Each tuple: (regex, group_index_for_literal, replacement_func)
# replacement_func receives the full match and the property name, returns the new text.
def replace_text(m, prop):
    return m.group(0).replace(m.group(1), f"Strings.{prop}")

def replace_button(m, prop):
    # m.group(1) is the literal including leading space if any
    return m.group(0).replace(m.group(1), f"Strings.{prop}")

def replace_alert(m, prop):
    return m.group(0).replace(m.group(1), f"Strings.{prop}")

def replace_nav_title(m, prop):
    return m.group(0).replace(m.group(1), f"Strings.{prop}")

def replace_label(m, prop):
    return m.group(0).replace(m.group(1), f"Strings.{prop}")

UI_PATTERNS = [
    # Text("hello")
    (re.compile(r'Text\((\s*"(?:[^"\\]|\\.)*")\s*\)'), replace_text),
    # Button("hello", ... — the comma/paren after the literal stays outside the match
    (re.compile(r'Button\((\s*"(?:[^"\\]|\\.)*")\s*(?=[,)])'), replace_button),
    # .alert("hello", ...
    (re.compile(r'\.alert\((\s*"(?:[^"\\]|\\.)*")\s*(?=,)'), replace_alert),
    # navigationTitle("hello")
    (re.compile(r'navigationTitle\((\s*"(?:[^"\\]|\\.)*")\s*\)'), replace_nav_title),
    # Label("hello", systemImage:
    (re.compile(r'Label\((\s*"(?:[^"\\]|\\.)*")\s*(?=,\s*systemImage:)'), replace_label),
]

# Skip patterns
SKIP_INTERPOLATION_RE = re.compile(r'\\\(')  # Contains \( interpolation
SKIP_URL_RE = re.compile(r'^(https?://|mailto:|tel:)')
SKIP_SYMBOL_RE = re.compile(r'^[\s\-\+−–—•·…/\\|=_©®™°❤️⭐🌙😴🎧⏱📊🔔📈🔊🌙✅⚠️]+$')  # Pure symbols/emojis


def extract_swift_string(literal: str) -> str:
    """Parse a Swift string literal (e.g. \"hello\\nworld\") into its value."""
    s = literal.strip()
    if len(s) >= 2 and s[0] == '"' and s[-1] == '"':
        s = s[1:-1]
    s = s.replace('\\"', '"')
    s = s.replace('\\n', '\n')
    s = s.replace('\\\\', '\\')
    return s


def should_localize(value: str) -> bool:
    if not value or not value.strip():
        return False
    if SKIP_INTERPOLATION_RE.search(value):
        return False
    if SKIP_URL_RE.match(value):
        return False
    # Pure symbols / emojis
    if SKIP_SYMBOL_RE.match(value):
        return False
    # Single alphanumeric char
    stripped = value.strip()
    if len(stripped) <= 1 and stripped.isalnum():
        return False
    # Looks like a code identifier (camelCase, no spaces or punctuation)
    if re.match(r'^[a-z][a-zA-Z0-9]*$', stripped):
        return False
    return True


def key_for_value(value: str) -> str:
    return value


def load_xcstrings(path: str) -> dict:
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"sourceLanguage": "en", "strings": {}}


def save_xcstrings(path: str, catalog: dict):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)
        f.write("\n")


def find_existing_key_by_value(catalog: dict, value: str) -> str | None:
    for key, entry in catalog.get("strings", {}).items():
        loc = entry.get("localizations", {})
        en = loc.get("en", {})
        unit = en.get("stringUnit", {})
        if unit.get("value") == value:
            return key
    return None


def add_entry(catalog: dict, key: str, value: str) -> bool:
    strings = catalog.setdefault("strings", {})
    if key in strings:
        return False
    strings[key] = {
        "extractionState": "manual",
        "localizations": {
            "en": {
                "stringUnit": {
                    "state": "translated",
                    "value": value
                }
            }
        }
    }
    return True


def find_swift_files(dirs: list[str]) -> list[str]:
    files = []
    for d in dirs:
        for root, _, names in os.walk(d):
            for name in names:
                if name.endswith(".swift"):
                    files.append(os.path.join(root, name))
    return sorted(files)


def scan_file(filepath: str) -> list:
    """Return list of (match, value, replacement_func) for localizable strings."""
    results = []
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    for pattern, replacer in UI_PATTERNS:
        for match in pattern.finditer(content):
            literal = match.group(1).strip()
            value = extract_swift_string(literal)

            if not should_localize(value):
                continue

            # Skip if already using Strings.xxx in the same statement/context
            start = max(0, match.start() - 30)
            context = content[start:match.start()]
            if 'Strings.' in context:
                continue

            results.append((match, value, replacer))

    return results


def main():
    catalog = load_xcstrings(XCSTRINGS)
    files = find_swift_files(SCAN_DIRS)

    values_to_add = {}
    file_findings = {}

    for filepath in files:
        if "Strings.swift" in filepath:
            continue

        findings = scan_file(filepath)
        if not findings:
            continue

        file_findings[filepath] = findings
        for match, value, _ in findings:
            existing_key = find_existing_key_by_value(catalog, value)
            if existing_key:
                continue
            key = key_for_value(value)
            if value not in values_to_add:
                values_to_add[value] = key

    if not values_to_add and not file_findings:
        print("No new localizable strings found.")
        subprocess.run([sys.executable, GENERATE_SCRIPT], check=False)
        return

    added_count = 0
    for value, key in values_to_add.items():
        if add_entry(catalog, key, value):
            added_count += 1
            print(f"  + [{key}]")

    if added_count > 0:
        save_xcstrings(XCSTRINGS, catalog)
        print(f"\nAdded {added_count} new string(s) to Localizable.xcstrings.")

    # Regenerate Strings.swift to get property names
    subprocess.run([sys.executable, GENERATE_SCRIPT], check=False)

    # Build key -> property_name map from generated Strings.swift
    key_to_prop = {}
    strings_swift = os.path.join(ROOT, "Packages/DesignSystem/Sources/Strings.swift")
    with open(strings_swift, "r", encoding="utf-8") as f:
        for line in f:
            m = re.search(r'public static var (\w+): String \{ String\(localized: "([^"]+)"', line)
            if m:
                prop_name, key = m.group(1), m.group(2)
                key_to_prop[key] = prop_name

    modified_files = 0
    for filepath, findings in file_findings.items():
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        new_content = content
        for match, value, replacer in sorted(findings, key=lambda x: x[0].start(), reverse=True):
            existing_key = find_existing_key_by_value(catalog, value)
            key = existing_key if existing_key else key_for_value(value)
            prop = key_to_prop.get(key)
            if not prop:
                print(f"  ! Warning: no property for key '{key}', skipping {filepath}")
                continue

            old_text = match.group(0)
            new_text = replacer(match, prop)
            start = match.start()
            end = match.end()
            new_content = new_content[:start] + new_text + new_content[end:]

        if new_content != content:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(new_content)
            modified_files += 1
            rel = os.path.relpath(filepath, ROOT)
            print(f"  → {rel}")

    if modified_files > 0:
        print(f"\nLocalized {modified_files} file(s).")
    else:
        print("\nNo source files needed updating.")


if __name__ == "__main__":
    main()
