#!/usr/bin/env python3
"""Regenerates Strings.swift.

The string catalog and its generator live in the SleepGuardShared repo
(Sources/SleepStrings), shared with the other SleepGuard apps. This script
runs that repo's generator against a local checkout:

  - $SLEEPGUARD_SHARED, when set, or
  - ../SleepGuardShared next to this repo.

Without a local checkout there is nothing to generate here (the package is
then a pinned dependency), so it exits successfully.
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
        print(f"warning: no SleepGuardShared checkout at {SHARED}; skipping strings generation")
        return 0
    return subprocess.run([sys.executable, script, *sys.argv[1:]]).returncode


if __name__ == "__main__":
    sys.exit(main())
