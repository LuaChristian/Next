//
//  FocusSessionResult.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation

struct FocusSessionResult: Equatable {
    let task: TaskItem
    let plannedDurationSeconds: TimeInterval
    let focusedDurationSeconds: TimeInterval
    let endedNaturally: Bool

    var focusedDurationLabel: String {
        GardenMetrics.focusedDurationLabel(seconds: focusedDurationSeconds)
    }
}

enum TaskCompletionStatus: Equatable {
    case completed
    case notCompleted
}

struct SessionCompletionState: Equatable {
    private(set) var taskCompletion: TaskCompletionStatus?

    var canContinue: Bool {
        taskCompletion != nil
    }

    mutating func select(_ status: TaskCompletionStatus) {
        taskCompletion = status
    }
}
