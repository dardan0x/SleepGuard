#!/bin/sh
# Point git at the versioned hooks directory. Run once per clone:
#   sh scripts/install-hooks.sh
set -e
cd "$(dirname "$0")/.."
git config core.hooksPath .githooks
echo "core.hooksPath = .githooks — pre-commit hook now auto-formats staged Swift files"
