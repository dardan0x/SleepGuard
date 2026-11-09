#!/bin/sh
# Runs every package's tests on the iOS Simulator.
#
# The app scheme can't run package tests (the packages are linked as package
# dependencies, so Xcode doesn't expose their test targets), and `swift test`
# builds for macOS, where iOS-only APIs fail. So we run `xcodebuild test`
# with each package's own scheme, sharing one derived-data folder.
#
# Usage: sh scripts/run-tests.sh [Package ...]   (default: every package with tests)
# Env:   DESTINATION  (default: the pinned iPhone 17 Pro, iOS 26.2 simulator)
#        DERIVED_DATA (default: .build/test-derived-data)
set -u
cd "$(dirname "$0")/.."
ROOT=$(pwd)

DESTINATION=${DESTINATION:-"platform=iOS Simulator,id=BD630AD5-5A05-4663-8F1B-A17283EBCBF5"}
DERIVED_DATA=${DERIVED_DATA:-"$ROOT/.build/test-derived-data"}
LOG_DIR="$DERIVED_DATA/logs"
mkdir -p "$LOG_DIR"

if [ $# -gt 0 ]; then
  PACKAGES="$*"
else
  PACKAGES=$(grep -l 'testTarget' Packages/*/Package.swift | cut -d/ -f2)
fi

FAILED=""
for pkg in $PACKAGES; do
  log="$LOG_DIR/$pkg.log"
  printf '▶ %s … ' "$pkg"
  (cd "Packages/$pkg" && xcodebuild test -scheme "$pkg" -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA" >"$log" 2>&1)
  if [ $? -eq 0 ]; then
    grep -m1 -E 'Test run with .* passed' "$log" || echo "passed"
  else
    echo "FAILED (log: $log)"
    grep -E 'error:|✘' "$log" | sort -u | head -20
    FAILED="$FAILED $pkg"
  fi
done

if [ -n "$FAILED" ]; then
  echo "Failed packages:$FAILED"
  exit 1
fi
echo "All package tests passed."
