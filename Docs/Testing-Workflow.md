# Testing workflow

Goal: keep iteration under a few minutes; reserve the full UI suite for PM review
and final milestone / release gates.

Simulator: prefer the already-booted `iPhone 16 Pro` (id `E2C7FDAA-F2E0-40CD-A322-A603ED048828`).
Always use `-parallel-testing-enabled NO` — simulator clones hang on this project.

## Policy

| Phase | What to run |
|---|---|
| Normal implementation | Build + targeted unit/UI tests for changed code only |
| Meaningful feature complete | Targeted unit + targeted UI only if interaction changed |
| Before PM review | Full unit suite + relevant UI regression (report skips) |
| Before final milestone approval | Full regression once, unless a prior full run still covers later changes |
| Before release | Complete unit + UI regression |

Never claim skipped tests passed.

## Commands

From repo root (or via `scripts/`):

```bash
# Build only
scripts/test-build.sh

# Full unit suite (~1 min warm)
scripts/test-unit.sh

# Targeted UI (pass one or more -only-testing selectors)
scripts/test-ui.sh NextUITests/NextUITests/testLargeDynamicTypeGardenDoesNotCoverGoals

# Full UI regression (~15 min serial) — no Review/ PNG rewrite
scripts/test-ui-full.sh

# PM visual capture: write Review/ PNGs for a specific visual test
UITEST_WRITE_REVIEW_SHOTS=1 scripts/test-ui.sh NextUITests/NextUITests/testGardenEvolutionVisualReview
```

## Screenshot policy

Visual review tests always attach `XCTAttachment`s to the result bundle.

Disk writes under `Review/` happen **only** when `UITEST_WRITE_REVIEW_SHOTS=1`.
Full regression runs must not rewrite completed-milestone PNGs.

## Report fields (every milestone)

- Build duration
- Targeted test duration
- Full unit test duration
- Full UI test duration (if executed)
- Total testing duration
- Passed / failed / skipped
- Bottlenecks identified
