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
        guard focusedDurationSeconds >= 60 else {
            return "<1 MIN FOCUSED"
        }

        let minutes = Int(focusedDurationSeconds / 60)
        if minutes == 1 {
            return "1 MIN FOCUSED"
        }
        return "\(minutes) MIN FOCUSED"
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
