//
//  Persistence.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation
import SwiftData

enum NextPersistence {
    /// Same model types as V1. V2-M1 adds `GoalTask.isCompleted` (default false)
    /// and `GoalTask.completedAt` (optional). SwiftData applies a lightweight
    /// migration; existing rows remain and default to active.
    static let schema = Schema([Goal.self, GoalTask.self, FocusSession.self])
    static let seedArgument = "UITEST_SEED_GARDEN"
    static let lifecycleSeedArgument = "UITEST_SEED_TASK_LIFECYCLE"
    static let growthSeedArgument = "UITEST_SEED_GROWTH"
    static let historySeedArgument = "UITEST_SEED_HISTORY"
    static let inMemoryArgument = "UITEST_IN_MEMORY"
    static let storeURLArgument = "UITEST_STORE_URL"

    static func makeContainer() throws -> ModelContainer {
        let arguments = ProcessInfo.processInfo.arguments

        if let index = arguments.firstIndex(of: storeURLArgument),
           arguments.indices.contains(index + 1) {
            let url = URL(fileURLWithPath: arguments[index + 1])
            let configuration = ModelConfiguration(schema: schema, url: url)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            if arguments.contains(historySeedArgument) {
                seedHistory(ModelContext(container))
            }
            if arguments.contains(lifecycleSeedArgument) {
                seedTaskLifecycle(ModelContext(container))
            }
            return container
        }

        if arguments.contains(seedArgument)
            || arguments.contains(growthSeedArgument)
            || arguments.contains(historySeedArgument)
            || arguments.contains(lifecycleSeedArgument)
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
            if arguments.contains(historySeedArgument) {
                seedHistory(context)
            }
            if arguments.contains(lifecycleSeedArgument) {
                seedTaskLifecycle(context)
            }
            return container
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

    static func seedHistory(_ context: ModelContext, now: Date = Date(), calendar: Calendar = .current) {
        let mcat = Goal(title: "Study for MCAT", area: .education, priority: .high)
        let next = Goal(title: "Build Next", area: .creative, priority: .normal)
        let interview = Goal(title: "Interview preparation", area: .career, priority: .normal)
        let book = Goal(title: "Finish book", area: .education, priority: .normal)
        [mcat, next, interview, book].forEach(context.insert)

        let amino = GoalTask(title: "Review amino acids", durationMinutes: 30, energyRequired: .good, goal: mcat)
        let build = GoalTask(title: "Build Next", durationMinutes: 45, energyRequired: .good, goal: next)
        let arrays = GoalTask(title: "Practice arrays", durationMinutes: 60, energyRequired: .ready, goal: interview)
        let chapter = GoalTask(title: "Read chapter", durationMinutes: 20, energyRequired: .low, goal: book)
        [amino, build, arrays, chapter].forEach(context.insert)

        func session(
            _ task: GoalTask,
            minutes: Double,
            finished: Bool,
            at date: Date
        ) {
            context.insert(
                FocusSession(
                    completedAt: date,
                    plannedDurationSeconds: minutes * 60,
                    focusedDurationSeconds: minutes * 60,
                    endedNaturally: true,
                    taskWasFinished: finished,
                    taskTitleSnapshot: task.title,
                    goalTitleSnapshot: task.goal?.title ?? "",
                    goal: task.goal,
                    task: task
                )
            )
        }

        let todayMorning = calendar.date(bySettingHour: 9, minute: 15, second: 0, of: now) ?? now
        let todayAfternoon = calendar.date(bySettingHour: 14, minute: 40, second: 0, of: now) ?? now
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let yesterdayAfternoon = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: yesterday) ?? yesterday
        let lastWeek = calendar.date(byAdding: .day, value: -8, to: now) ?? now

        var earlierThisWeek = calendar.date(byAdding: .day, value: -3, to: now) ?? now
        if let week = calendar.dateInterval(of: .weekOfYear, for: now),
           !week.contains(earlierThisWeek) || calendar.isDate(earlierThisWeek, inSameDayAs: now)
            || calendar.isDate(earlierThisWeek, inSameDayAs: yesterday) {
            earlierThisWeek = week.start
        }

        session(amino, minutes: 30, finished: true, at: todayMorning)
        session(build, minutes: 45, finished: false, at: todayAfternoon)
        session(arrays, minutes: 60, finished: true, at: yesterdayAfternoon)
        if let week = calendar.dateInterval(of: .weekOfYear, for: now), week.contains(earlierThisWeek) {
            session(chapter, minutes: 20, finished: true, at: earlierThisWeek)
        }
        session(chapter, minutes: 90, finished: false, at: lastWeek)

        for offset in [9, 10, 12, 14, 16] {
            if let older = calendar.date(byAdding: .day, value: -offset, to: now) {
                session(arrays, minutes: 25, finished: false, at: older)
            }
        }

        try? context.save()
    }

    static func seedTaskLifecycle(_ context: ModelContext, now: Date = Date()) {
        let mcat = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(mcat)
        let amino = GoalTask(
            title: "Review amino acids",
            durationMinutes: 25,
            energyRequired: .good,
            isCompleted: true,
            completedAt: now,
            goal: mcat
        )
        context.insert(amino)
        context.insert(GoalTask(title: "Review flashcards", durationMinutes: 15, energyRequired: .low, goal: mcat))
        context.insert(
            FocusSession(
                completedAt: now,
                plannedDurationSeconds: 25 * 60,
                focusedDurationSeconds: 25 * 60,
                endedNaturally: true,
                taskWasFinished: true,
                taskTitleSnapshot: amino.title,
                goalTitleSnapshot: mcat.title,
                goal: mcat,
                task: amino
            )
        )

        let book = Goal(title: "Finish book", area: .education, priority: .normal)
        context.insert(book)
        context.insert(
            GoalTask(
                title: "Read chapter",
                durationMinutes: 20,
                energyRequired: .low,
                isCompleted: true,
                completedAt: now,
                goal: book
            )
        )

        try? context.save()
    }
}
