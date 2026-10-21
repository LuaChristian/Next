//
//  PlanningStore.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/26/26.
//

import Foundation
import SwiftData

enum PlanningStore {
    static func updateGoal(
        _ goal: Goal,
        title: String,
        area: GoalArea,
        priority: GoalPriority,
        botanicalSpecies: BotanicalSpecies? = nil,
        context: ModelContext
    ) throws {
        try updateGoal(
            goal,
            title: title,
            areas: [area],
            priority: priority,
            botanicalSpecies: botanicalSpecies,
            context: context
        )
    }

    static func updateGoal(
        _ goal: Goal,
        title: String,
        areas: [GoalArea],
        priority: GoalPriority,
        botanicalSpecies: BotanicalSpecies? = nil,
        context: ModelContext
    ) throws {
        guard let trimmed = NextInput.trimmedTitle(title) else { return }
        goal.title = trimmed
        goal.areas = areas
        goal.priority = priority
        if let botanicalSpecies {
            goal.botanicalSpecies = botanicalSpecies
        }
        try context.save()
    }

    static func updateTask(
        _ task: GoalTask,
        title: String,
        durationMinutes: Int,
        energyRequired: EnergyLevel,
        context: ModelContext
    ) throws {
        guard let trimmed = NextInput.trimmedTitle(title) else { return }
        task.title = trimmed
        task.durationMinutes = durationMinutes
        task.energyRequired = energyRequired
        try context.save()
    }

    static func deleteTask(_ task: GoalTask, context: ModelContext) throws {
        let taskID = task.id
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        for session in sessions where session.task?.id == taskID {
            session.task = nil
        }
        context.delete(task)
        try context.save()
    }

    static func deleteGoal(_ goal: Goal, context: ModelContext) throws {
        let goalID = goal.id
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        for session in sessions where session.goal?.id == goalID {
            session.goal = nil
            session.task = nil
        }
        context.delete(goal)
        try context.save()
    }

    /// Removes a single FocusSession by stable identity. Does not delete Goal or GoalTask.
    static func deleteFocusSession(_ session: FocusSession, context: ModelContext) throws {
        context.delete(session)
        try context.save()
    }
}
