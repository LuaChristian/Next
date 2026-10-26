//
//  BotanicalPlantView.swift
//  Next
//
//  Compatibility wrapper. New surfaces should use PlantView.
//

import SwiftUI

#Preview {
    HStack(alignment: .bottom, spacing: 16) {
        ForEach(GardenGrowthStage.allCases, id: \.self) { stage in
            PlantView(variant: .broadLeaf, stage: stage)
                .frame(width: 56, height: 80)
        }
    }
    .padding()
    .background(NextTheme.canvas)
}
