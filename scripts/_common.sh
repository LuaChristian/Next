#!/usr/bin/env bash
# Shared xcodebuild defaults for Next.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
DESTINATION="${DESTINATION:-platform=iOS Simulator,id=E2C7FDAA-F2E0-40CD-A322-A603ED048828}"
PROJECT="${PROJECT:-Next.xcodeproj}"
SCHEME="${SCHEME:-Next}"
PARALLEL="${PARALLEL:--parallel-testing-enabled NO}"
