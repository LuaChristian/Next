# Plant artwork replacement

Next maps each **plant variant × growth stage** to artwork through `PlantArtwork`.
Garden growth, FocusSession persistence, and Goal identity are unchanged.

**Resolution order (V3-M7):**

1. Asset-catalog image `plant-{variant}-{stage}` when present  
2. Pixel-art species via `PixelPlantPresentation.species(for:)` (production maps every variant to the reference **fern**)  
3. Built-in Canvas botanical fallback (`PlantDrawing`) when mapping returns `nil`  

Canvas botanical code remains for fallback. Fern stage showcase / UITest fixtures are DEBUG-only.

## Naming

Add Image Sets to `Assets.xcassets` with these exact names:

```
plant-{variant}-{stage}
```

| Variant (`plantVariantRaw`) | Stages |
|---|---|
| `broadLeaf` | `beginning` · `establishing` · `developing` · `flourishing` · `mature` |
| `narrowLeaf` | same |
| `branching` | same |
| `roundedLeaf` | same |

Example: Broad Leaf at Beginning → `plant-broadLeaf-beginning`.

There are **20** images in a full set (4 variants × 5 stages).

## How to replace

1. Export transparent-background PNG or PDF (portrait ~3:4 is ideal).
2. Create matching Image Sets in the asset catalog (names above).
3. Optionally add a Dark Appearance in the same Image Set for dark mode.
4. Build and run — no Swift changes if names match.
5. Omit or rename an Image Set to fall back to Canvas for that cell only.

## Rules

- Do **not** bake the cream or charcoal canvas into the file; keep alpha transparent.
- Do **not** expect automatic tinting of full-color artwork; Next draws assets as authored.
- Do **not** change `Goal.plantVariantRaw`, growth thresholds, or FocusSession logic.
- Accessibility labels stay on parent Goal rows / comparison cells, not on the plant image.

## Light and Dark

Canvas fallback plants use `NextTheme.botanicalInk`, which adapts automatically
(Calm Garden ink in Light, softer botanical green in Dark).

For custom images:

1. Prefer transparent PNGs/PDFs that read on both warm ivory (`#FAF7F0`) and
   warm charcoal (`#171F1B`).
2. When a single asset cannot work in both themes, add a **Dark Appearance**
   variant in the same Image Set (Xcode asset catalog). Keep the same name —
   no second naming scheme.
3. Avoid bright rectangular backgrounds, neon greens, or lavender accents.
4. Do not supply 40 placeholder files; add only authored artwork.
5. Full-color illustrations are never template-tinted.

## Code switch point

`PlantArtwork.resolve` → `PlantView`. That is the only place that chooses asset vs Canvas.
