//
//  FocusRecoveryPromptView.swift
//  Next
//
//  Calm cold-launch recovery gate. Never auto-resumes the timer.
//

import SwiftUI

struct FocusRecoveryPromptView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let model: FocusRecoveryPromptModel
    let onResume: () -> Void
    let onEndSession: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NEXT")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(3.2)
                .foregroundStyle(NextTheme.secondary)

            Text("Continue where you left off?")
                .nextFont(28, relativeTo: .title)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, dynamicTypeSize.isAccessibilitySize ? 24 : 36)
                .accessibilityIdentifier("recoveryPromptTitle")

            sessionContext
                .padding(.top, dynamicTypeSize.isAccessibilitySize ? 24 : 32)

            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 24 : 36)

            actions
        }
        .nextScrollableCanvas(top: 16)
        .accessibilityElement(children: .contain)
    }

    private var sessionContext: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(model.taskTitle)
                .nextFont(22, relativeTo: .title2)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("recoveryTaskTitle")

            Text(model.goalTitle.uppercased())
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 12)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("recoveryGoalTitle")

            NextHairline()
                .padding(.top, 24)
                .padding(.bottom, 20)

            Text(model.modeLabel.uppercased())
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(2.2)
                .foregroundStyle(NextTheme.secondary)
                .accessibilityIdentifier("recoveryModeLabel")

            Text(earnedLabel)
                .nextFont(17)
                .foregroundStyle(NextTheme.botanical)
                .padding(.top, 10)
                .accessibilityIdentifier("recoveryEarnedFocus")

            if model.wasInterruptedWhileRunning {
                Text("Your session was interrupted. Focus already earned is saved. Time away was not counted.")
                    .nextFont(15)
                    .foregroundStyle(NextTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
                    .accessibilityIdentifier("recoveryPolicyNote")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var actions: some View {
        VStack(spacing: 16) {
            NextHairline()

            Button("RESUME") {
                onResume()
            }
            .nextFont(13, weight: .semibold)
            .tracking(2.2)
            .foregroundStyle(NextTheme.botanical)
            .frame(maxWidth: .infinity, minHeight: 48)
            .accessibilityIdentifier("recoveryResume")
            .accessibilityHint("Continues this focus session")

            NextHairline()
                .padding(.top, 4)

            Button("End Session") {
                onEndSession()
            }
            .nextFont(16)
            .foregroundStyle(NextTheme.secondary)
            .frame(maxWidth: .infinity, minHeight: 48)
            .accessibilityIdentifier("recoveryEndSession")
            .accessibilityHint("Ends this session and keeps the focus time already earned")
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.experienceID)
    }

    private var earnedLabel: String {
        if model.earnedFocusSeconds < 1 {
            return "No focus time earned yet"
        }
        return GardenMetrics.focusedDurationLabel(seconds: model.earnedFocusSeconds)
    }

    private var accessibilitySummary: String {
        var parts = [
            model.taskTitle,
            model.goalTitle,
            model.modeLabel,
            earnedLabel
        ]
        if model.wasInterruptedWhileRunning {
            parts.append("Interrupted. Focus already earned is saved. Time away was not counted.")
        }
        return parts.joined(separator: ". ")
    }
}
