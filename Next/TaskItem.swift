//
//  TaskItem.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation

struct TaskItem: Identifiable, Hashable {
    let id: UUID
    let goalID: UUID?
    let title: String
    let durationMinutes: Int
    let energyRequired: EnergyLevel
    let area: String
    let goal: String
    let goalPriority: GoalPriority
    let lastFocusedAt: Date?

    init(
        id: UUID = UUID(),
        goalID: UUID? = nil,
        title: String,
        durationMinutes: Int,
        energyRequired: EnergyLevel,
        area: String,
        goal: String,
        goalPriority: GoalPriority = .normal,
        lastFocusedAt: Date? = nil
    ) {
        self.id = id
        self.goalID = goalID
        self.title = title
        self.durationMinutes = durationMinutes
        self.energyRequired = energyRequired
        self.area = area
        self.goal = goal
        self.goalPriority = goalPriority
        self.lastFocusedAt = lastFocusedAt
    }
}
