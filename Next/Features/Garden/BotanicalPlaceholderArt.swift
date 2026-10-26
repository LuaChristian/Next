//
//  BotanicalPlaceholderArt.swift
//  Next
//
//  Simple placeholder pixel grids for catalog species beyond the reference fern.
//  Visual perfection is not required — distinct silhouettes for selection QA.
//  Shared 24×32 canvas and soil anchor with FernPixelArt.
//
//  Palette: 0 clear · 1–2 soil · 3 stem · 4–6 foliage · 7 tip · 8 lavender · 9 bloom
//

import Foundation

enum BotanicalPlaceholderArt {
    static func grid(species: BotanicalSpecies, stage: GardenGrowthStage) -> PixelGrid {
        switch species {
        case .fern:
            return FernPixelArt.grid(stage: stage)
        case .lavender:
            return lavender(stage)
        case .rosemary:
            return rosemary(stage)
        case .flowering:
            return flowering(stage)
        }
    }

    // MARK: - Lavender (upright spikes + soft purple tips)

    private static func lavender(_ stage: GardenGrowthStage) -> PixelGrid {
        switch stage {
        case .seedling: soilOnly
        case .sprout: PixelGrid.parse(pad([
            "000000000003000000000000",
            "000000000038300000000000",
            "000000000003000000000000",
            "000000000003000000000000",
        ] + soilRows))
        case .young: PixelGrid.parse(pad([
            "000000000008000000000000",
            "000000000038300000000000",
            "000000080003000800000000",
            "000000038003083000000000",
            "000000000300300000000000",
            "000000000003000000000000",
            "000000000003000000000000",
        ] + soilRows))
        case .growing: PixelGrid.parse(pad([
            "000000000008000000000000",
            "000000080038300800000000",
            "000000038003083000000000",
            "000008000300300008000000",
            "000003800030000830000000",
            "000000300003000300000000",
            "000000030003000300000000",
            "000000000300300000000000",
            "000000000003000000000000",
        ] + soilRows))
        case .mature: PixelGrid.parse(pad([
            "000000080008000800000000",
            "000000038038380300000000",
            "000008000300300008000000",
            "000003800030000830000000",
            "000800030003000300080000",
            "000380003003003000830000",
            "000030000300300000300000",
            "000003000030000003000000",
            "000000300003000300000000",
            "000000030003000300000000",
            "000000000300300000000000",
            "000000000003000000000000",
        ] + soilRows))
        }
    }

    // MARK: - Rosemary (narrow upright needles)

    private static func rosemary(_ stage: GardenGrowthStage) -> PixelGrid {
        switch stage {
        case .seedling: soilOnly
        case .sprout: PixelGrid.parse(pad([
            "000000000006000000000000",
            "000000000053500000000000",
            "000000000003000000000000",
            "000000000003000000000000",
        ] + soilRows))
        case .young: PixelGrid.parse(pad([
            "000000000006000000000000",
            "000000050053500500000000",
            "000000005003050000000000",
            "000000000300300000000000",
            "000000000003000000000000",
            "000000000003000000000000",
        ] + soilRows))
        case .growing: PixelGrid.parse(pad([
            "000000000006000000000000",
            "000000060053500600000000",
            "000000505003050500000000",
            "000000050300300500000000",
            "000000005003050000000000",
            "000000000300300000000000",
            "000000000003000000000000",
            "000000000003000000000000",
        ] + soilRows))
        case .mature: PixelGrid.parse(pad([
            "000000060006000600000000",
            "000000505053505050000000",
            "000005050003050500000000",
            "000000503003003050000000",
            "000000050300300500000000",
            "000000005003050000000000",
            "000000000300300000000000",
            "000000000030000000000000",
            "000000000003000000000000",
            "000000000003000000000000",
        ] + soilRows))
        }
    }

    // MARK: - Flowering (stem + simple bloom)

    private static func flowering(_ stage: GardenGrowthStage) -> PixelGrid {
        switch stage {
        case .seedling: soilOnly
        case .sprout: PixelGrid.parse(pad([
            "000000000009000000000000",
            "000000000003000000000000",
            "000000000053500000000000",
            "000000000003000000000000",
        ] + soilRows))
        case .young: PixelGrid.parse(pad([
            "000000000090900000000000",
            "000000000099900000000000",
            "000000000009000000000000",
            "000000050003000500000000",
            "000000005300350000000000",
            "000000000003000000000000",
            "000000000003000000000000",
        ] + soilRows))
        case .growing: PixelGrid.parse(pad([
            "000000009090900000000000",
            "000000000999000000000000",
            "000000000090000000000000",
            "000000900003000090000000",
            "000000090999090000000000",
            "000000500003000500000000",
            "000000053003035000000000",
            "000000000300300000000000",
            "000000000003000000000000",
        ] + soilRows))
        case .mature: PixelGrid.parse(pad([
            "000000090909090000000000",
            "000000009999900000000000",
            "000000000090000000000000",
            "000009000003000090000000",
            "000000900999009000000000",
            "000000090003090000000000",
            "000005000300300005000000",
            "000000530030000350000000",
            "000000003003003000000000",
            "000000000300300000000000",
            "000000000003000000000000",
            "000000000003000000000000",
        ] + soilRows))
        }
    }

    // MARK: - Shared soil (8 rows) — matches fern canvas height with padding

    private static let soilRows = [
        "000000000022200000000000",
        "000000000122221000000000",
        "000000001111111100000000",
        "000000011111111110000000",
        "000000111111111111000000",
        "000001111111111111100000",
        "000011111111111111110000",
        "000011111111111111110000",
    ]

    private static var soilOnly: PixelGrid {
        PixelGrid.parse(pad(soilRows))
    }

    /// Pad plant rows at the top so total height is 32 (fern canvas).
    private static func pad(_ plantRows: [String]) -> [String] {
        let empty = String(repeating: "0", count: 24)
        let needed = FernPixelArt.canvasHeight - plantRows.count
        precondition(needed >= 0, "Plant rows exceed canvas height")
        return Array(repeating: empty, count: needed) + plantRows
    }
}
