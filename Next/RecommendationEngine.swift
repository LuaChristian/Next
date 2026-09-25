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

struct RecommendationEngine {
    func recommendations(
        tasks: [TaskItem],
        availableTime: TimeOption,
        energy: EnergyLevel
    ) -> [TaskItem] {
        let availableMinutes = availableTime.minutes

        return tasks
            .enumerated()
            .filter { _, task in
                task.durationMinutes <= availableMinutes
                    && task.energyRequired <= energy
            }
            .sorted { lhs, rhs in
                if lhs.element.durationMinutes != rhs.element.durationMinutes {
                    return lhs.element.durationMinutes > rhs.element.durationMinutes
                }

                let lhsEnergyDistance = energy.rank - lhs.element.energyRequired.rank
                let rhsEnergyDistance = energy.rank - rhs.element.energyRequired.rank
                if lhsEnergyDistance != rhsEnergyDistance {
                    return lhsEnergyDistance < rhsEnergyDistance
                }

                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}
