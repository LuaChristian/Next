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

    @Relationship(deleteRule: .cascade, inverse: \FocusSession.goal)
    var focusSessions: [FocusSession]

    init(
        id: UUID = UUID(),
        title: String,
        area: GoalArea,
        priority: GoalPriority,
        createdAt: Date = Date(),
        tasks: [GoalTask] = [],
        focusSessions: [FocusSession] = []
    ) {
        self.id = id
        self.title = title
        self.area = area
        self.priority = priority
        self.createdAt = createdAt
        self.tasks = tasks
        self.focusSessions = focusSessions
    }

    var sortedTasks: [GoalTask] {
        tasks.sorted { $0.createdAt < $1.createdAt }
    }

    var activeTasks: [GoalTask] {
        sortedTasks.filter(\.isActive)
    }

    var completedTasks: [GoalTask] {
        tasks.filter(\.isCompleted).sorted { lhs, rhs in
            (lhs.completedAt ?? lhs.createdAt) > (rhs.completedAt ?? rhs.createdAt)
        }
    }

    var taskCountLabel: String {
        tasks.count == 1 ? "1 TASK" : "\(tasks.count) TASKS"
    }

    var activeTaskCountLabel: String {
        activeTasks.count == 1 ? "1 TASK" : "\(activeTasks.count) TASKS"
    }

    var sessionCount: Int {
        focusSessions.count
    }

    var totalFocusedDuration: TimeInterval {
        focusSessions.reduce(0) { $0 + $1.focusedDurationSeconds }
    }

    var growthStage: GardenGrowthStage {
        GardenGrowth.stage(for: totalFocusedDuration)
    }

    var progressMetricsLabel: String {
        "\(GardenMetrics.sessionCountLabel(sessionCount))  ·  \(GardenMetrics.focusedDurationLabel(seconds: totalFocusedDuration))"
    }

    var progressAccessibilityLabel: String {
        "\(title). \(area.title). \(GardenMetrics.sessionCountSpoken(sessionCount)). \(GardenMetrics.focusedDurationSpoken(seconds: totalFocusedDuration))"
    }
}

@Model
final class GoalTask {
    var id: UUID
    var title: String
    var durationMinutes: Int
    var energyRequired: EnergyLevel
    var createdAt: Date
    /// Additive V2-M1 fields. Existing V1 rows migrate as active via
    /// the stored default (`false`) and optional `completedAt`.
    var isCompleted: Bool = false
    var completedAt: Date?
    var goal: Goal?

    @Relationship(deleteRule: .nullify, inverse: \FocusSession.task)
    var focusSessions: [FocusSession]

    init(
        id: UUID = UUID(),
        title: String,
        durationMinutes: Int,
        energyRequired: EnergyLevel,
        createdAt: Date = Date(),
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        goal: Goal? = nil,
        focusSessions: [FocusSession] = []
    ) {
        self.id = id
        self.title = title
        self.durationMinutes = durationMinutes
        self.energyRequired = energyRequired
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.goal = goal
        self.focusSessions = focusSessions
    }

    var isActive: Bool {
        !isCompleted
    }

    func complete(at date: Date = Date()) {
        isCompleted = true
        completedAt = date
    }

    func reopen() {
        isCompleted = false
        completedAt = nil
    }

    var asTaskItem: TaskItem {
        TaskItem(
            id: id,
            goalID: goal?.id,
            title: title,
            durationMinutes: durationMinutes,
            energyRequired: energyRequired,
            area: goal?.area.title ?? "",
            goal: goal?.title ?? ""
        )
    }
}

extension Collection where Element == GoalTask {
    var recommendationItems: [TaskItem] {
        filter(\.isActive).map(\.asTaskItem)
    }
}
