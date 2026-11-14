#!/usr/bin/env python3
"""Merges Strings.txt entries into Localizable.xcstrings, then regenerates Strings.swift.

The string catalog, Strings.txt and the generator live in the SleepGuardShared
repo (Sources/SleepStrings/Resources), shared with the other SleepGuard apps.
This script runs that repo's generator against a local checkout:

  - $SLEEPGUARD_SHARED, when set, or
  - ../SleepGuardShared next to this repo.

Add entries to <SleepGuardShared>/Sources/SleepStrings/Resources/Strings.txt
(`key`, `key = value` or `"key" = "value"`), then run this script.
"""
import os
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SCRIPT_DIR)
SHARED = os.environ.get("SLEEPGUARD_SHARED") or os.path.join(os.path.dirname(ROOT), "SleepGuardShared")


def main():
    script = os.path.join(SHARED, "scripts", os.path.basename(__file__))
    if not os.path.exists(script):
        print(f"error: no SleepGuardShared checkout at {SHARED}; strings are edited there")
        return 1
    return subprocess.run([sys.executable, script, *sys.argv[1:]]).returncode


if __name__ == "__main__":
    sys.exit(main())
