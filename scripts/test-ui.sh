#!/usr/bin/env bash
# Targeted UI tests. Pass one or more selectors after the script name.
# Example:
#   scripts/test-ui.sh NextUITests/NextUITests/testLargeDynamicTypeGardenDoesNotCoverGoals
# Write Review/ PNGs:
#   UITEST_WRITE_REVIEW_SHOTS=1 scripts/test-ui.sh NextUITests/NextUITests/testGardenEvolutionVisualReview
set -euo pipefail
source "$(dirname "$0")/_common.sh"
if [[ $# -lt 1 ]]; then
  echo "usage: $0 <OnlyTestingSelector> [more...]" >&2
  echo "example: $0 NextUITests/NextUITests/testGardenEvolutionVisualReview" >&2
  exit 2
fi
ARGS=()
for sel in "$@"; do
  ARGS+=("-only-testing:$sel")
done
echo "== ui targeted: $* =="
if [[ "${UITEST_WRITE_REVIEW_SHOTS:-}" == "1" ]]; then
  echo "(Review/ disk writes ENABLED)"
  export UITEST_WRITE_REVIEW_SHOTS=1
  time xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    "${ARGS[@]}" \
    $PARALLEL \
    -test-runner-env UITEST_WRITE_REVIEW_SHOTS=1
else
  echo "(Review/ disk writes off — XCTAttachments only)"
  time xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    "${ARGS[@]}" \
    $PARALLEL
fi
