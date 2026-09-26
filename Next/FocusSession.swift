//
//  FocusSession.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var completedAt: Date
    var plannedDurationSeconds: Double
    var focusedDurationSeconds: Double
    var endedNaturally: Bool
    var taskWasFinished: Bool
    var goal: Goal?
    var task: GoalTask?

    init(
        id: UUID = UUID(),
        completedAt: Date = Date(),
        plannedDurationSeconds: Double,
        focusedDurationSeconds: Double,
        endedNaturally: Bool,
        taskWasFinished: Bool,
        goal: Goal? = nil,
        task: GoalTask? = nil
    ) {
        self.id = id
        self.completedAt = completedAt
        self.plannedDurationSeconds = plannedDurationSeconds
        self.focusedDurationSeconds = focusedDurationSeconds
        self.endedNaturally = endedNaturally
        self.taskWasFinished = taskWasFinished
        self.goal = goal
        self.task = task
    }
}

enum FocusSessionStoreError: Error {
    case missingIdentity
    case goalNotFound
}

enum FocusSessionStore {
    @discardableResult
    static func commit(
        result: FocusSessionResult,
        taskWasFinished: Bool,
        context: ModelContext,
        completedAt: Date = Date()
    ) throws -> FocusSession {
        guard let goalID = result.task.goalID else {
            throw FocusSessionStoreError.missingIdentity
        }

        let taskID = result.task.id
        let goals = try context.fetch(FetchDescriptor<Goal>(predicate: #Predicate { $0.id == goalID }))
        guard let goal = goals.first else {
            throw FocusSessionStoreError.goalNotFound
        }

        let tasks = try context.fetch(FetchDescriptor<GoalTask>(predicate: #Predicate { $0.id == taskID }))
        let session = FocusSession(
            completedAt: completedAt,
            plannedDurationSeconds: result.plannedDurationSeconds,
            focusedDurationSeconds: result.focusedDurationSeconds,
            endedNaturally: result.endedNaturally,
            taskWasFinished: taskWasFinished,
            goal: goal,
            task: tasks.first
        )
        context.insert(session)
        try context.save()
        return session
    }
}
