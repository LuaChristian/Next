# V3-M8 — Botanical Collections & Plant Selection

**Status:** Ready for PM review (uncommitted)  
**Date:** 2026-10-21  
**Device:** iPhone 16 / iPhone 16e Simulator

## 1. Implementation summary

Users can choose a botanical species for each goal. The catalog is centralized and extensible; Garden / Goal Detail / growth math are unchanged. Species selection is cosmetic only.

**Catalog:** Fern · Lavender · Rosemary · Flower (flowering) — five growth stages each.

**Default:** Fern when creating a goal (and for onboarding).

**Edit:** Species can change at any time; focus sessions, tasks, and stage are preserved.

## 2. Persistence / migration

| Approach | Detail |
| --- | --- |
| Storage | Reuses existing `Goal.plantVariantRaw` (no new SwiftData property) |
| New values | `fern`, `lavender`, `rosemary`, `flowering` |
| Legacy values | `broadLeaf` / `narrowLeaf` / `branching` / `roundedLeaf` → resolve to **fern** via `BotanicalSpecies.resolved(stored:)` |
| Unknown | Falls back to fern |
| Migration | Non-destructive; existing rows keep stored strings and render as fern until edited |

`Goal.botanicalSpecies` is the user-facing API. `Goal.plantVariant` still exposes a Canvas silhouette for fallback drawing.

## 3. Artwork architecture

Resolution order preserved and extended:

1. `plant-{species}-{stage}` asset  
2. Legacy `plant-{silhouette}-{stage}` asset  
3. Pixel catalog (`PixelPlantCatalog` / placeholders)  
4. Canvas silhouette fallback  

Separated: **species identity** · **growth stage** · **artwork source** · **renderer**.

Adding a species = new `BotanicalSpecies` case + grid (or assets). No GardenView redesign.

## 4. Files changed

| File | Role |
| --- | --- |
| `Next/BotanicalSpecies.swift` | **New** catalog + Goal bridge |
| `Next/BotanicalPlaceholderArt.swift` | **New** lavender / rosemary / flowering placeholders |
| `Next/BotanicalSpeciesPicker.swift` | **New** create/edit selection UI |
| `Next/PixelPlantArt.swift` | Species alias + palette accents + presentation |
| `Next/PlantArtwork.swift` | Species-first resolve |
| `Next/PlantView.swift` | Species-first rendering |
| `Next/Goal.swift` | Init + botanicalSpecies / plantVariant compat |
| `Next/PlantGoalView.swift` | Species picker (default fern) |
| `Next/EditGoalView.swift` | Species picker |
| `Next/PlanningStore.swift` | Optional species update |
| `Next/GardenView.swift` / `GoalDetailView.swift` | Render `botanicalSpecies` |
| `Next/OnboardingState.swift` | Default fern |
| `Next/Persistence.swift` | Seeds use varied species |
| `Docs/Plant-Artwork.md` | Docs update |
| `NextTests` / `NextUITests` | Coverage + screenshots |
| `Review/V3-M8-Botanical-Collections/` | REPORT + shots |

## 5. Targeted test results

**Unit — PASS** (`BotanicalSpeciesTests`, `PixelPlantArtTests`, `PlantArtworkResolutionTests`, `GardenGrowthTests`)

Notable cases:
- newGoalDefaultsToFern  
- unknownStoredSpeciesFallsBackToFern  
- selectionSurvivesRelaunchViaPersistedRaw  
- changingSpeciesPreservesFocusProgress  
- updateGoalSpeciesDoesNotDuplicateSessions  
- everyCatalogSpeciesHasFiveDistinctStages  
- growthThresholdsUnchangedByPixelArt  
- legacy variants → fern pixel  

**UI — PASS**
- `testBotanicalCollectionsVisualReview` (iPhone 16)  
- `testBotanicalCollectionsSmallScreenReview` (iPhone 16e → shot 07)

## 6. Screenshots

`Review/V3-M8-Botanical-Collections/`

1. Plant selection during goal creation  
2. Plant selection during goal editing  
3. Garden showing different species  
4. Goal Detail with a selected species  
5. Light-mode Garden  
6. Dark-mode Garden  
7. Small-screen layout  
8. Large Dynamic Type layout  

## 7. Remaining limitations / risks

- Lavender / rosemary / flowering art is intentionally simple placeholder pixel work.  
- Legacy silhouette `plantVariantRaw` values remain until a goal is saved with a catalog species.  
- Asset catalog for species is optional; pixels ship by default.

## Not committed / not pushed
