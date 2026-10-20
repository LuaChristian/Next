#!/usr/bin/env bash
# Full NextUITests suite (serial). Does NOT rewrite Review/ PNGs.
set -euo pipefail
source "$(dirname "$0")/_common.sh"
echo "== ui full (no Review/ rewrite) =="
time xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -only-testing:NextUITests \
  $PARALLEL
