//
//  PlantArtwork.swift
//  Next
//
//  Resolver: botanical species + growth stage → artwork.
//  Order: asset catalog → pixel catalog → Canvas silhouette fallback.
//  Growth math and Goal relationships never depend on this file.
//
//  Asset names (optional replacements):
//      plant-{species}-{stage}
//      species: fern | lavender | rosemary | flowering
//      stage:   beginning | establishing | developing | flourishing | mature
//

import SwiftUI
import UIKit

enum PlantArtwork {
    enum Source: Equatable {
        case asset(String)
        case pixel(BotanicalSpecies)
        case canvas
    }

    static var assetAvailability: ((String) -> Bool)?

    static func assetName(species: BotanicalSpecies, stage: GardenGrowthStage) -> String {
        "plant-\(species.rawValue)-\(stage.artworkToken)"
    }

    /// Legacy silhouette asset names (still recognized if present).
    static func assetName(variant: PlantVariant, stage: GardenGrowthStage) -> String {
        "plant-\(variant.rawValue)-\(stage.artworkToken)"
    }

    static func signature(species: BotanicalSpecies, stage: GardenGrowthStage) -> String {
        "\(species.rawValue)-\(stage.rawValue)"
    }

    static func signature(variant: PlantVariant, stage: GardenGrowthStage) -> String {
        signature(species: BotanicalSpecies.resolved(stored: variant.rawValue), stage: stage)
    }

    /// Primary resolve path for Garden / Goal Detail.
    static func resolve(species: BotanicalSpecies, stage: GardenGrowthStage) -> Source {
        let speciesName = assetName(species: species, stage: stage)
        if hasAsset(named: speciesName) {
            return .asset(speciesName)
        }
        // Legacy silhouette assets (pre-M8) still win when present.
        let legacyName = assetName(variant: species.canvasSilhouette, stage: stage)
        if hasAsset(named: legacyName) {
            return .asset(legacyName)
        }
        if let pixel = PixelPlantPresentation.pixelSpecies(for: species) {
            return .pixel(pixel)
        }
        return .canvas
    }

    /// Compatibility for call sites still holding a PlantVariant.
    /// Legacy silhouette assets are checked before botanical remapping.
    static func resolve(variant: PlantVariant, stage: GardenGrowthStage) -> Source {
        let legacyName = assetName(variant: variant, stage: stage)
        if hasAsset(named: legacyName) {
            return .asset(legacyName)
        }
        return resolve(species: BotanicalSpecies.resolved(stored: variant.rawValue), stage: stage)
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
