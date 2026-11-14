#!/bin/sh
# Re-records the detection replay goldens (F22-T9). Run this ONLY when a change
# is meant to alter detection, then review the diff it prints and explain each
# changed line in the PR. A normal test run never writes goldens.
#
# The detection state machine, its replay fixtures and goldens live in the
# SleepGuardShared repo (SleepCore). This runs that repo's script against a
# local checkout: $SLEEPGUARD_SHARED, or ../SleepGuardShared next to this repo.
#
# Usage: sh scripts/record-replay-goldens.sh
set -eu
cd "$(dirname "$0")/.."

SHARED=${SLEEPGUARD_SHARED:-"$(pwd)/../SleepGuardShared"}
if [ ! -f "$SHARED/scripts/record-replay-goldens.sh" ]; then
  echo "error: no SleepGuardShared checkout at $SHARED; goldens are recorded there" >&2
  exit 1
fi
exec sh "$SHARED/scripts/record-replay-goldens.sh"
