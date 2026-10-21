//
//  PixelPlantArt.swift
//  Next
//
//  Cozy pixel-art plant foundation (V3-M7).
//  Separates: species identity → growth stage → pixel grid → SwiftUI draw.
//  Goal persistence and GardenGrowth thresholds are untouched.
//

import SwiftUI
import UIKit

// MARK: - Species alias

/// Pixel-art species identity — same catalog as user-selectable `BotanicalSpecies`.
typealias PixelPlantSpecies = BotanicalSpecies

// MARK: - Presentation bridge

/// Maps a botanical species to pixel artwork.
/// Catalog assets still win in `PlantArtwork.resolve`. Returning `nil` yields Canvas.
enum PixelPlantPresentation {
    /// Production: every catalog species has pixel artwork.
    static func pixelSpecies(for species: BotanicalSpecies) -> PixelPlantSpecies? {
        #if DEBUG
        if let override = testPixelOverride {
            return override(species)
        }
        #endif
        return species
    }

    /// Legacy silhouette → botanical species (existing goals / tests).
    static func species(for variant: PlantVariant) -> PixelPlantSpecies? {
        pixelSpecies(for: BotanicalSpecies.resolved(stored: variant.rawValue))
    }

    #if DEBUG
    /// Test-only seam to exercise Canvas fallback. Never read in Release.
    static var testPixelOverride: ((BotanicalSpecies) -> PixelPlantSpecies?)?

    static func resetTestOverrides() {
        testPixelOverride = nil
    }
    #endif
}

// MARK: - Grid

struct PixelGrid: Equatable {
    let width: Int
    let height: Int
    /// Row-major palette indices. `0` = transparent.
    let cells: [UInt8]

    init(width: Int, height: Int, cells: [UInt8]) {
        precondition(width > 0 && height > 0)
        precondition(cells.count == width * height)
        self.width = width
        self.height = height
        self.cells = cells
    }

    /// Build from equal-length rows of digit characters (`0`–`9`).
    static func parse(_ rows: [String]) -> PixelGrid {
        precondition(!rows.isEmpty)
        let width = rows[0].count
        precondition(rows.allSatisfy { $0.count == width })
        var cells: [UInt8] = []
        cells.reserveCapacity(width * rows.count)
        for row in rows {
            for ch in row {
                let value = UInt8(String(ch), radix: 10) ?? 0
                cells.append(value)
            }
        }
        return PixelGrid(width: width, height: rows.count, cells: cells)
    }

    func index(at x: Int, y: Int) -> UInt8 {
        cells[y * width + x]
    }
}

// MARK: - Palette

enum PixelPlantPalette {
    /// Index legend:
    /// 0 clear · 1 soil · 2 seed · 3 stem · 4–6 foliage · 7 tip · 8 lavender · 9 bloom
    static func color(index: UInt8, colorScheme: ColorScheme) -> Color? {
        guard index > 0 else { return nil }
        let dark = colorScheme == .dark
        switch index {
        case 1: // soil
            return Color(
                uiColor: dark
                    ? UIColor(red: 0.42, green: 0.36, blue: 0.28, alpha: 1)
                    : UIColor(red: 0.55, green: 0.46, blue: 0.34, alpha: 1)
            )
        case 2: // seed / dark soil
            return Color(
                uiColor: dark
                    ? UIColor(red: 0.32, green: 0.27, blue: 0.20, alpha: 1)
                    : UIColor(red: 0.40, green: 0.32, blue: 0.22, alpha: 1)
            )
        case 3: // stem
            return Color(
                uiColor: dark
                    ? UIColor(red: 0.45, green: 0.58, blue: 0.48, alpha: 1)
                    : UIColor(red: 0.28, green: 0.40, blue: 0.30, alpha: 1)
            )
        case 4: // frond deep
            return Color(
                uiColor: dark
                    ? UIColor(red: 0.38, green: 0.55, blue: 0.42, alpha: 1)
                    : UIColor(red: 0.22, green: 0.38, blue: 0.28, alpha: 1)
            )
        case 5: // frond mid
            return Color(
                uiColor: dark
                    ? UIColor(red: 0.48, green: 0.66, blue: 0.52, alpha: 1)
                    : UIColor(red: 0.32, green: 0.48, blue: 0.36, alpha: 1)
            )
        case 6: // frond light
            return Color(
                uiColor: dark
                    ? UIColor(red: 0.58, green: 0.74, blue: 0.60, alpha: 1)
                    : UIColor(red: 0.42, green: 0.58, blue: 0.44, alpha: 1)
            )
        case 7: // soft tip / highlight
            return Color(
                uiColor: dark
                    ? UIColor(red: 0.70, green: 0.82, blue: 0.70, alpha: 1)
                    : UIColor(red: 0.55, green: 0.68, blue: 0.52, alpha: 1)
            )
        case 8: // lavender
            return Color(
                uiColor: dark
                    ? UIColor(red: 0.72, green: 0.62, blue: 0.82, alpha: 1)
                    : UIColor(red: 0.55, green: 0.45, blue: 0.62, alpha: 1)
            )
        case 9: // bloom / petal
            return Color(
                uiColor: dark
                    ? UIColor(red: 0.86, green: 0.70, blue: 0.72, alpha: 1)
                    : UIColor(red: 0.72, green: 0.48, blue: 0.50, alpha: 1)
            )
        default:
            return nil
        }
    }
}

// MARK: - Catalog

enum PixelPlantCatalog {
    static func grid(species: PixelPlantSpecies, stage: GardenGrowthStage) -> PixelGrid {
        BotanicalPlaceholderArt.grid(species: species, stage: stage)
    }
}

// MARK: - Renderer

enum PixelArtRenderer {
    /// Integer nearest-neighbor scale, bottom-centered in `size` (plant anchor).
    static func draw(
        grid: PixelGrid,
        in context: inout GraphicsContext,
        size: CGSize,
        colorScheme: ColorScheme
    ) {
        guard size.width > 0, size.height > 0 else { return }

        let scale = max(
            1,
            floor(min(size.width / CGFloat(grid.width), size.height / CGFloat(grid.height)))
        )
        let drawnWidth = scale * CGFloat(grid.width)
        let drawnHeight = scale * CGFloat(grid.height)
        let originX = (size.width - drawnWidth) / 2
        let originY = size.height - drawnHeight

        for y in 0..<grid.height {
            for x in 0..<grid.width {
                let index = grid.index(at: x, y: y)
                guard let color = PixelPlantPalette.color(index: index, colorScheme: colorScheme) else {
                    continue
                }
                let rect = CGRect(
                    x: originX + CGFloat(x) * scale,
                    y: originY + CGFloat(y) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(color))
            }
        }
    }
}

struct PixelPlantView: View {
    let species: PixelPlantSpecies
    let stage: GardenGrowthStage
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let grid = PixelPlantCatalog.grid(species: species, stage: stage)
        Canvas { context, size in
            PixelArtRenderer.draw(
                grid: grid,
                in: &context,
                size: size,
                colorScheme: colorScheme
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
    }
}
