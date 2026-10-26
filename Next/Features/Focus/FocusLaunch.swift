//
//  FocusLaunch.swift
//  Next
//
//  Shared boundary for recommendation and direct-selection Focus entry.
//  Both paths produce a TaskItem and present the same FocusView.
//

import Foundation

enum FocusLaunch {
    /// Builds the Focus payload from a persisted task. Uses the task's estimated
    /// duration as the Simple Focus starting duration.
    static func taskItem(from task: GoalTask) -> TaskItem? {
        guard task.isActive else { return nil }
        guard task.goal != nil else { return nil }
        return task.asTaskItem
    }

    /// Goals that can appear in Choose a task (any goal the user planted).
    static func selectableGoals(from goals: [Goal]) -> [Goal] {
        goals.sorted { $0.createdAt < $1.createdAt }
    }

    /// Incomplete tasks available for direct Focus on a goal.
    static func selectableTasks(on goal: Goal) -> [GoalTask] {
        goal.activeTasks
    }

    static func hasAnySelectableTasks(in goals: [Goal]) -> Bool {
        goals.contains { !$0.activeTasks.isEmpty }
    }
}

enum HomeFocusEntry: String, Hashable, CaseIterable, Identifiable {
    case helpMeDecide
    case chooseTask

    var id: Self { self }

    var title: String {
        switch self {
        case .helpMeDecide: "Help me decide"
        case .chooseTask: "Choose a task"
        }
    }

    var subtitle: String {
        switch self {
        case .helpMeDecide: "Find something that fits your time and energy."
        case .chooseTask: "Pick exactly what you want to work on."
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .helpMeDecide: "homeHelpMeDecide"
        case .chooseTask: "homeChooseATask"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .helpMeDecide: "Opens guided time and energy recommendations"
        case .chooseTask: "Opens goal and task selection for direct focus"
        }
    }
}
