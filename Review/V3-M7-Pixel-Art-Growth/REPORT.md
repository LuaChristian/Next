# V3-M7 — Pixel-Art Growth Foundation

**Status:** Ready for PM review (uncommitted)  
**Date:** 2026-10-21  
**Device:** iPhone 16 Simulator (iOS 18.x); small-screen note for shot 09

## Summary

Introduces a cozy **programmatic pixel-art** plant system and a five-stage **reference fern**, integrated into Garden / Goal Detail through the existing `PlantArtwork` → `PlantView` switch. Growth thresholds, Goal `plantVariant` identities, FocusSession accounting, and Canvas botanical code are preserved.

---

## 1. Existing Garden architecture audit

| Topic | Finding |
| --- | --- |
| **GardenView** | Lists goals with `PlantView(variant:stage:)` at 72×104 (48×68 a11y). |
| **Goal Detail** | Same `PlantView` at 108×148 (56×76 a11y). |
| **Renderer** | `PlantArtwork.resolve` → asset or Canvas `PlantDrawing` (pre-M7). |
| **Identities** | `PlantVariant`: broadLeaf, narrowLeaf, branching, roundedLeaf on `Goal.plantVariantRaw`. |
| **Growth** | `GardenGrowth.stage(for:)` from `Goal.totalFocusedDuration` (FocusSession sum). **Not stored.** |
| **Thresholds** | &lt;30 / 30–119 / 120–299 / 300–599 / ≥600 focused minutes. |
| **Assignment** | Auto least-used variant at create; edit does not change variant. |
| **Theme** | Canvas ivory/charcoal; plants use botanical greens (now pixel palette). |
| **A11y** | Plant artwork `accessibilityHidden`; row/header combine goal + spoken stage. |

Changing the renderer does **not** alter Goal data or historical progress.

---

## 2. Selected rendering approach

**Programmatic pixel grids** (`PixelGrid` + `PixelArtRenderer` + Canvas fills).

| Criterion | Why this approach |
| --- | --- |
| Visual quality | Integer nearest-neighbor scale → crisp edges |
| Maintainability | Artwork as data rows, separate from layout |
| New varieties (V3-M8) | Add `PixelPlantSpecies` case + grid file |
| Dark mode | Palette resolves per `ColorScheme` |
| Assets | No 20-image catalog required for fern |
| Fallback | Canvas botanical retained when pixel presentation is off |

Rejected for M7: external sprite packs (asset churn), third-party engines, emoji placeholders.

---

## 3. Reference fern design

- **Canvas:** 24×32 logical pixels, shared across stages  
- **Anchor:** Soil mound bottom-center (palette 1–2)  
- **Palette:** Soil browns + muted botanical greens (light/dark variants)  
- **Stages:** Seed → Sprout → Young → Flourishing → Mature (same organism growing)

---

## 4. Growth-stage mapping

Unchanged:

| Stage | Enum | Minutes focused |
| --- | --- | --- |
| 0 | `.seedling` | &lt; 30 |
| 1 | `.sprout` | 30–119 |
| 2 | `.young` | 120–299 |
| 3 | `.growing` | 300–599 |
| 4 | `.mature` | ≥ 600 |

`PixelPlantCatalog.grid(species:stage:)` consumes `GardenGrowthStage` only — does not recalculate progress.

---

## 5. Garden integration

- `PlantView` draws `.pixel(species)` when resolved.  
- Navigation, ordering, titles, areas, metrics, empty state, interactions unchanged.  
- No plant-selection UI, no new tab, no creation/edit flow changes.

---

## 6. Existing plant identity preservation

- `plantVariantRaw` values untouched.  
- Production mapping: `PixelPlantPresentation.species(for:)` returns `.fern` for every variant (approved V3-M7 visual).  
- Identities (`plantVariantRaw`) unchanged. Canvas botanical remains the nil-mapping fallback.  
- DEBUG-only: fern stage showcase (`UITEST_FERN_STAGES`) and test mapping override — not in Release paths.  
- No SwiftData migration.

---

## 7. Light / dark mode

Pixel palette has light and dark botanical/soil tones. App chrome still uses `NextTheme.canvas`. No gradients or glow.

---

## 8. Accessibility

- Plant pixels remain `accessibilityHidden`.  
- Goal rows / detail keep `progressAccessibilityLabel` + spoken stage.  
- Dynamic Type still shrinks plant frames; artwork uses integer scale (not font).  
- No growth animations (V4-M2). Reduce Motion unaffected.

---

## 9. Files changed

| File | Change |
| --- | --- |
| `Next/PixelPlantArt.swift` | **New** — species, grid, palette, renderer, presentation bridge |
| `Next/FernPixelArt.swift` | **New** — five fern stage grids |
| `Next/FernStageShowcaseView.swift` | **New** — DEBUG `UITEST_FERN_STAGES` |
| `Next/PlantArtwork.swift` | `.pixel` source; resolve order asset → pixel → canvas |
| `Next/PlantView.swift` | Render pixel path; asset interpolation `.none` |
| `Next/NextApp.swift` | DEBUG fern showcase route |
| `Docs/Plant-Artwork.md` | Document resolution order |
| `NextTests/NextTests.swift` | Resolution + `PixelPlantArtTests` |
| `NextUITests/NextUITests.swift` | `testPixelArtGrowthVisualReview` |
| `Review/V3-M7-Pixel-Art-Growth/` | REPORT + screenshots |

---

## 10. Targeted test results

**Unit (PASS):**

- `GardenGrowthTests` — thresholds unchanged  
- `PlantIdentityTests` — variants stable  
- `PlantArtworkResolutionTests` — asset / pixel / canvas order  
- `PixelPlantArtTests` — five distinct fern grids, identity preserved, canvas fallback, deterministic mapping  

**UI:**
- `testPixelArtGrowthVisualReview` — PASS (iPhone 16)
- `testPixelArtGrowthSmallScreenReview` — PASS (iPhone 16e → shot 09)

---

## 11. Screenshots

`Review/V3-M7-Pixel-Art-Growth/`

1. Fern Stage 0  
2. Fern Stage 1  
3. Fern Stage 2  
4. Fern Stage 3  
5. Fern Stage 4  
6. Garden with multiple goals  
7. Garden in Dark mode  
8. Goal detail with pixel-art fern  
9. Small-screen Garden  
10. Large Dynamic Type Garden  

---

## 12. Remaining limitations and risks

- All `PlantVariant`s share fern visuals until V3-M8 maps species / user choice.  
- Programmatic art is hand-authored; V3-M8 can add species without Garden redesign.  
- Shot 09 captured on iPhone 16e (compact width).  
- DEBUG test mapping override suites are serialized.

---

## 13. Proposed V3-M8 approach

1. Add `PixelPlantSpecies` cases (lavender, rosemary, …) with five-stage grids.  
2. Replace temporary `preferReferenceFern` with `species(for: PlantVariant)` or user-selected species stored on Goal (additive optional field).  
3. Keep `PlantArtwork.resolve` order; Canvas remains ultimate fallback.  
4. Add plant-selection UI without changing growth math.

## Not committed / not pushed
