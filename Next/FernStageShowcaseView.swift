//
//  FernStageShowcaseView.swift
//  Next
//
//  DEBUG / UITest review only. Fern stages at a consistent frame size.
//  Launch: UITEST_FERN_STAGES [optional stage 0-4 for a single focused shot]
//

import SwiftUI

#if DEBUG
struct FernStageShowcaseView: View {
    /// UITest: `UITEST_FERN_STAGES` optionally followed by `0`…`4`.
    static let argument = "UITEST_FERN_STAGES"

    private let focusedStage: GardenGrowthStage?

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        if let index = arguments.firstIndex(of: Self.argument),
           arguments.indices.contains(index + 1),
           let raw = Int(arguments[index + 1]),
           let stage = GardenGrowthStage(rawValue: raw) {
            focusedStage = stage
        } else {
            focusedStage = nil
        }
    }

    private var stages: [GardenGrowthStage] {
        if let focusedStage { return [focusedStage] }
        return Array(GardenGrowthStage.allCases)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("FERN STAGES")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(3.2)
                .foregroundStyle(NextTheme.secondary)
                .accessibilityAddTraits(.isHeader)

            Text(focusedStage == nil
                 ? "Reference pixel fern. Review only."
                 : "Reference pixel fern · Stage \(focusedStage!.rawValue).")
                .nextFont(17)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(stages, id: \.self) { stage in
                HStack(spacing: 20) {
                    PixelPlantView(species: .fern, stage: stage)
                        .frame(
                            width: focusedStage == nil ? 96 : 160,
                            height: focusedStage == nil ? 140 : 220
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("STAGE \(stage.rawValue)")
                            .nextFont(13, weight: .medium, relativeTo: .caption)
                            .tracking(1.6)
                            .foregroundStyle(NextTheme.secondary)
                        Text(stage.spokenName)
                            .nextFont(22, relativeTo: .title3)
                            .foregroundStyle(NextTheme.ink)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, focusedStage == nil ? 8 : 24)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Fern. Stage \(stage.rawValue). \(stage.spokenName).")
                .accessibilityIdentifier("fernStage-\(stage.rawValue)")

                if stage != stages.last {
                    NextHairline()
                }
            }

            Spacer(minLength: 0)
        }
        .nextScrollableCanvas()
        .accessibilityIdentifier("fernStageShowcase")
    }
}
#endif
