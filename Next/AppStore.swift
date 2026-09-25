//
//  AppStore.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation
import Observation

@Observable
final class AppStore {
    var goals: [Goal]

    init(goals: [Goal] = []) {
        self.goals = goals
    }

    var allTasks: [TaskItem] {
        goals.flatMap(\.tasks)
    }

    @discardableResult
    func addGoal(title: String, area: GoalArea, priority: GoalPriority) -> Goal {
        let goal = Goal(title: title, area: area, priority: priority)
        goals.append(goal)
        return goal
    }

    @discardableResult
    func addTask(
        to goalID: UUID,
        title: String,
        durationMinutes: Int,
        energyRequired: EnergyLevel
    ) -> TaskItem? {
        guard let index = goals.firstIndex(where: { $0.id == goalID }) else {
            return nil
        }

        let goal = goals[index]
        let task = TaskItem(
            title: title,
            durationMinutes: durationMinutes,
            energyRequired: energyRequired,
            area: goal.area.title,
            goal: goal.title
        )
        goals[index].tasks.append(task)
        return task
    }

    func goal(id: UUID) -> Goal? {
        goals.first(where: { $0.id == id })
    }
}

extension AppStore {
    static let uiTestSeedArgument = "UITEST_SEED_GARDEN"

    static func seededForUITests() -> AppStore {
        let store = AppStore()
        let mcat = store.addGoal(title: "Study for MCAT", area: .education, priority: .high)
        store.addTask(to: mcat.id, title: "Review amino acids", durationMinutes: 25, energyRequired: .good)
        store.addTask(to: mcat.id, title: "Review flashcards", durationMinutes: 15, energyRequired: .low)

        let personal = store.addGoal(title: "Keep your space organized", area: .personal, priority: .normal)
        store.addTask(to: personal.id, title: "Clean your space", durationMinutes: 15, energyRequired: .low)

        let career = store.addGoal(title: "Improve programming", area: .career, priority: .normal)
        store.addTask(to: career.id, title: "Coding practice", durationMinutes: 45, energyRequired: .ready)

        let creative = store.addGoal(title: "Build something", area: .creative, priority: .normal)
        store.addTask(to: creative.id, title: "Work on personal project", durationMinutes: 60, energyRequired: .good)
        return store
    }
}
