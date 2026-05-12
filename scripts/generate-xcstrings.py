#!/usr/bin/env python3
"""
Merges plain-text string entries into Localizable.xcstrings.

Usage:
    1. Add entries to Packages/DesignSystem/Sources/Resources/Strings.txt
       Format: one of the following
         key
         key = value
         "key" = "value"

       If only key is provided, value defaults to the key itself.

    2. Run: python3 scripts/generate-xcstrings.py
    3. The script merges new entries into Localizable.xcstrings,
       then runs generate-strings.py to update Strings.swift.
"""

import json
import os
import re
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SCRIPT_DIR)

STRINGS_TXT = os.path.join(ROOT, "Packages/DesignSystem/Sources/Resources/Strings.txt")
XCSTRINGS = os.path.join(ROOT, "Packages/DesignSystem/Sources/Resources/Localizable.xcstrings")
GENERATE_SCRIPT = os.path.join(ROOT, "scripts/generate-strings.py")


def parse_strings_txt(path: str) -> dict[str, str]:
    """Parse simple key=value entries from Strings.txt."""
    if not os.path.exists(path):
        return {}

    entries = {}
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            # Skip comments and blank lines
            if not line.strip() or line.strip().startswith("#"):
                continue

            # Try "key" = "value" or key = value
            m = re.match(r'^\s*"([^"]+)"\s*=\s*"([^"]*)"\s*$', line)
            if m:
                entries[m.group(1)] = m.group(2)
                continue

            m = re.match(r'^\s*([^=]+?)\s*=\s*(.*?)\s*$', line)
            if m:
                key = m.group(1).strip()
                value = m.group(2).strip()
                # Remove surrounding quotes if present
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                entries[key] = value if value else key
                continue

            # Just a key on its own — value equals key
            key = line.strip()
            if key:
                entries[key] = key

    return entries


def load_xcstrings(path: str) -> dict:
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"sourceLanguage": "en", "strings": {}}


def save_xcstrings(path: str, catalog: dict):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)
        f.write("\n")


def merge_entry(catalog: dict, key: str, value: str):
    strings = catalog.setdefault("strings", {})
    if key in strings:
        return False  # Already exists

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


def main():
    entries = parse_strings_txt(STRINGS_TXT)
    if not entries:
        print("No entries found in Strings.txt. Nothing to do.")
        # Still run generate-strings to ensure Strings.swift is up-to-date
        subprocess.run([sys.executable, GENERATE_SCRIPT], check=False)
        return

    catalog = load_xcstrings(XCSTRINGS)
    added = 0

    for key, value in entries.items():
        if merge_entry(catalog, key, value):
            added += 1
            print(f"  + {key}")

    if added > 0:
        save_xcstrings(XCSTRINGS, catalog)
        print(f"\nAdded {added} new string(s) to Localizable.xcstrings.")
    else:
        print("All strings already present in Localizable.xcstrings.")

    # Always regenerate Strings.swift
    subprocess.run([sys.executable, GENERATE_SCRIPT], check=False)


if __name__ == "__main__":
    main()
