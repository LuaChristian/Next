//
//  RecommendationScope.swift
//  Next
//
//  Home recommendation filter applied before Recommendation Engine 2.0 ranking.
//

import Foundation

enum RecommendationScopeMode: String, CaseIterable, Identifiable {
    case anything
    case lifeArea
    case specificGoal

    var id: Self { self }

    var title: String {
        switch self {
        case .anything: "Anything"
        case .lifeArea: "Life area"
        case .specificGoal: "Specific goal"
        }
    }
}

struct RecommendationScope: Equatable, Hashable {
    var mode: RecommendationScopeMode = .anything
    var selectedArea: GoalArea?
    var selectedGoalID: UUID?

    static let anything = RecommendationScope()

    /// Ready to run WHAT'S NEXT? — Anything always; other modes need a concrete choice.
    var isReady: Bool {
        switch mode {
        case .anything: true
        case .lifeArea: selectedArea != nil
        case .specificGoal: selectedGoalID != nil
        }
    }

    func includes(_ goal: Goal) -> Bool {
        switch mode {
        case .anything:
            return true
        case .lifeArea:
            guard let selectedArea else { return false }
            return goal.areas.contains(selectedArea)
        case .specificGoal:
            guard let selectedGoalID else { return false }
            return goal.id == selectedGoalID
        }
    }

    mutating func selectMode(_ mode: RecommendationScopeMode) {
        self.mode = mode
        // Do not carry a selection across modes.
        selectedArea = nil
        selectedGoalID = nil
    }

    mutating func validate(against goals: [Goal]) {
        switch mode {
        case .anything:
            selectedArea = nil
            selectedGoalID = nil
        case .lifeArea:
            selectedGoalID = nil
            if let selectedArea, !GoalArea.allCases.contains(selectedArea) {
                self.selectedArea = nil
            }
        case .specificGoal:
            selectedArea = nil
            if let selectedGoalID, !goals.contains(where: { $0.id == selectedGoalID }) {
                self.selectedGoalID = nil
            }
        }
    }
}

enum RecommendationEmptyKind: Equatable {
    case noTasksInApp
    case scopeNeedsSelection
    case scopeHasNoActiveTasks
    case noneFitTimeAndEnergy

    var headline: String {
        switch self {
        case .noTasksInApp: "NO TASKS YET"
        case .scopeNeedsSelection: "CHOOSE A FOCUS"
        case .scopeHasNoActiveTasks: "NOTHING IN THIS FOCUS"
        case .noneFitTimeAndEnergy: "NOTHING FITS RIGHT NOW"
        }
    }

    var message: String {
        switch self {
        case .noTasksInApp:
            "Plant a goal and add a task before asking what's next."
        case .scopeNeedsSelection:
            "Choose a life area or goal, or switch back to Anything."
        case .scopeHasNoActiveTasks:
            "There are no open tasks in this focus. Try another scope or add a task."
        case .noneFitTimeAndEnergy:
            "None of your tasks in this focus fit this time and energy combination."
        }
    }
}

enum RecommendationEmptyKindResolver {
    static func resolve(
        scope: RecommendationScope,
        scopedActiveTaskCount: Int,
        rankedCount: Int,
        hasAnyTasksInApp: Bool
    ) -> RecommendationEmptyKind? {
        guard rankedCount == 0 else { return nil }
        if !hasAnyTasksInApp { return .noTasksInApp }
        if !scope.isReady { return .scopeNeedsSelection }
        if scopedActiveTaskCount == 0 { return .scopeHasNoActiveTasks }
        return .noneFitTimeAndEnergy
    }
}
