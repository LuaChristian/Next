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
    var taskTitleSnapshot: String?
    var goalTitleSnapshot: String?
    var goal: Goal?
    var task: GoalTask?

    init(
        id: UUID = UUID(),
        completedAt: Date = Date(),
        plannedDurationSeconds: Double,
        focusedDurationSeconds: Double,
        endedNaturally: Bool,
        taskWasFinished: Bool,
        taskTitleSnapshot: String? = nil,
        goalTitleSnapshot: String? = nil,
        goal: Goal? = nil,
        task: GoalTask? = nil
    ) {
        self.id = id
        self.completedAt = completedAt
        self.plannedDurationSeconds = plannedDurationSeconds
        self.focusedDurationSeconds = focusedDurationSeconds
        self.endedNaturally = endedNaturally
        self.taskWasFinished = taskWasFinished
        self.taskTitleSnapshot = taskTitleSnapshot
        self.goalTitleSnapshot = goalTitleSnapshot
        self.goal = goal
        self.task = task
    }

    var historyTaskTitle: String {
        if let taskTitleSnapshot, !taskTitleSnapshot.isEmpty { return taskTitleSnapshot }
        return task?.title ?? "Untitled"
    }

    var historyGoalTitle: String {
        if let goalTitleSnapshot, !goalTitleSnapshot.isEmpty { return goalTitleSnapshot }
        return goal?.title ?? ""
    }

    var historyRecord: HistorySessionRecord {
        HistorySessionRecord(
            id: id,
            completedAt: completedAt,
            focusedDurationSeconds: focusedDurationSeconds,
            taskWasFinished: taskWasFinished,
            taskTitle: historyTaskTitle,
            goalTitle: historyGoalTitle
        )
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
        completedAt: Date = Date(),
        experienceID: UUID? = nil
    ) throws -> FocusSession {
        // Exactly-once: recovery uses a stable experienceID as FocusSession.id.
        if let experienceID {
            let existing = try context.fetch(
                FetchDescriptor<FocusSession>(predicate: #Predicate { $0.id == experienceID })
            )
            if let first = existing.first {
                return first
            }
        }

        let taskID = result.task.id
        var goal: Goal?
        if let goalID = result.task.goalID {
            let goals = try context.fetch(FetchDescriptor<Goal>(predicate: #Predicate { $0.id == goalID }))
            goal = goals.first
        }

        let tasks = try context.fetch(FetchDescriptor<GoalTask>(predicate: #Predicate { $0.id == taskID }))
        let task = tasks.first
        if taskWasFinished {
            task?.complete(at: completedAt)
        }

        // Prefer live relationships; fall back to snapshots when the task/goal was deleted.
        // Never attach focus to a different task/goal.
        let session = FocusSession(
            id: experienceID ?? UUID(),
            completedAt: completedAt,
            plannedDurationSeconds: result.plannedDurationSeconds,
            focusedDurationSeconds: result.focusedDurationSeconds,
            endedNaturally: result.endedNaturally,
            taskWasFinished: taskWasFinished,
            taskTitleSnapshot: result.task.title,
            goalTitleSnapshot: result.task.goal,
            goal: goal,
            task: task
        )
        context.insert(session)
        try context.save()
        return session
    }
}
