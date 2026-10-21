//
//  GardenPlantCell.swift
//  Next
//
//  Living Garden collection cell. Botanical artwork leads; growth context
//  is restrained copy beneath. No decorative card chrome.
//

import SwiftUI

struct GardenPlantCell: View {
    let goal: Goal
    let plantSize: CGSize
    var columns: Int = 1

    var body: some View {
        VStack(alignment: columns == 1 ? .leading : .center, spacing: 0) {
            PlantView(species: goal.botanicalSpecies, stage: goal.growthStage)
                .frame(width: plantSize.width, height: plantSize.height)
                .frame(maxWidth: .infinity, alignment: columns == 1 ? .leading : .center)

            Text(goal.title)
                .nextFont(columns == 1 ? 22 : 17, relativeTo: columns == 1 ? .title3 : .body)
                .foregroundStyle(NextTheme.ink)
                .multilineTextAlignment(columns == 1 ? .leading : .center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: columns == 1 ? .leading : .center)
                .padding(.top, 16)

            Text(goal.growthStage.spokenName.uppercased())
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.4)
                .foregroundStyle(NextTheme.secondary)
                .multilineTextAlignment(columns == 1 ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: columns == 1 ? .leading : .center)
                .padding(.top, 8)

            Text(GardenMetrics.focusedDurationLabel(seconds: goal.totalFocusedDuration))
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.2)
                .foregroundStyle(NextTheme.secondary)
                .multilineTextAlignment(columns == 1 ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: columns == 1 ? .leading : .center)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: columns == 1 ? .leading : .center)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(goal.progressAccessibilityLabel)
        .accessibilityValue(goal.growthStage.spokenName)
        .accessibilityIdentifier("gardenGoal-\(goal.title)")
    }
}
