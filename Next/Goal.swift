//
//  Goal.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation

enum GoalArea: String, CaseIterable, Identifiable {
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

enum GoalPriority: String, CaseIterable, Identifiable {
    case low
    case normal
    case high

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }
}

struct Goal: Identifiable, Hashable {
    let id: UUID
    var title: String
    var area: GoalArea
    var priority: GoalPriority
    var tasks: [TaskItem]

    init(
        id: UUID = UUID(),
        title: String,
        area: GoalArea,
        priority: GoalPriority,
        tasks: [TaskItem] = []
    ) {
        self.id = id
        self.title = title
        self.area = area
        self.priority = priority
        self.tasks = tasks
    }

    var taskCountLabel: String {
        tasks.count == 1 ? "1 TASK" : "\(tasks.count) TASKS"
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
