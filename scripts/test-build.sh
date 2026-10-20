#!/usr/bin/env bash
# Build app for the preferred simulator. No tests.
set -euo pipefail
source "$(dirname "$0")/_common.sh"
echo "== build =="
time xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  $PARALLEL
