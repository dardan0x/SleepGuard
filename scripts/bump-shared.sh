#!/bin/sh
# Moves SleepGuard to a released version of SleepGuardShared.
#
# Release first, in ../SleepGuardShared: commit, push, then
#   git tag -a 0.2.0 -m "…" && git push origin 0.2.0
#
# Usage: sh scripts/bump-shared.sh 0.2.0
#
# What it does:
#   1. Checks the tag exists on GitHub.
#   2. Rewrites `exact: "<old>"` to `exact: "<new>"` in every package manifest
#      that depends on SleepGuardShared.
#   3. Re-resolves the project (updates its committed Package.resolved).
#   4. Copies the project's pins into the dev workspace and re-resolves it, so
#      both lockfiles agree on every other dependency.
set -eu
cd "$(dirname "$0")/.."

VERSION=${1:?usage: sh scripts/bump-shared.sh <version>}
URL=https://github.com/dardan0x/SleepGuardShared.git
PROJECT_RESOLVED=SleepGuard.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
WORKSPACE_RESOLVED=SleepGuard.xcworkspace/xcshareddata/swiftpm/Package.resolved

if ! git ls-remote --exit-code --tags "$URL" "refs/tags/$VERSION" >/dev/null; then
  echo "error: tag $VERSION not found on $URL; push the tag first" >&2
  exit 1
fi

MANIFESTS=$(grep -l "SleepGuardShared.git" Packages/*/Package.swift)
for manifest in $MANIFESTS; do
  sed -i '' -E "s#(SleepGuardShared\.git\", exact: \")[^\"]+#\1$VERSION#" "$manifest"
done
echo "Manifests now require SleepGuardShared $VERSION:"
grep -h "SleepGuardShared.git" $MANIFESTS | sort -u

xcodebuild -resolvePackageDependencies -project SleepGuard.xcodeproj -scheme SleepGuard >/dev/null
cp "$PROJECT_RESOLVED" "$WORKSPACE_RESOLVED"
xcodebuild -resolvePackageDependencies -workspace SleepGuard.xcworkspace -scheme SleepGuard >/dev/null

grep -A6 '"sleepguardshared"' "$PROJECT_RESOLVED" | grep '"version"'
echo "Done. Run sh scripts/run-tests.sh, build the app, then commit the manifests and both Package.resolved files."
