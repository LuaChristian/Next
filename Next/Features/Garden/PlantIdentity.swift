//
//  PlantIdentity.swift
//  Next
//
//  Stable plant identity on Goal. Growth remains derived from FocusSessions.
//

import Foundation
import SwiftData

enum PlantVariant: String, CaseIterable, Identifiable, Codable {
    case broadLeaf
    case narrowLeaf
    case branching
    case roundedLeaf

    var id: Self { self }

    /// Least-used variant among current Goals, stable order as a tie-break.
    static func next(among goals: [Goal]) -> PlantVariant {
        let counts = Dictionary(grouping: goals, by: \.plantVariant).mapValues(\.count)
        return allCases.min { lhs, rhs in
            let left = counts[lhs, default: 0]
            let right = counts[rhs, default: 0]
            if left != right { return left < right }
            return (allCases.firstIndex(of: lhs) ?? 0) < (allCases.firstIndex(of: rhs) ?? 0)
        } ?? .broadLeaf
    }

    static func next(in context: ModelContext) -> PlantVariant {
        let goals = (try? context.fetch(FetchDescriptor<Goal>())) ?? []
        return next(among: goals)
    }
}

enum GardenAcknowledgement {
    static func message(
        goalTitle: String,
        previousStage: GardenGrowthStage,
        nextStage: GardenGrowthStage
    ) -> String {
        if nextStage.rawValue > previousStage.rawValue {
            return "Your \(goalTitle) plant has new growth."
        }
        return "This session helped your \(goalTitle) plant grow."
    }
}
