//
//  RecommendationEngine.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation

extension TimeOption {
    var minutes: Int {
        switch self {
        case .fifteen: 15
        case .thirty: 30
        case .sixty: 60
        case .ninetyPlus: 90
        }
    }
}

extension EnergyLevel: Comparable {
    var rank: Int {
        switch self {
        case .low: 1
        case .good: 2
        case .ready: 3
        }
    }

    static func < (lhs: EnergyLevel, rhs: EnergyLevel) -> Bool {
        lhs.rank < rhs.rank
    }
}

struct RecommendationExplanation: Equatable, Hashable {
    let lines: [String]

    var accessibilityText: String {
        lines.joined(separator: " ")
    }
}

struct RankedRecommendation: Identifiable, Hashable {
    let task: TaskItem
    let explanation: RecommendationExplanation

    var id: UUID { task.id }
}

struct RecommendationEngine {
    func recommendations(
        tasks: [TaskItem],
        availableTime: TimeOption,
        energy: EnergyLevel
    ) -> [TaskItem] {
        rankedRecommendations(
            tasks: tasks,
            availableTime: availableTime,
            energy: energy
        ).map(\.task)
    }

    func rankedRecommendations(
        tasks: [TaskItem],
        availableTime: TimeOption,
        energy: EnergyLevel
    ) -> [RankedRecommendation] {
        let availableMinutes = availableTime.minutes

        return tasks
            .enumerated()
            .filter { _, task in
                isEligible(task, availableMinutes: availableMinutes, energy: energy)
            }
            .sorted { lhs, rhs in
                compare(lhs, rhs, energy: energy)
            }
            .map { pair in
                RankedRecommendation(
                    task: pair.element,
                    explanation: explanation(
                        for: pair.element,
                        availableTime: availableTime,
                        energy: energy
                    )
                )
            }
    }

    func isEligible(
        _ task: TaskItem,
        availableMinutes: Int,
        energy: EnergyLevel
    ) -> Bool {
        task.durationMinutes <= availableMinutes && task.energyRequired <= energy
    }

    func explanation(
        for task: TaskItem,
        availableTime: TimeOption,
        energy: EnergyLevel
    ) -> RecommendationExplanation {
        let fit = "Fits your \(availableTime.minutes) minutes and \(energy.title) energy."
        let reason: String
        if task.goalPriority == .high {
            if task.lastFocusedAt == nil {
                reason = "\(task.goal) is a high-priority goal you haven't worked on yet."
            } else {
                reason = "\(task.goal) is a high-priority goal you haven't worked on recently."
            }
        } else if task.lastFocusedAt == nil {
            reason = "You haven't worked on \(task.goal) yet."
        } else {
            reason = "This goal has had less attention recently."
        }
        return RecommendationExplanation(lines: [fit, reason])
    }

    private func compare(
        _ lhs: (offset: Int, element: TaskItem),
        _ rhs: (offset: Int, element: TaskItem),
        energy: EnergyLevel
    ) -> Bool {
        let left = lhs.element
        let right = rhs.element

        if left.goalPriority != right.goalPriority {
            return left.goalPriority > right.goalPriority
        }

        switch (left.lastFocusedAt, right.lastFocusedAt) {
        case (nil, nil):
            break
        case (nil, .some):
            return true
        case (.some, nil):
            return false
        case let (leftDate?, rightDate?) where leftDate != rightDate:
            return leftDate < rightDate
        default:
            break
        }

        if left.durationMinutes != right.durationMinutes {
            return left.durationMinutes > right.durationMinutes
        }

        let leftEnergyDistance = energy.rank - left.energyRequired.rank
        let rightEnergyDistance = energy.rank - right.energyRequired.rank
        if leftEnergyDistance != rightEnergyDistance {
            return leftEnergyDistance < rightEnergyDistance
        }

        return lhs.offset < rhs.offset
    }
}
