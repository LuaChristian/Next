//
//  GuidedEnergyStepView.swift
//  Next
//
//  Guided step 3: energy → recommendation.
//

import SwiftUI

struct GuidedEnergyStepView: View {
    var draft: GuidedFocusDraft
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var stacksChoices: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        GuidedFocusStepChrome(
            eyebrow: "HELP ME DECIDE",
            progressStep: 3,
            title: "How are you feeling?"
        ) {
            energyChoices
                .accessibilityIdentifier("homeEnergySection")

            Button {
                draft.goToRecommendation()
            } label: {
                Text("SEE WHAT'S NEXT →")
                    .nextFont(13, weight: .semibold)
                    .tracking(2.2)
                    .foregroundStyle(draft.energy != nil ? NextTheme.interactiveAccent : NextTheme.disabledText)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .disabled(draft.energy == nil)
            .accessibilityValue(draft.energy == nil ? "Needs selection" : "Ready")
            .padding(.top, 32)
            .accessibilityIdentifier("guidedEnergyContinue")
        }
        .accessibilityIdentifier("guidedEnergyStep")
    }

    private var energyChoices: some View {
        Group {
            if stacksChoices {
                VStack(spacing: 4) {
                    ForEach(EnergyLevel.allCases) { level in
                        energyChip(level)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(EnergyLevel.allCases) { level in
                        energyChip(level)
                    }
                }
            }
        }
    }

    private func energyChip(_ level: EnergyLevel) -> some View {
        SelectionOption(
            title: level.title,
            isSelected: draft.energy == level,
            accessibilityIdentifier: "guidedEnergy-\(level.rawValue)"
        ) {
            draft.selectEnergy(level)
        }
        .accessibilityLabel(level.title)
    }
}
