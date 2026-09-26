//
//  Persistence.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation
import SwiftData

enum NextPersistence {
    static let schema = Schema([Goal.self, GoalTask.self, FocusSession.self])
    static let seedArgument = "UITEST_SEED_GARDEN"
    static let growthSeedArgument = "UITEST_SEED_GROWTH"
    static let inMemoryArgument = "UITEST_IN_MEMORY"
    static let storeURLArgument = "UITEST_STORE_URL"

    static func makeContainer() throws -> ModelContainer {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains(seedArgument)
            || arguments.contains(growthSeedArgument)
            || arguments.contains(inMemoryArgument) {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            if arguments.contains(seedArgument) {
                seed(context)
            }
            if arguments.contains(growthSeedArgument) {
                seedGrowthStages(context)
            }
            return container
        }

        if let index = arguments.firstIndex(of: storeURLArgument),
           arguments.indices.contains(index + 1) {
            let url = URL(fileURLWithPath: arguments[index + 1])
            let configuration = ModelConfiguration(schema: schema, url: url)
            return try ModelContainer(for: schema, configurations: [configuration])
        }

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeContainer(storeURL: URL) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func seed(_ context: ModelContext) {
        let mcat = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(mcat)
        context.insert(GoalTask(title: "Review amino acids", durationMinutes: 25, energyRequired: .good, goal: mcat))
        context.insert(GoalTask(title: "Review flashcards", durationMinutes: 15, energyRequired: .low, goal: mcat))

        let personal = Goal(title: "Keep your space organized", area: .personal, priority: .normal)
        context.insert(personal)
        context.insert(GoalTask(title: "Clean your space", durationMinutes: 15, energyRequired: .low, goal: personal))

        let career = Goal(title: "Improve programming", area: .career, priority: .normal)
        context.insert(career)
        context.insert(GoalTask(title: "Coding practice", durationMinutes: 45, energyRequired: .ready, goal: career))

        let creative = Goal(title: "Build something", area: .creative, priority: .normal)
        context.insert(creative)
        context.insert(GoalTask(title: "Work on personal project", durationMinutes: 60, energyRequired: .good, goal: creative))

        try? context.save()
    }

    static func seedGrowthStages(_ context: ModelContext) {
        func plant(_ title: String, minutes: Double) {
            let goal = Goal(title: title, area: .education, priority: .normal)
            context.insert(goal)
            guard minutes > 0 else { return }
            context.insert(
                FocusSession(
                    plannedDurationSeconds: minutes * 60,
                    focusedDurationSeconds: minutes * 60,
                    endedNaturally: true,
                    taskWasFinished: false,
                    goal: goal
                )
            )
        }

        plant("Beginning study", minutes: 0)
        plant("First growth", minutes: 30)
        plant("Young plant", minutes: 120)
        plant("Growing plant", minutes: 300)
        plant("Mature plant", minutes: 600)
        try? context.save()
    }
}
