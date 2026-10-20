#!/usr/bin/env bash
# Full NextTests unit suite (serial).
set -euo pipefail
source "$(dirname "$0")/_common.sh"
ONLY="${1:--only-testing:NextTests}"
echo "== unit: $ONLY =="
time xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  "$ONLY" \
  $PARALLEL
