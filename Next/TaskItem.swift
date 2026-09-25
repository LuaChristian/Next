//
//  TaskItem.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation

struct TaskItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let durationMinutes: Int
    let energyRequired: EnergyLevel
    let area: String
    let goal: String

    init(
        id: UUID = UUID(),
        title: String,
        durationMinutes: Int,
        energyRequired: EnergyLevel,
        area: String,
        goal: String
    ) {
        self.id = id
        self.title = title
        self.durationMinutes = durationMinutes
        self.energyRequired = energyRequired
        self.area = area
        self.goal = goal
    }
}
