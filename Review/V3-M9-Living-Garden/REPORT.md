# V3-M9 — Living Garden Experience

**Status:** Ready for PM review (uncommitted)  
**Date:** 2026-10-21  
**Devices:** iPhone 16 / iPhone 16e Simulator  
**Base:** `769bf9c` — V3-M8 botanical collections (confirmed committed before start)

## 1. Implementation summary

Garden is no longer a text-led goal list. It presents a botanical collection: larger plants lead each goal, with restrained growth context beneath. An editorial summary answers “how is my garden growing?” Empty state welcomes without guilt. Growth math, sessions, recommendation, and focus modes are unchanged.

## 2. Architectural decisions

| Decision | Rationale |
| --- | --- |
| Presentation-only milestone | No SwiftData schema changes; reuse Goal / FocusSession / GardenGrowth / PlantArtwork |
| `GardenCollectionSummary` | Pure metrics from existing goal→session relationships; multi-area goals count once |
| `GardenCollectionLayout` | Adaptive 1↔2 columns from content width + accessibility Dynamic Type |
| `GardenPlantCell` | Shared cell; artwork primary; stage + focused time as copy (no cards) |
| LazyVStack / LazyVGrid | Keeps collection smooth with many goals |
| Goal Detail stage label | Localized consistency (`MATURE`, etc.) without redesigning Detail |

Resolution order unchanged: asset → pixel → Canvas. Species selection remains cosmetic.

## 3. Files changed

| File | Role |
| --- | --- |
| `Next/GardenCollectionSummary.swift` | **New** — summary metrics + layout helpers |
| `Next/GardenPlantCell.swift` | **New** — collection cell |
| `Next/GardenView.swift` | Living Garden layout, summary, empty state |
| `Next/GoalDetailView.swift` | Spoken growth stage label |
| `NextTests/NextTests.swift` | `LivingGardenSummaryTests` |
| `NextUITests/NextUITests.swift` | Living Garden UI / visual review + empty-copy updates |
| `Review/V3-M9-Living-Garden/` | Screenshots + this REPORT |

## 4. Targeted test results

**Unit — PASS** (14 tests)

- `GardenGrowthTests` — thresholds unchanged  
- `GardenMetricsTests` — formatting unchanged  
- `LivingGardenSummaryTests`
  - editorialDurationFormatting  
  - goalsGrowingGrammar  
  - columnCountAdaptsToWidthAndDynamicType  
  - summaryDoesNotDoubleCountSessionsAcrossGoals  
  - multiAreaGoalAppearsOnceInCollectionMetrics  
  - gardenAndDetailShareGrowthFromSameSessions  

**UI — PASS**

- `testLivingGardenVisualReview` (iPhone 16) — shots 01–08, 10  
- `testLivingGardenSmallScreenReview` (iPhone 16e) — shot 09  
- `testLivingGardenOpensCorrectGoalAndPreservesPlantFlow`

## 5. Screenshots

| # | File |
| --- | --- |
| 01 | `01 Empty Garden.png` |
| 02 | `02 Garden with one goal.png` |
| 03 | `03 Garden with multiple goals.png` |
| 04 | `04 Garden showing different species.png` |
| 05 | `05 Garden showing different growth stages.png` |
| 06 | `06 Garden summary.png` |
| 07 | `07 Goal Detail from Garden.png` |
| 08 | `08 Dark-mode Garden.png` |
| 09 | `09 Small-screen Garden.png` |
| 10 | `10 Large Dynamic Type Garden.png` |

**Visual QA notes**

- Plants are clearly larger than V3-M8 list rows; pixel art stays crisp.  
- Summary is quiet editorial copy (“5 goals growing” / “17h 30m of focused time”).  
- Two-column grid on standard width; single column at accessibility Dynamic Type.  
- Empty state uses suggested welcoming copy + prominent Plant a Goal.  
- Light / dark / SE-class / large type all render within Next’s ivory / charcoal language.

## 6. Remaining limitations / risks

- Placeholder species artwork from M8 is unchanged (intentional).  
- On mid-size phones the lower grid rows sit under the pinned CTA until scroll — expected with a fixed Plant action.  
- Column threshold (≥320pt content width) favors two columns on iPhone 16 / 16e; SE-class widths stay single-column.  
- No animation / motion polish in this milestone.

**Do not commit or push until PM approval.**
