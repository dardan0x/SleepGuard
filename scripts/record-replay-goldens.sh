#!/bin/sh
# Re-records the detection replay goldens (F22-T9). Run this ONLY when a change
# is meant to alter detection, then review the diff it prints and explain each
# changed line in the PR. A normal test run never writes goldens.
#
# Usage: sh scripts/record-replay-goldens.sh
set -eu
cd "$(dirname "$0")/.."

# xcodebuild forwards TEST_RUNNER_-prefixed variables to the test process.
TEST_RUNNER_RECORD_REPLAY_GOLDENS=1 sh scripts/run-tests.sh AudioEngine

GOLDENS=Packages/AudioEngine/Tests/Fixtures/Replay
echo
if git diff --quiet -- "$GOLDENS" && [ -z "$(git ls-files --others --exclude-standard -- "$GOLDENS")" ]; then
  echo "Goldens unchanged."
else
  echo "Goldens changed. Review before committing:"
  git status --short -- "$GOLDENS"
  git --no-pager diff --stat -- "$GOLDENS"
fi
