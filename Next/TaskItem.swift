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

enum SampleTasks {
    static let all: [TaskItem] = [
        TaskItem(
            title: "Review amino acids",
            durationMinutes: 25,
            energyRequired: .good,
            area: "Education",
            goal: "Study for MCAT"
        ),
        TaskItem(
            title: "Clean your space",
            durationMinutes: 15,
            energyRequired: .low,
            area: "Personal",
            goal: "Keep your space organized"
        ),
        TaskItem(
            title: "Coding practice",
            durationMinutes: 45,
            energyRequired: .ready,
            area: "Career",
            goal: "Improve programming"
        ),
        TaskItem(
            title: "Review flashcards",
            durationMinutes: 15,
            energyRequired: .low,
            area: "Education",
            goal: "Study for MCAT"
        ),
        TaskItem(
            title: "Work on personal project",
            durationMinutes: 60,
            energyRequired: .good,
            area: "Creative",
            goal: "Build something"
        )
    ]
}
