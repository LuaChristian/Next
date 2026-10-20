# Plant artwork replacement

Next maps each **plant variant × growth stage** to artwork through `PlantArtwork`.
Garden growth, FocusSession persistence, and Goal identity are unchanged.

Until custom images are supplied, the app draws the built-in Canvas plants.

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

- Do **not** bake the cream canvas into the file; keep alpha transparent.
- Do **not** expect automatic tinting; supply light/dark artwork as needed.
- Do **not** change `Goal.plantVariantRaw`, growth thresholds, or FocusSession logic.
- Accessibility labels stay on parent Goal rows / comparison cells, not on the plant image.

## Code switch point

`PlantArtwork.resolve` → `PlantView`. That is the only place that chooses asset vs Canvas.
