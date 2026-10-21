//
//  PlantArtwork.swift
//  Next
//
//  Lightweight resolver: PlantVariant + GardenGrowthStage -> plant artwork.
//  Asset-catalog images win when present; Canvas/Path drawings remain the fallback.
//  Growth, FocusSession persistence, and Goal identity never depend on this file.
//
//  ── Replacing botanical artwork ─────────────────────────────────────────────
//
//  1. Export each illustration as a transparent-background PNG (or PDF vector).
//  2. In Assets.xcassets, create an Image Set named exactly:
//
//         plant-{variant}-{stage}
//
//     Variants (Goal.plantVariantRaw / PlantVariant.rawValue):
//         broadLeaf | narrowLeaf | branching | roundedLeaf
//
//     Stages (spoken name, lowercase):
//         beginning | establishing | developing | flourishing | mature
//
//     Full set of 20 names:
//         plant-broadLeaf-beginning
//         plant-broadLeaf-establishing
//         plant-broadLeaf-developing
//         plant-broadLeaf-flourishing
//         plant-broadLeaf-mature
//         plant-narrowLeaf-beginning
//         plant-narrowLeaf-establishing
//         plant-narrowLeaf-developing
//         plant-narrowLeaf-flourishing
//         plant-narrowLeaf-mature
//         plant-branching-beginning
//         plant-branching-establishing
//         plant-branching-developing
//         plant-branching-flourishing
//         plant-branching-mature
//         plant-roundedLeaf-beginning
//         plant-roundedLeaf-establishing
//         plant-roundedLeaf-developing
//         plant-roundedLeaf-flourishing
//         plant-roundedLeaf-mature
//
//  3. Prefer a portrait aspect near 3:4 (matches Garden / Goal Detail frames).
//     PlantView uses aspect-fit; extra margins are fine.
//  4. Keep the background fully transparent. Do not bake a cream canvas into
//     the asset — Garden and Goal Detail supply the canvas color.
//  5. For dark mode later: add Dark Appearance variants in the same Image Set.
//     Do not rely on template tinting; full-color artwork is drawn as-is.
//  6. Drop images into the asset catalog. No code change is required when the
//     name matches. Missing assets continue to use the Canvas fallback.
//  7. To force Canvas again, remove or rename the Image Set.
//
//  Single switch point: PlantArtwork.resolve / PlantView.body.
//

import SwiftUI
import UIKit

enum PlantArtwork {
    /// Resolved source for one variant × stage pair.
    enum Source: Equatable {
        /// Named asset-catalog image. Drawn without template tinting.
        case asset(String)
        /// Programmatic cozy pixel-art species (V3-M7+).
        case pixel(PixelPlantSpecies)
        /// Existing Canvas/Path botanical illustration (retained as fallback).
        case canvas
    }

    /// Test seam. When non-nil, used instead of `UIImage(named:)`.
    static var assetAvailability: ((String) -> Bool)?

    /// Deterministic asset-catalog name for a variant × stage.
    static func assetName(variant: PlantVariant, stage: GardenGrowthStage) -> String {
        "plant-\(variant.rawValue)-\(stage.artworkToken)"
    }

    /// Deterministic key used by tests and accessibility identifiers.
    static func signature(variant: PlantVariant, stage: GardenGrowthStage) -> String {
        "\(variant.rawValue)-\(stage.rawValue)"
    }

    /// Maps identity + growth to artwork.
    /// Order: catalog asset → pixel species (when mapped) → Canvas botanical.
    static func resolve(variant: PlantVariant, stage: GardenGrowthStage) -> Source {
        let name = assetName(variant: variant, stage: stage)
        if hasAsset(named: name) {
            return .asset(name)
        }
        if let species = PixelPlantPresentation.species(for: variant) {
            return .pixel(species)
        }
        return .canvas
    }

    static func resetTestOverrides() {
        assetAvailability = nil
        #if DEBUG
        PixelPlantPresentation.resetTestOverrides()
        #endif
    }

    private static func hasAsset(named name: String) -> Bool {
        if let assetAvailability {
            return assetAvailability(name)
        }
        return UIImage(named: name) != nil
    }
}

extension GardenGrowthStage {
    /// Stable token used in asset-catalog names (spoken name, lowercase).
    var artworkToken: String {
        switch self {
        case .seedling: "beginning"
        case .sprout: "establishing"
        case .young: "developing"
        case .growing: "flourishing"
        case .mature: "mature"
        }
    }
}
