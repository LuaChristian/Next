//
//  GuidedTimeStepView.swift
//  Next
//
//  Guided step 2: available time, including an exact 25-minute option.
//

import SwiftUI

struct GuidedTimeStepView: View {
    var draft: GuidedFocusDraft
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var stacksChoices: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        GuidedFocusStepChrome(
            eyebrow: "HELP ME DECIDE",
            progressStep: 2,
            title: "How much time do you have?"
        ) {
            Text("Choose how much time you have.")
                .nextFont(17)
                .foregroundStyle(NextTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            presets
                .padding(.top, 20)
                .accessibilityIdentifier("homeTimeSection")

            NextHairline()
                .padding(.top, 22)

            exactCustom
                .padding(.top, 22)
                .accessibilityIdentifier("guidedExactTimeSection")

            Button {
                draft.goToEnergy()
            } label: {
                Text("CONTINUE →")
                    .nextFont(13, weight: .semibold)
                    .tracking(2.2)
                    .foregroundStyle(draft.time != nil ? NextTheme.interactiveAccent : NextTheme.disabledText)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .disabled(draft.time == nil)
            .accessibilityValue(draft.time == nil ? "Needs selection" : "Ready")
            .padding(.top, 32)
            .accessibilityIdentifier("guidedTimeContinue")
        }
        .accessibilityIdentifier("guidedTimeStep")
    }

    private var presets: some View {
        Group {
            if stacksChoices {
                VStack(spacing: 4) {
                    ForEach(TimeOption.standardPresets) { option in
                        timeChip(option)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(TimeOption.standardPresets) { option in
                        timeChip(option)
                    }
                }
            }
        }
    }

    private var exactCustom: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXACT DURATION")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondaryText)
                .accessibilityAddTraits(.isHeader)

            SelectionOption(
                title: TimeOption.twentyFive.title,
                isSelected: draft.time == .twentyFive,
                accessibilityIdentifier: "guidedTime-twentyFive"
            ) {
                draft.selectTime(.twentyFive)
            }
            .accessibilityHint("Exact duration")
            .frame(maxWidth: stacksChoices ? .infinity : 120, alignment: .leading)
        }
    }

    private func timeChip(_ option: TimeOption) -> some View {
        SelectionOption(
            title: option.title,
            isSelected: draft.time == option,
            accessibilityIdentifier: "guidedTime-\(option.minutes)"
        ) {
            draft.selectTime(option)
        }
    }
}
