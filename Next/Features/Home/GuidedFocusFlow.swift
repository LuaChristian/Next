//
//  GuidedFocusFlow.swift
//  Next
//
//  Shared draft + step model for the page-by-page Help me decide experience.
//

import Foundation
import Observation
import SwiftUI

enum GuidedFocusStep: Int, Equatable {
    case scope = 1
    case time = 2
    case energy = 3
    case recommendation = 4

    var progressLabelStep: Int? {
        switch self {
        case .scope, .time, .energy: rawValue
        case .recommendation: nil
        }
    }
}

@Observable
final class GuidedFocusDraft {
    var scope = RecommendationScope.anything
    var time: TimeOption?
    var energy: EnergyLevel?
    var step: GuidedFocusStep = .scope

    var canLeaveScope: Bool {
        switch scope.mode {
        case .anything:
            return true
        case .lifeArea, .specificGoal:
            return scope.isReady
        }
    }

    func selectScopeMode(_ mode: RecommendationScopeMode) {
        guard scope.mode != mode else { return }
        scope.selectMode(mode)
        // Changing scope invalidates downstream answers that may no longer apply.
        time = nil
        energy = nil
        if step.rawValue > GuidedFocusStep.scope.rawValue {
            step = .scope
        }
    }

    func selectTime(_ option: TimeOption) {
        time = option
    }

    func selectEnergy(_ level: EnergyLevel) {
        energy = level
    }

    func goToTime(validatingAgainst goals: [Goal]) {
        scope.validate(against: goals)
        guard canLeaveScope else { return }
        step = .time
    }

    func goToEnergy() {
        guard time != nil else { return }
        step = .energy
    }

    func goToRecommendation() {
        guard energy != nil else { return }
        step = .recommendation
    }

    func goBack() -> Bool {
        switch step {
        case .scope:
            return false
        case .time:
            step = .scope
            return true
        case .energy:
            step = .time
            return true
        case .recommendation:
            step = .energy
            return true
        }
    }

    func resetToScope() {
        step = .scope
    }

    func validatedInput(against goals: [Goal]) -> RecommendationInput? {
        guard let time, let energy else { return nil }
        var scoped = scope
        scoped.validate(against: goals)
        return RecommendationInput(time: time, energy: energy, scope: scoped)
    }
}

struct GuidedFocusProgressLabel: View {
    let step: Int
    let total: Int

    private var label: String {
        String(format: "%02d / %02d", step, total)
    }

    var body: some View {
        Text(label)
            .nextFont(13, weight: .medium, relativeTo: .caption)
            .tracking(1.8)
            .foregroundStyle(NextTheme.secondaryText)
            .accessibilityLabel(label)
            .accessibilityHint("Step \(step) of \(total)")
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("guidedProgress-\(step)")
    }
}

struct GuidedFocusStepChrome<Content: View>: View {
    let eyebrow: String
    let progressStep: Int?
    let title: String
    @ViewBuilder var content: () -> Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var stacksHeader: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Progress sits in the scroll content (not the toolbar) so it never
                // competes with Back at large Dynamic Type.
                if let progressStep {
                    GuidedFocusProgressLabel(step: progressStep, total: 3)
                        .padding(.top, stacksHeader ? 4 : 0)
                }

                Text(eyebrow)
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(3.2)
                    .foregroundStyle(NextTheme.secondaryText)
                    .padding(.top, progressStep == nil ? 0 : (stacksHeader ? 16 : 20))
                    .accessibilityAddTraits(.isHeader)

                Text(title)
                    .nextFont(28, relativeTo: .title)
                    .foregroundStyle(NextTheme.primaryText)
                    .padding(.top, stacksHeader ? 20 : 16)
                    .fixedSize(horizontal: false, vertical: true)

                content()
                    .padding(.top, stacksHeader ? 24 : 28)
            }
            .padding(.horizontal, NextTheme.pagePadding)
            .padding(.top, stacksHeader ? 8 : 12)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationBarTitleDisplayMode(.inline)
    }
}
