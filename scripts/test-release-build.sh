#!/usr/bin/env bash
# Clean Release build for the Next app target (no tests).
set -euo pipefail
source "$(dirname "$0")/_common.sh"
echo "== release build =="
time xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -configuration Release \
  clean build \
  $PARALLEL
