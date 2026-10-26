//
//  BotanicalSpecies.swift
//  Next
//
//  User-selectable botanical catalog (V3-M8).
//  Stored in Goal.plantVariantRaw for compatibility — no new SwiftData property.
//  Legacy silhouette IDs (broadLeaf, …) resolve to .fern.
//

import Foundation

/// Central botanical catalog. Add cases + artwork without touching Garden layout.
enum BotanicalSpecies: String, CaseIterable, Identifiable, Codable, Equatable {
    case fern
    case lavender
    case rosemary
    case flowering

    var id: Self { self }

    var displayName: String {
        switch self {
        case .fern: "Fern"
        case .lavender: "Lavender"
        case .rosemary: "Rosemary"
        case .flowering: "Flower"
        }
    }

    /// Default for new goals and unknown / legacy stored values.
    static let `default`: BotanicalSpecies = .fern

    /// Resolve a persisted `Goal.plantVariantRaw` value safely.
    static func resolved(stored raw: String) -> BotanicalSpecies {
        if let species = BotanicalSpecies(rawValue: raw) {
            return species
        }
        // Legacy V2–V3-M7 silhouette identifiers → fern presentation.
        switch raw {
        case PlantVariant.broadLeaf.rawValue,
             PlantVariant.narrowLeaf.rawValue,
             PlantVariant.branching.rawValue,
             PlantVariant.roundedLeaf.rawValue:
            return .fern
        default:
            return .default
        }
    }

    /// Canvas botanical silhouette used when pixel presentation is unavailable.
    var canvasSilhouette: PlantVariant {
        switch self {
        case .fern: .broadLeaf
        case .lavender: .roundedLeaf
        case .rosemary: .narrowLeaf
        case .flowering: .branching
        }
    }
}

extension Goal {
    /// User-facing botanical species. Writes into `plantVariantRaw`.
    var botanicalSpecies: BotanicalSpecies {
        get { BotanicalSpecies.resolved(stored: plantVariantRaw) }
        set { plantVariantRaw = newValue.rawValue }
    }
}
