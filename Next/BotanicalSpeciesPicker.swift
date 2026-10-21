//
//  BotanicalSpeciesPicker.swift
//  Next
//
//  Editorial plant selection for goal create / edit.
//

import SwiftUI

struct BotanicalSpeciesPicker: View {
    @Binding var selection: BotanicalSpecies
    var previewStage: GardenGrowthStage = .young

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PLANT")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondary)

            Text("Choose how this goal grows in your garden.")
                .nextFont(16)
                .foregroundStyle(NextTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(BotanicalSpecies.allCases) { species in
                        speciesCell(species)
                    }
                }
                .padding(.vertical, 4)
            }
            .accessibilityElement(children: .contain)
        }
        .accessibilityIdentifier("botanicalSpeciesPicker")
    }

    private func speciesCell(_ species: BotanicalSpecies) -> some View {
        let selected = selection == species
        return Button {
            selection = species
        } label: {
            VStack(spacing: 10) {
                PlantView(species: species, stage: previewStage)
                    .frame(width: 56, height: 76)

                Text(species.displayName.uppercased())
                    .nextFont(11, weight: .medium, relativeTo: .caption2)
                    .tracking(1.2)
                    .foregroundStyle(selected ? NextTheme.ink : NextTheme.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 88)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(selected ? NextTheme.accentSurface : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(
                        selected ? NextTheme.interactiveAccent : NextTheme.separator,
                        lineWidth: selected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(species.displayName)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
        .accessibilityIdentifier("botanicalSpecies-\(species.rawValue)")
    }
}
