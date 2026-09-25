//
//  Goal.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation
import SwiftData

enum GoalArea: String, CaseIterable, Identifiable, Codable {
    case education
    case career
    case fitness
    case creative
    case wellness
    case finance
    case social
    case personal

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }
}

enum GoalPriority: String, CaseIterable, Identifiable, Codable {
    case low
    case normal
    case high

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }
}

enum TaskDuration: CaseIterable, Identifiable {
    case fifteen
    case thirty
    case fortyFive
    case sixty
    case ninetyPlus

    var id: Self { self }

    var minutes: Int {
        switch self {
        case .fifteen: 15
        case .thirty: 30
        case .fortyFive: 45
        case .sixty: 60
        case .ninetyPlus: 90
        }
    }

    var title: String {
        switch self {
        case .fifteen: "15 min"
        case .thirty: "30 min"
        case .fortyFive: "45 min"
        case .sixty: "60 min"
        case .ninetyPlus: "90+ min"
        }
    }
}

@Model
final class Goal {
    var id: UUID
    var title: String
    var area: GoalArea
    var priority: GoalPriority
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \GoalTask.goal)
    var tasks: [GoalTask]

    init(
        id: UUID = UUID(),
        title: String,
        area: GoalArea,
        priority: GoalPriority,
        createdAt: Date = Date(),
        tasks: [GoalTask] = []
    ) {
        self.id = id
        self.title = title
        self.area = area
        self.priority = priority
        self.createdAt = createdAt
        self.tasks = tasks
    }

    var sortedTasks: [GoalTask] {
        tasks.sorted { $0.createdAt < $1.createdAt }
    }

    var taskCountLabel: String {
        tasks.count == 1 ? "1 TASK" : "\(tasks.count) TASKS"
    }
}

@Model
final class GoalTask {
    var id: UUID
    var title: String
    var durationMinutes: Int
    var energyRequired: EnergyLevel
    var createdAt: Date
    var goal: Goal?

    init(
        id: UUID = UUID(),
        title: String,
        durationMinutes: Int,
        energyRequired: EnergyLevel,
        createdAt: Date = Date(),
        goal: Goal? = nil
    ) {
        self.id = id
        self.title = title
        self.durationMinutes = durationMinutes
        self.energyRequired = energyRequired
        self.createdAt = createdAt
        self.goal = goal
    }

    var asTaskItem: TaskItem {
        TaskItem(
            id: id,
            title: title,
            durationMinutes: durationMinutes,
            energyRequired: energyRequired,
            area: goal?.area.title ?? "",
            goal: goal?.title ?? ""
        )
    }
}
