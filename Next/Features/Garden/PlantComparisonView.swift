//
//  PlantComparisonView.swift
//  Next
//
//  Development/review only. Never shown as product UI.
//

import SwiftUI

struct PlantComparisonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("PLANT COMPARISON")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(3.2)
                .foregroundStyle(NextTheme.secondary)
                .accessibilityAddTraits(.isHeader)

            Text("Review only. Same organism across stages.")
                .nextFont(17)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(PlantVariant.allCases) { variant in
                VStack(alignment: .leading, spacing: 12) {
                    Text(variant.reviewName.uppercased())
                        .nextFont(13, weight: .medium, relativeTo: .caption)
                        .tracking(1.8)
                        .foregroundStyle(NextTheme.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 24) {
                            ForEach(GardenGrowthStage.allCases, id: \.self) { stage in
                                VStack(spacing: 10) {
                                    PlantView(variant: variant, stage: stage)
                                        .frame(width: 96, height: 140)
                                    Text(stage.spokenName)
                                        .nextFont(13, weight: .medium, relativeTo: .caption)
                                        .foregroundStyle(NextTheme.secondary)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(variant.reviewName). \(stage.spokenName).")
                                .accessibilityIdentifier("compare-\(variant.rawValue)-\(stage.rawValue)")
                            }
                        }
                    }
                }
            }
        }
        .nextScrollableCanvas()
        .accessibilityIdentifier("plantComparison")
    }
}

extension PlantVariant {
    var reviewName: String {
        switch self {
        case .broadLeaf: "Broad leaf"
        case .narrowLeaf: "Narrow leaf"
        case .branching: "Branching"
        case .roundedLeaf: "Rounded leaf"
        }
    }
}
