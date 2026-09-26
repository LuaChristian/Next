//
//  NextTests.swift
//  NextTests
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation
import SwiftData
import Testing
@testable import Next

struct RecommendationEngineTests {
    private let engine = RecommendationEngine()
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let threeDaysAgo = Date(timeIntervalSince1970: 1_800_000_000 - 3 * 24 * 60 * 60)
    private let tenDaysAgo = Date(timeIntervalSince1970: 1_800_000_000 - 10 * 24 * 60 * 60)
    private let twentyMinutesAgo = Date(timeIntervalSince1970: 1_800_000_000 - 20 * 60)

    private func item(
        _ title: String,
        minutes: Int = 30,
        energy: EnergyLevel = .good,
        goal: String,
        priority: GoalPriority = .normal,
        lastFocusedAt: Date? = nil,
        goalID: UUID = UUID()
    ) -> TaskItem {
        TaskItem(
            goalID: goalID,
            title: title,
            durationMinutes: minutes,
            energyRequired: energy,
            area: "Education",
            goal: goal,
            goalPriority: priority,
            lastFocusedAt: lastFocusedAt
        )
    }

    @Test func timeFilterExcludesTasksThatExceedAvailableTime() {
        let coding = item("Coding practice", minutes: 45, energy: .ready, goal: "Improve programming")
        let amino = item("Review amino acids", minutes: 25, goal: "MCAT", priority: .high)
        let result = engine.recommendations(tasks: [coding, amino], availableTime: .thirty, energy: .ready)
        #expect(result.contains(where: { $0.id == coding.id }) == false)
        #expect(result.contains(where: { $0.id == amino.id }))
    }

    @Test func energyFilterExcludesTasksThatRequireMoreEnergy() {
        let coding = item("Coding practice", minutes: 45, energy: .ready, goal: "Improve programming")
        let amino = item("Review amino acids", minutes: 25, goal: "MCAT", priority: .high)
        let result = engine.recommendations(tasks: [coding, amino], availableTime: .sixty, energy: .good)
        #expect(result.contains(where: { $0.id == coding.id }) == false)
        #expect(result.contains(where: { $0.id == amino.id }))
    }

    @Test func lowerEnergyTasksRemainEligible() {
        let clean = item("Clean your space", minutes: 15, energy: .low, goal: "Space")
        let result = engine.recommendations(tasks: [clean], availableTime: .thirty, energy: .good)
        #expect(result.contains(where: { $0.id == clean.id }))
    }

    @Test func betterTimeFitRanksHigherWhenPriorityAndRecencyTie() {
        let flashcards = item("Review flashcards", minutes: 15, energy: .low, goal: "MCAT", priority: .high)
        let amino = item("Review amino acids", minutes: 25, goal: "MCAT", priority: .high)
        let result = engine.recommendations(tasks: [flashcards, amino], availableTime: .thirty, energy: .good)
        #expect(result.map(\.id) == [amino.id, flashcards.id])
    }

    @Test func closerEnergyRanksHigherWhenDurationMatches() {
        let low = item("Low energy match", minutes: 20, energy: .low, goal: "Rest")
        let good = item("Good energy match", minutes: 20, goal: "Study")
        let result = engine.recommendations(tasks: [low, good], availableTime: .thirty, energy: .good)
        #expect(result.map(\.id) == [good.id, low.id])
    }

    @Test func rankingIsDeterministic() {
        let coding = item("Coding practice", minutes: 45, energy: .ready, goal: "Career")
        let flashcards = item("Review flashcards", minutes: 15, energy: .low, goal: "MCAT", priority: .high)
        let amino = item("Review amino acids", minutes: 25, goal: "MCAT", priority: .high)
        let clean = item("Clean your space", minutes: 15, energy: .low, goal: "Space")
        let tasks = [coding, flashcards, amino, clean]
        let first = engine.recommendations(tasks: tasks, availableTime: .thirty, energy: .good)
        let second = engine.recommendations(tasks: tasks, availableTime: .thirty, energy: .good)
        #expect(first.map(\.id) == second.map(\.id))
        #expect(first.map(\.id) == [amino.id, flashcards.id, clean.id])
    }

    @Test func highPriorityRanksAboveNormal() {
        let normal = item("Normal task", goal: "Portfolio", priority: .normal)
        let high = item("High task", minutes: 15, energy: .low, goal: "MCAT", priority: .high)
        let result = engine.recommendations(tasks: [normal, high], availableTime: .thirty, energy: .good)
        #expect(result.map(\.title) == ["High task", "Normal task"])
    }

    @Test func normalPriorityRanksAboveLow() {
        let low = item("Low goal", goal: "Chores", priority: .low)
        let normal = item("Normal goal", minutes: 15, energy: .low, goal: "Portfolio", priority: .normal)
        let result = engine.recommendations(tasks: [low, normal], availableTime: .thirty, energy: .good)
        #expect(result.map(\.title) == ["Normal goal", "Low goal"])
    }

    @Test func priorityOutranksRecency() {
        let recentHigh = item("Recent high", goal: "MCAT", priority: .high, lastFocusedAt: twentyMinutesAgo)
        let staleNormal = item("Stale normal", goal: "Portfolio", priority: .normal, lastFocusedAt: tenDaysAgo)
        let result = engine.recommendations(tasks: [staleNormal, recentHigh], availableTime: .thirty, energy: .good)
        #expect(result.map(\.title) == ["Recent high", "Stale normal"])
    }

    @Test func priorityOutranksBetterDurationFit() {
        let highShort = item("High short", minutes: 15, goal: "MCAT", priority: .high)
        let normalPerfect = item("Normal perfect", minutes: 30, goal: "Portfolio", priority: .normal)
        let result = engine.recommendations(tasks: [normalPerfect, highShort], availableTime: .thirty, energy: .good)
        #expect(result.map(\.title) == ["High short", "Normal perfect"])
    }

    @Test func neverWorkedRanksAbovePreviouslyWorkedWhenPriorityTies() {
        let worked = item("Worked", goal: "Game Development", lastFocusedAt: tenDaysAgo)
        let never = item("Never", goal: "Portfolio")
        let result = engine.recommendations(tasks: [worked, never], availableTime: .thirty, energy: .good)
        #expect(result.map(\.title) == ["Never", "Worked"])
    }

    @Test func olderGoalSessionRanksAboveNewerGoalSession() {
        let newer = item("Newer", goal: "Game Development", lastFocusedAt: twentyMinutesAgo)
        let older = item("Older", goal: "MCAT", lastFocusedAt: threeDaysAgo)
        let result = engine.recommendations(tasks: [newer, older], availableTime: .thirty, energy: .good)
        #expect(result.map(\.title) == ["Older", "Newer"])
    }

    @Test func sameGoalFallsThroughToDurationRanking() {
        let goalID = UUID()
        let short = item("Flashcards", minutes: 15, energy: .low, goal: "MCAT", priority: .high, lastFocusedAt: threeDaysAgo, goalID: goalID)
        let long = item("Amino", minutes: 30, goal: "MCAT", priority: .high, lastFocusedAt: threeDaysAgo, goalID: goalID)
        let result = engine.recommendations(tasks: [short, long], availableTime: .thirty, energy: .good)
        #expect(result.map(\.title) == ["Amino", "Flashcards"])
    }

    @Test func longerFittingDurationRanksFirstWhenPriorityAndRecencyTie() {
        let short = item("Fifteen", minutes: 15, goal: "Portfolio")
        let long = item("Thirty", minutes: 30, goal: "Game Development")
        let result = engine.recommendations(tasks: [short, long], availableTime: .thirty, energy: .good)
        #expect(result.map(\.title) == ["Thirty", "Fifteen"])
    }

    @Test func exactEnergyMatchWinsAfterPreviousTies() {
        let low = item("Low", minutes: 30, energy: .low, goal: "MCAT", priority: .high)
        let good = item("Good", minutes: 30, goal: "MCAT", priority: .high)
        let result = engine.recommendations(tasks: [low, good], availableTime: .thirty, energy: .good)
        #expect(result.map(\.title) == ["Good", "Low"])
    }

    @Test func readyEnergyOrdersExactThenGoodThenLow() {
        let low = item("Low", minutes: 30, energy: .low, goal: "A")
        let good = item("Good", minutes: 30, energy: .good, goal: "B")
        let ready = item("Ready", minutes: 30, energy: .ready, goal: "C")
        let result = engine.recommendations(tasks: [low, good, ready], availableTime: .thirty, energy: .ready)
        #expect(result.map(\.title) == ["Ready", "Good", "Low"])
    }

    @Test func stableOriginalOrderResolvesCompleteTies() {
        let first = item("First", goal: "A")
        let second = item("Second", goal: "B")
        let result = engine.recommendations(tasks: [first, second], availableTime: .thirty, energy: .good)
        #expect(result.map(\.title) == ["First", "Second"])
    }

    @Test func repeatedRankingWithUnchangedInputsIsIdentical() {
        let a = item("A", minutes: 20, goal: "MCAT", priority: .high, lastFocusedAt: threeDaysAgo)
        let b = item("B", goal: "Portfolio")
        let c = item("C", goal: "Game Development", lastFocusedAt: twentyMinutesAgo)
        let tasks = [b, c, a]
        let first = engine.recommendations(tasks: tasks, availableTime: .thirty, energy: .good)
        let second = engine.recommendations(tasks: tasks, availableTime: .thirty, energy: .good)
        #expect(first.map(\.id) == second.map(\.id))
        #expect(first.map(\.title) == ["A", "B", "C"])
    }

    @Test func notThisOneFollowsRankedOrder() {
        let a = item("A", minutes: 20, goal: "MCAT", priority: .high, lastFocusedAt: threeDaysAgo)
        let b = item("B", goal: "Portfolio")
        let c = item("C", goal: "Fitness", priority: .high, lastFocusedAt: now)
        let ranked = engine.recommendations(tasks: [b, c, a], availableTime: .thirty, energy: .good)
        #expect(ranked.map(\.title) == ["A", "C", "B"])
        #expect(ranked.dropFirst().map(\.title) == ["C", "B"])
        #expect(ranked.dropFirst(2).map(\.title) == ["B"])
    }

    @Test func exampleAPriorityThenRecency() {
        let a = item("A", minutes: 20, goal: "MCAT", priority: .high, lastFocusedAt: threeDaysAgo)
        let b = item("B", goal: "Portfolio")
        let c = item("C", goal: "Fitness", priority: .high, lastFocusedAt: now)
        let result = engine.recommendations(tasks: [a, b, c], availableTime: .thirty, energy: .good)
        #expect(result.map(\.title) == ["A", "C", "B"])
    }

    @Test func neverWorkedHighOutranksWorkedHigh() {
        let worked = item("Worked high", goal: "MCAT", priority: .high, lastFocusedAt: tenDaysAgo)
        let never = item("Never high", minutes: 15, energy: .low, goal: "Interview", priority: .high)
        let result = engine.recommendations(tasks: [worked, never], availableTime: .thirty, energy: .good)
        #expect(result.map(\.title) == ["Never high", "Worked high"])
    }

    @Test func recentlyWorkedHighOutranksNeverWorkedNormal() {
        let high = item("Recent high", goal: "MCAT", priority: .high, lastFocusedAt: twentyMinutesAgo)
        let neverNormal = item("Never normal", goal: "Portfolio")
        let result = engine.recommendations(tasks: [neverNormal, high], availableTime: .thirty, energy: .good)
        #expect(result.map(\.title) == ["Recent high", "Never normal"])
    }

    @Test func ninetyPlusTreatsAvailableTimeAsNinety() {
        let ninety = item("Ninety", minutes: 90, goal: "Deep work")
        let tooLong = item("Too long", minutes: 91, goal: "Marathon")
        let sixty = item("Sixty", minutes: 60, goal: "Studio")
        let result = engine.recommendations(tasks: [tooLong, ninety, sixty], availableTime: .ninetyPlus, energy: .ready)
        #expect(result.map(\.title) == ["Ninety", "Sixty"])
        #expect(TimeOption.ninetyPlus.minutes == 90)
    }

    @Test func emptyEligibleSetIsSafe() {
        let long = item("Long", minutes: 60, energy: .ready, goal: "Career")
        let result = engine.recommendations(tasks: [long], availableTime: .fifteen, energy: .low)
        #expect(result.isEmpty)
    }

    @Test func explanationMentionsHighPriorityAndRecency() {
        let task = item("Review amino acids", minutes: 20, goal: "MCAT", priority: .high, lastFocusedAt: threeDaysAgo)
        let explanation = engine.explanation(for: task, availableTime: .thirty, energy: .good)
        #expect(explanation.lines[0] == "Fits your 30 minutes and Good energy.")
        #expect(explanation.lines[1] == "MCAT is a high-priority goal you haven't worked on recently.")
    }

    @Test func explanationMentionsNeverWorkedGoal() {
        let task = item("Update project description", goal: "Portfolio")
        let explanation = engine.explanation(for: task, availableTime: .fifteen, energy: .low)
        #expect(explanation.lines[0] == "Fits your 15 minutes and Low energy.")
        #expect(explanation.lines[1] == "You haven't worked on Portfolio yet.")
    }

    @Test func explanationMentionsHighPriorityNeverWorked() {
        let task = item("Review amino acids", goal: "MCAT", priority: .high)
        let explanation = engine.explanation(for: task, availableTime: .thirty, energy: .good)
        #expect(explanation.lines[1] == "MCAT is a high-priority goal you haven't worked on yet.")
    }
}

struct RecommendationEnginePersistenceTests {
    private let engine = RecommendationEngine()

    @MainActor
    private func makeContext() throws -> ModelContext {
        ModelContext(try NextPersistence.makeInMemoryContainer())
    }

    @MainActor
    private func recommend(from context: ModelContext, time: TimeOption = .thirty, energy: EnergyLevel = .good) throws -> [TaskItem] {
        engine.recommendations(
            tasks: try context.fetch(FetchDescriptor<GoalTask>()).recommendationItems,
            availableTime: time,
            energy: energy
        )
    }

    @MainActor
    @Test func completedTasksRemainExcluded() throws {
        let context = try makeContext()
        let goal = Goal(title: "MCAT", area: .education, priority: .high)
        context.insert(goal)
        let done = GoalTask(title: "Done", durationMinutes: 30, energyRequired: .good, isCompleted: true, completedAt: Date(), goal: goal)
        let active = GoalTask(title: "Active", durationMinutes: 15, energyRequired: .low, goal: goal)
        context.insert(done)
        context.insert(active)
        try context.save()

        let result = try recommend(from: context)
        #expect(result.map(\.title) == ["Active"])
    }

    @MainActor
    @Test func yesFocusSessionAffectsRecency() throws {
        let context = try makeContext()
        let mcat = Goal(title: "MCAT", area: .education, priority: .high)
        let portfolio = Goal(title: "Portfolio", area: .career, priority: .high)
        context.insert(mcat)
        context.insert(portfolio)
        let amino = GoalTask(title: "Amino", durationMinutes: 30, energyRequired: .good, goal: mcat)
        let page = GoalTask(title: "Page", durationMinutes: 30, energyRequired: .good, goal: portfolio)
        context.insert(amino)
        context.insert(page)
        try context.save()

        try FocusSessionStore.commit(
            result: FocusSessionResult(task: amino.asTaskItem, plannedDurationSeconds: 30 * 60, focusedDurationSeconds: 30 * 60, endedNaturally: true),
            taskWasFinished: true,
            context: context,
            completedAt: Date()
        )
        amino.reopen()
        try context.save()

        let result = try recommend(from: context)
        #expect(result.map(\.title) == ["Page", "Amino"])
        #expect(mcat.lastFocusedAt != nil)
        #expect(portfolio.lastFocusedAt == nil)
    }

    @MainActor
    @Test func notYetFocusSessionAlsoAffectsRecency() throws {
        let context = try makeContext()
        let mcat = Goal(title: "MCAT", area: .education, priority: .high)
        let portfolio = Goal(title: "Portfolio", area: .career, priority: .high)
        context.insert(mcat)
        context.insert(portfolio)
        let amino = GoalTask(title: "Amino", durationMinutes: 30, energyRequired: .good, goal: mcat)
        let page = GoalTask(title: "Page", durationMinutes: 30, energyRequired: .good, goal: portfolio)
        context.insert(amino)
        context.insert(page)
        try context.save()

        try FocusSessionStore.commit(
            result: FocusSessionResult(task: amino.asTaskItem, plannedDurationSeconds: 30 * 60, focusedDurationSeconds: 20 * 60, endedNaturally: false),
            taskWasFinished: false,
            context: context,
            completedAt: Date()
        )

        #expect(amino.isCompleted == false)
        let result = try recommend(from: context)
        #expect(result.map(\.title) == ["Page", "Amino"])
    }

    @MainActor
    @Test func goalWithMultipleSessionsUsesMostRecent() throws {
        let context = try makeContext()
        let olderGoal = Goal(title: "Older", area: .education, priority: .normal)
        let newerGoal = Goal(title: "Newer", area: .creative, priority: .normal)
        context.insert(olderGoal)
        context.insert(newerGoal)
        let olderTask = GoalTask(title: "Older task", durationMinutes: 30, energyRequired: .good, goal: olderGoal)
        let newerTask = GoalTask(title: "Newer task", durationMinutes: 30, energyRequired: .good, goal: newerGoal)
        context.insert(olderTask)
        context.insert(newerTask)

        let oldest = Date(timeIntervalSince1970: 1_000_000)
        let middle = Date(timeIntervalSince1970: 2_000_000)
        let newest = Date(timeIntervalSince1970: 3_000_000)

        context.insert(FocusSession(completedAt: oldest, plannedDurationSeconds: 30 * 60, focusedDurationSeconds: 30 * 60, endedNaturally: true, taskWasFinished: false, goal: newerGoal, task: newerTask))
        context.insert(FocusSession(completedAt: newest, plannedDurationSeconds: 30 * 60, focusedDurationSeconds: 30 * 60, endedNaturally: true, taskWasFinished: true, goal: newerGoal, task: newerTask))
        context.insert(FocusSession(completedAt: middle, plannedDurationSeconds: 30 * 60, focusedDurationSeconds: 30 * 60, endedNaturally: true, taskWasFinished: false, goal: olderGoal, task: olderTask))
        try context.save()

        #expect(newerGoal.lastFocusedAt == newest)
        #expect(olderGoal.lastFocusedAt == middle)
        let result = try recommend(from: context)
        #expect(result.map(\.title) == ["Older task", "Newer task"])
    }

    @MainActor
    @Test func reopenedTaskBecomesEligible() throws {
        let context = try makeContext()
        let goal = Goal(title: "MCAT", area: .education, priority: .high)
        context.insert(goal)
        let task = GoalTask(title: "Amino", durationMinutes: 30, energyRequired: .good, isCompleted: true, completedAt: Date(), goal: goal)
        context.insert(task)
        try context.save()
        #expect(try recommend(from: context).isEmpty)

        task.reopen()
        try context.save()
        #expect(try recommend(from: context).map(\.title) == ["Amino"])
    }

    @MainActor
    @Test func rankingDoesNotMutatePersistedData() throws {
        let context = try makeContext()
        let goal = Goal(title: "MCAT", area: .education, priority: .high)
        context.insert(goal)
        let task = GoalTask(title: "Amino", durationMinutes: 30, energyRequired: .good, goal: goal)
        context.insert(task)
        context.insert(
            FocusSession(
                completedAt: Date(timeIntervalSince1970: 1_800_000_000),
                plannedDurationSeconds: 30 * 60,
                focusedDurationSeconds: 30 * 60,
                endedNaturally: true,
                taskWasFinished: false,
                goal: goal,
                task: task
            )
        )
        try context.save()

        let beforeSessions = try context.fetch(FetchDescriptor<FocusSession>()).count
        let beforeRecency = goal.lastFocusedAt
        let beforeCompleted = task.isCompleted
        _ = try recommend(from: context)
        _ = try recommend(from: context)

        #expect(try context.fetch(FetchDescriptor<FocusSession>()).count == beforeSessions)
        #expect(goal.lastFocusedAt == beforeRecency)
        #expect(task.isCompleted == beforeCompleted)
        #expect(goal.totalFocusedDuration == 1_800)
        #expect(goal.growthStage == .sprout)
    }

    @MainActor
    @Test func notThisOneDoesNotMutateGoalRecency() throws {
        let context = try makeContext()
        NextPersistence.seedRecommendationEngine(context)
        let before = Dictionary(
            uniqueKeysWithValues: try context.fetch(FetchDescriptor<Goal>()).map { ($0.title, $0.lastFocusedAt) }
        )
        let ranked = try recommend(from: context)
        #expect(ranked.count == 4)
        _ = ranked.dropFirst()
        let after = Dictionary(
            uniqueKeysWithValues: try context.fetch(FetchDescriptor<Goal>()).map { ($0.title, $0.lastFocusedAt) }
        )
        #expect(before == after)
    }

    @MainActor
    @Test func seededManualScenarioRanksPriorityThenRecencyThenTime() throws {
        let context = try makeContext()
        NextPersistence.seedRecommendationEngine(context)
        let result = try recommend(from: context)
        #expect(result.map(\.title) == [
            "Review amino acids",
            "Practice flashcards",
            "Update project description",
            "Work on movement system"
        ])
    }
}

struct FocusSessionTimerTests {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func initialDurationIsTwentyFiveMinutes() {
        let session = FocusSessionTimer(durationMinutes: 25, startedAt: start)

        #expect(session.remainingSeconds(at: start) == 1500)
        #expect(session.remainingDisplay(at: start) == "25:00")
        #expect(session.phase == .running)
    }

    @Test func runningElapsedTimeUsesTimestamps() {
        var session = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        let now = start.addingTimeInterval(5 * 60)
        session.evaluateCompletion(at: now)

        #expect(session.remainingSeconds(at: now) == 20 * 60)
        #expect(session.phase == .running)
    }

    @Test func pauseFreezesRemainingTime() {
        var session = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        let pauseAt = start.addingTimeInterval(5 * 60)
        session.pause(at: pauseAt)

        let later = pauseAt.addingTimeInterval(5 * 60)

        #expect(session.phase == .paused)
        #expect(session.remainingSeconds(at: later) == 20 * 60)
        #expect(session.remainingDisplay(at: later) == "20:00")
    }

    @Test func resumeExcludesPausedTime() {
        var session = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        session.pause(at: start.addingTimeInterval(5 * 60))
        session.resume(at: start.addingTimeInterval(10 * 60))

        let afterActiveMinute = start.addingTimeInterval(11 * 60)

        #expect(session.phase == .running)
        #expect(session.remainingSeconds(at: afterActiveMinute) == 19 * 60)
        #expect(session.remainingDisplay(at: afterActiveMinute) == "19:00")
    }

    @Test func remainingClampsToZero() {
        var session = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        let afterDuration = start.addingTimeInterval(30 * 60)
        session.evaluateCompletion(at: afterDuration)

        #expect(session.remainingSeconds(at: afterDuration) == 0)
        #expect(session.remainingDisplay(at: afterDuration) == "00:00")
        #expect(session.phase == .ended)
    }

    @Test func finishEarlyEndsAndFreezesCountdown() {
        var session = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        let finishAt = start.addingTimeInterval(6 * 60 + 18)
        session.finish(at: finishAt)

        let later = finishAt.addingTimeInterval(10 * 60)
        session.pause(at: later)
        session.resume(at: later.addingTimeInterval(60))

        #expect(session.phase == .ended)
        #expect(session.remainingSeconds(at: later) == session.remainingSeconds(at: finishAt))
        #expect(session.remainingSeconds(at: later) == 18 * 60 + 42)
    }

    @Test func activeElapsedExcludesPausedTime() {
        var session = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        session.pause(at: start.addingTimeInterval(4 * 60))
        session.resume(at: start.addingTimeInterval(7 * 60))
        session.finish(at: start.addingTimeInterval(9 * 60))

        #expect(session.phase == .ended)
        #expect(session.activeElapsed(at: start.addingTimeInterval(9 * 60)) == 6 * 60)
        #expect(session.activeElapsed(at: start.addingTimeInterval(20 * 60)) == 6 * 60)
    }
}

struct FocusSessionResultTests {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)
    private let amino = TaskItem(
        title: "Review amino acids",
        durationMinutes: 25,
        energyRequired: .good,
        area: "Education",
        goal: "Study for MCAT"
    )

    @Test func naturalCompletionUsesPlannedDuration() {
        var session = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        let end = start.addingTimeInterval(25 * 60)
        session.evaluateCompletion(at: end)

        let result = session.makeResult(for: amino, at: end)

        #expect(result?.task.id == amino.id)
        #expect(result?.plannedDurationSeconds == 1_500.0)
        #expect(result?.focusedDurationSeconds == 1_500.0)
        #expect(result?.endedNaturally == true)
    }

    @Test func earlyFinishUsesActiveElapsedTime() {
        var session = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        let finishAt = start.addingTimeInterval(10 * 60)
        session.finish(at: finishAt)

        let result = session.makeResult(for: amino, at: finishAt)

        #expect(result?.focusedDurationSeconds == 600.0)
        #expect(result?.endedNaturally == false)
    }

    @Test func resultExcludesPausedTime() {
        var session = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        session.pause(at: start.addingTimeInterval(5 * 60))
        session.resume(at: start.addingTimeInterval(8 * 60))
        let finishAt = start.addingTimeInterval(12 * 60)
        session.finish(at: finishAt)

        let result = session.makeResult(for: amino, at: finishAt)

        #expect(result?.focusedDurationSeconds == 540.0)
        #expect(result?.endedNaturally == false)
    }

    @Test func naturalCompletionClampsToPlannedDuration() {
        var session = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        let lateReturn = start.addingTimeInterval(30 * 60)
        session.evaluateCompletion(at: lateReturn)

        let result = session.makeResult(for: amino, at: lateReturn)

        #expect(result?.focusedDurationSeconds == 1_500.0)
        #expect(result?.endedNaturally == true)
    }

    @Test func completionAnswerStartsUnselected() {
        let state = SessionCompletionState()

        #expect(state.taskCompletion == nil)
        #expect(state.canContinue == false)
    }

    @Test func completionSelectionCanBeChanged() {
        var state = SessionCompletionState()
        state.select(.completed)
        #expect(state.taskCompletion == .completed)
        #expect(state.canContinue)

        state.select(.notCompleted)
        #expect(state.taskCompletion == .notCompleted)
        #expect(state.canContinue)
    }

    @Test func focusedDurationLabelUsesMinutes() {
        let underAMinute = FocusSessionResult(
            task: amino,
            plannedDurationSeconds: 25 * 60,
            focusedDurationSeconds: 42,
            endedNaturally: false
        )
        let oneMinute = FocusSessionResult(
            task: amino,
            plannedDurationSeconds: 25 * 60,
            focusedDurationSeconds: 60,
            endedNaturally: false
        )
        let twentyThree = FocusSessionResult(
            task: amino,
            plannedDurationSeconds: 25 * 60,
            focusedDurationSeconds: 23 * 60 + 14,
            endedNaturally: false
        )

        #expect(underAMinute.focusedDurationLabel == "<1 MIN FOCUSED")
        #expect(oneMinute.focusedDurationLabel == "1 MIN FOCUSED")
        #expect(twentyThree.focusedDurationLabel == "23 MIN FOCUSED")
    }
}

struct PersistenceTests {
    private let engine = RecommendationEngine()

    @MainActor
    private func makeContext() throws -> ModelContext {
        let container = try NextPersistence.makeInMemoryContainer()
        return ModelContext(container)
    }

    @MainActor
    @Test func insertGoalPersistsFields() throws {
        let context = try makeContext()
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(goal)
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        #expect(goals.count == 1)
        #expect(goals.first?.title == "Study for MCAT")
        #expect(goals.first?.area == .education)
        #expect(goals.first?.priority == .high)
        #expect(goals.first?.tasks.isEmpty == true)
    }

    @MainActor
    @Test func taskBelongsToOwningGoal() throws {
        let context = try makeContext()
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(goal)
        let task = GoalTask(
            title: "Review amino acids",
            durationMinutes: 30,
            energyRequired: .good,
            goal: goal
        )
        context.insert(task)
        try context.save()

        #expect(goal.tasks.count == 1)
        #expect(task.goal?.id == goal.id)
        #expect(task.goal?.title == "Study for MCAT")
        #expect(task.asTaskItem.area == "Education")
        #expect(task.asTaskItem.goal == "Study for MCAT")
    }

    @MainActor
    @Test func taskDoesNotAppearOnADifferentGoal() throws {
        let context = try makeContext()
        let mcat = Goal(title: "Study for MCAT", area: .education, priority: .high)
        let next = Goal(title: "Build Next", area: .creative, priority: .normal)
        context.insert(mcat)
        context.insert(next)
        context.insert(
            GoalTask(
                title: "Review amino acids",
                durationMinutes: 30,
                energyRequired: .good,
                goal: mcat
            )
        )
        try context.save()

        #expect(mcat.tasks.count == 1)
        #expect(next.tasks.isEmpty)
        #expect(try context.fetch(FetchDescriptor<GoalTask>()).count == 1)
    }

    @MainActor
    @Test func persistedTaskCanBeRecommendedWithDerivedContext() throws {
        let context = try makeContext()
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(goal)
        context.insert(
            GoalTask(
                title: "Review amino acids",
                durationMinutes: 30,
                energyRequired: .good,
                goal: goal
            )
        )
        try context.save()

        let candidates = try context.fetch(FetchDescriptor<GoalTask>()).map(\.asTaskItem)
        let result = engine.recommendations(
            tasks: candidates,
            availableTime: .thirty,
            energy: .good
        )

        #expect(result.count == 1)
        #expect(result.first?.title == "Review amino acids")
        #expect(result.first?.area == "Education")
        #expect(result.first?.goal == "Study for MCAT")
    }

    @MainActor
    @Test func persistedTaskStillRespectsTimeFilter() throws {
        let context = try makeContext()
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(goal)
        context.insert(
            GoalTask(
                title: "Practice biology questions",
                durationMinutes: 45,
                energyRequired: .good,
                goal: goal
            )
        )
        try context.save()

        let result = engine.recommendations(
            tasks: try context.fetch(FetchDescriptor<GoalTask>()).map(\.asTaskItem),
            availableTime: .thirty,
            energy: .good
        )

        #expect(result.isEmpty)
    }

    @MainActor
    @Test func persistedTaskStillRespectsEnergyFilter() throws {
        let context = try makeContext()
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(goal)
        context.insert(
            GoalTask(
                title: "Practice biology questions",
                durationMinutes: 30,
                energyRequired: .ready,
                goal: goal
            )
        )
        try context.save()

        let result = engine.recommendations(
            tasks: try context.fetch(FetchDescriptor<GoalTask>()).map(\.asTaskItem),
            availableTime: .thirty,
            energy: .good
        )

        #expect(result.isEmpty)
    }

    @MainActor
    @Test func goalAndTaskSurviveContainerRecreation() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-m6-\(UUID().uuidString).store")

        do {
            let container = try NextPersistence.makeContainer(storeURL: storeURL)
            let context = ModelContext(container)
            let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
            context.insert(goal)
            context.insert(
                GoalTask(
                    title: "Review amino acids",
                    durationMinutes: 30,
                    energyRequired: .good,
                    goal: goal
                )
            )
            try context.save()
        }

        let reopened = try NextPersistence.makeContainer(storeURL: storeURL)
        let context = ModelContext(reopened)
        let goals = try context.fetch(FetchDescriptor<Goal>())
        let tasks = try context.fetch(FetchDescriptor<GoalTask>())

        #expect(goals.count == 1)
        #expect(goals.first?.title == "Study for MCAT")
        #expect(goals.first?.area == .education)
        #expect(tasks.count == 1)
        #expect(tasks.first?.title == "Review amino acids")
        #expect(tasks.first?.goal?.title == "Study for MCAT")
        #expect(tasks.first?.asTaskItem.area == "Education")
        #expect(tasks.first?.isCompleted == false)
        #expect(tasks.first?.completedAt == nil)
    }
}

struct OnboardingTests {
    private func makeDefaults() -> UserDefaults {
        let name = "next.onboarding.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func suggestedGoalsMapToCorrectAreas() {
        #expect(OnboardingGoalSuggestion.suggestion(titled: "Study for an exam")?.area == .education)
        #expect(OnboardingGoalSuggestion.suggestion(titled: "Build strength")?.area == .fitness)
    }

    @Test func multipleAreasCanBeSelected() {
        var state = OnboardingState()
        state.toggleArea(.education)
        state.toggleArea(.fitness)

        #expect(state.selectedAreas == [.education, .fitness])
        #expect(state.canContinueFromAreas)
    }

    @Test func removingAnAreaClearsItsPendingGoals() {
        var state = OnboardingState()
        state.toggleArea(.education)
        state.toggleSuggestion(OnboardingGoalSuggestion.suggestion(titled: "Study for an exam")!)

        #expect(state.pendingGoals.contains { $0.title == "Study for an exam" })

        state.toggleArea(.education)

        #expect(state.selectedAreas.isEmpty)
        #expect(state.pendingGoals.isEmpty)
        #expect(!state.canContinueFromGoals)
    }

    @Test func customGoalStaysPendingWithSelectedArea() {
        var state = OnboardingState()
        state.toggleArea(.education)
        state.toggleArea(.creative)
        state.addCustomGoal(title: "Learn iOS development", area: .creative)

        #expect(state.pendingGoals.count == 1)
        #expect(state.pendingGoals.first?.title == "Learn iOS development")
        #expect(state.pendingGoals.first?.area == .creative)
    }

    @MainActor
    @Test func completionPersistsGoalsWithoutTasks() throws {
        var state = OnboardingState()
        state.toggleArea(.education)
        state.toggleArea(.fitness)
        state.toggleSuggestion(OnboardingGoalSuggestion.suggestion(titled: "Study for an exam")!)
        state.toggleSuggestion(OnboardingGoalSuggestion.suggestion(titled: "Build strength")!)

        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let defaults = makeDefaults()
        state.complete(into: context, defaults: defaults)

        let goals = try context.fetch(FetchDescriptor<Goal>())
        #expect(goals.count == 2)
        #expect(goals.contains { $0.title == "Study for an exam" && $0.area == .education })
        #expect(goals.contains { $0.title == "Build strength" && $0.area == .fitness })
        #expect(goals.allSatisfy { $0.priority == .normal })
        #expect(goals.allSatisfy { $0.tasks.isEmpty })
        #expect(OnboardingPreference.isCompleted(in: defaults))
    }

    @MainActor
    @Test func customGoalPersistsWithNormalPriority() throws {
        var state = OnboardingState()
        state.toggleArea(.education)
        state.toggleArea(.creative)
        state.addCustomGoal(title: "Learn iOS development", area: .creative)

        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        state.complete(into: context, defaults: makeDefaults())

        let goals = try context.fetch(FetchDescriptor<Goal>())
        #expect(goals.count == 1)
        #expect(goals.first?.title == "Learn iOS development")
        #expect(goals.first?.area == .creative)
        #expect(goals.first?.priority == .normal)
        #expect(goals.first?.tasks.isEmpty == true)
    }

    @Test func skipCompletesOnboardingWithoutGoals() {
        var state = OnboardingState()
        let defaults = makeDefaults()
        state.skip(defaults: defaults)

        #expect(state.didCommit)
        #expect(state.pendingGoals.isEmpty)
        #expect(OnboardingPreference.isCompleted(in: defaults))
    }

    @MainActor
    @Test func existingGardenWithoutFlagSkipsOnboarding() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let existing = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(existing)
        try context.save()

        let defaults = makeDefaults()
        #expect(defaults.object(forKey: OnboardingPreference.completedKey) == nil)

        let completed = OnboardingPreference.resolveCompleted(
            goalsExist: true,
            arguments: [],
            defaults: defaults
        )

        #expect(completed)
        #expect(OnboardingPreference.isCompleted(in: defaults))
        #expect(existing.title == "Study for MCAT")
        #expect(try context.fetch(FetchDescriptor<Goal>()).count == 1)
    }

    @Test func completedFlagPreventsOnboardingOnRelaunch() {
        let defaults = makeDefaults()
        OnboardingPreference.markCompleted(in: defaults)

        let completed = OnboardingPreference.resolveCompleted(
            goalsExist: false,
            arguments: [],
            defaults: defaults
        )

        #expect(completed)
    }

    @MainActor
    @Test func completingOnboardingTwiceDoesNotDuplicateGoals() throws {
        var state = OnboardingState()
        state.toggleArea(.education)
        state.toggleSuggestion(OnboardingGoalSuggestion.suggestion(titled: "Study for an exam")!)

        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let defaults = makeDefaults()
        state.complete(into: context, defaults: defaults)
        state.complete(into: context, defaults: defaults)

        #expect(try context.fetch(FetchDescriptor<Goal>()).count == 1)
    }
}

struct GardenGrowthTests {
    @Test func stageZeroBelowThirtyMinutes() {
        #expect(GardenGrowth.stage(for: 0) == .seedling)
        #expect(GardenGrowth.stage(for: 29 * 60) == .seedling)
    }

    @Test func stageOneFromThirtyMinutes() {
        #expect(GardenGrowth.stage(for: 30 * 60) == .sprout)
        #expect(GardenGrowth.stage(for: 119 * 60) == .sprout)
    }

    @Test func stageTwoFromTwoHours() {
        #expect(GardenGrowth.stage(for: 120 * 60) == .young)
        #expect(GardenGrowth.stage(for: 299 * 60) == .young)
    }

    @Test func stageThreeFromFiveHours() {
        #expect(GardenGrowth.stage(for: 300 * 60) == .growing)
        #expect(GardenGrowth.stage(for: 599 * 60) == .growing)
    }

    @Test func stageFourFromTenHours() {
        #expect(GardenGrowth.stage(for: 600 * 60) == .mature)
        #expect(GardenGrowth.stage(for: 1000 * 60) == .mature)
    }
}

struct GardenMetricsTests {
    @Test func focusedDurationFormatting() {
        #expect(GardenMetrics.durationText(seconds: 0) == "0 MIN")
        #expect(GardenMetrics.durationText(seconds: 20) == "<1 MIN")
        #expect(GardenMetrics.durationText(seconds: 18 * 60) == "18 MIN")
        #expect(GardenMetrics.durationText(seconds: 85 * 60) == "1H 25M")
        #expect(GardenMetrics.durationText(seconds: 120 * 60) == "2H")
        #expect(GardenMetrics.focusedDurationLabel(seconds: 0) == "0 MIN FOCUSED")
        #expect(GardenMetrics.focusedDurationLabel(seconds: 20) == "<1 MIN FOCUSED")
        #expect(GardenMetrics.focusedDurationLabel(seconds: 18 * 60) == "18 MIN FOCUSED")
        #expect(GardenMetrics.focusedDurationLabel(seconds: 85 * 60) == "1H 25M FOCUSED")
        #expect(GardenMetrics.focusedDurationLabel(seconds: 120 * 60) == "2H FOCUSED")
    }

    @Test func sessionCountGrammar() {
        #expect(GardenMetrics.sessionCountLabel(0) == "0 SESSIONS")
        #expect(GardenMetrics.sessionCountLabel(1) == "1 SESSION")
        #expect(GardenMetrics.sessionCountLabel(2) == "2 SESSIONS")
    }
}

struct FocusSessionPersistenceTests {
    @MainActor
    private func makeContext() throws -> ModelContext {
        ModelContext(try NextPersistence.makeInMemoryContainer())
    }

    @MainActor
    private func plantMCAT(in context: ModelContext) throws -> (Goal, GoalTask) {
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(goal)
        let task = GoalTask(
            title: "Review amino acids",
            durationMinutes: 30,
            energyRequired: .good,
            goal: goal
        )
        context.insert(task)
        try context.save()
        return (goal, task)
    }

    private func result(
        for task: GoalTask,
        focused: TimeInterval,
        planned: TimeInterval = 30 * 60,
        endedNaturally: Bool
    ) -> FocusSessionResult {
        FocusSessionResult(
            task: task.asTaskItem,
            plannedDurationSeconds: planned,
            focusedDurationSeconds: focused,
            endedNaturally: endedNaturally
        )
    }

    @MainActor
    @Test func completedSessionBelongsToGoal() throws {
        let context = try makeContext()
        let (goal, task) = try plantMCAT(in: context)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 18 * 60, endedNaturally: false),
            taskWasFinished: false,
            context: context
        )

        #expect(goal.sessionCount == 1)
        #expect(goal.focusSessions.first?.task?.id == task.id)
        #expect(goal.focusSessions.first?.goal?.id == goal.id)
    }

    @MainActor
    @Test func actualFocusedDurationIsPersisted() throws {
        let context = try makeContext()
        let (goal, task) = try plantMCAT(in: context)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 18 * 60.0, endedNaturally: false),
            taskWasFinished: false,
            context: context
        )

        #expect(goal.focusSessions.first?.focusedDurationSeconds == 1_080.0)
        #expect(goal.totalFocusedDuration == 1_080.0)
        #expect(goal.growthStage == .seedling)
    }

    @MainActor
    @Test func naturalCompletionPersistsEndedNaturally() throws {
        let context = try makeContext()
        let (_, task) = try plantMCAT(in: context)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 30 * 60, endedNaturally: true),
            taskWasFinished: true,
            context: context
        )

        #expect(try context.fetch(FetchDescriptor<FocusSession>()).first?.endedNaturally == true)
    }

    @MainActor
    @Test func finishEarlyPersistsActualElapsedDuration() throws {
        let context = try makeContext()
        let (goal, task) = try plantMCAT(in: context)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 18 * 60.0, endedNaturally: false),
            taskWasFinished: false,
            context: context
        )

        let session = try context.fetch(FetchDescriptor<FocusSession>()).first
        #expect(session?.endedNaturally == false)
        #expect(session?.focusedDurationSeconds == 1_080.0)
        #expect(goal.sessionCount == 1)
    }

    @MainActor
    @Test func notYetStillCountsFocusedWork() throws {
        let context = try makeContext()
        let (goal, task) = try plantMCAT(in: context)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 25 * 60.0, endedNaturally: false),
            taskWasFinished: false,
            context: context
        )

        #expect(goal.sessionCount == 1)
        #expect(goal.totalFocusedDuration == 1_500.0)
        #expect(goal.focusSessions.first?.taskWasFinished == false)
        #expect(task.tasksAreUnchanged)
        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
    }

    @MainActor
    @Test func yesCompletesTheTaskOnce() throws {
        let context = try makeContext()
        let (goal, task) = try plantMCAT(in: context)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 30 * 60, endedNaturally: true),
            taskWasFinished: true,
            context: context
        )

        #expect(goal.sessionCount == 1)
        #expect(goal.totalFocusedDuration == 1_800.0)
        #expect(goal.focusSessions.first?.taskWasFinished == true)
        #expect(try context.fetch(FetchDescriptor<GoalTask>()).count == 1)
        #expect(task.title == "Review amino acids")
        #expect(task.isCompleted)
        #expect(task.completedAt != nil)
    }

    @MainActor
    @Test func changingAnswerDoesNotDuplicateSession() throws {
        let context = try makeContext()
        let (goal, task) = try plantMCAT(in: context)
        var completion = SessionCompletionState()
        completion.select(.completed)
        completion.select(.notCompleted)
        completion.select(.completed)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 20 * 60, endedNaturally: false),
            taskWasFinished: completion.taskCompletion == .completed,
            context: context
        )

        #expect(goal.sessionCount == 1)
        #expect(goal.focusSessions.first?.taskWasFinished == true)
    }

    @MainActor
    @Test func goalProgressIsIsolated() throws {
        let context = try makeContext()
        let first = Goal(title: "Goal A", area: .education, priority: .normal)
        let second = Goal(title: "Goal B", area: .fitness, priority: .normal)
        context.insert(first)
        context.insert(second)
        context.insert(
            FocusSession(
                plannedDurationSeconds: 30 * 60,
                focusedDurationSeconds: 30 * 60,
                endedNaturally: true,
                taskWasFinished: false,
                goal: first
            )
        )
        context.insert(
            FocusSession(
                plannedDurationSeconds: 120 * 60,
                focusedDurationSeconds: 120 * 60,
                endedNaturally: true,
                taskWasFinished: false,
                goal: second
            )
        )
        try context.save()

        #expect(first.growthStage == .sprout)
        #expect(second.growthStage == .young)
        #expect(first.totalFocusedDuration == 30 * 60)
        #expect(second.totalFocusedDuration == 120 * 60)
    }

    @MainActor
    @Test func sessionSurvivesContainerRecreation() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-m8-\(UUID().uuidString).store")
        let goalID: UUID
        let taskID: UUID

        do {
            let container = try NextPersistence.makeContainer(storeURL: storeURL)
            let context = ModelContext(container)
            let (goal, task) = try plantMCAT(in: context)
            goalID = goal.id
            taskID = task.id
            try FocusSessionStore.commit(
                result: result(for: task, focused: 25 * 60.0, endedNaturally: false),
                taskWasFinished: false,
                context: context
            )
        }

        let reopened = try NextPersistence.makeContainer(storeURL: storeURL)
        let context = ModelContext(reopened)
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        let goals = try context.fetch(FetchDescriptor<Goal>())

        #expect(sessions.count == 1)
        #expect(sessions.first?.focusedDurationSeconds == 1_500.0)
        #expect(sessions.first?.goal?.id == goalID)
        #expect(sessions.first?.task?.id == taskID)
        #expect(goals.first?.sessionCount == 1)
        #expect(goals.first?.totalFocusedDuration == 1_500.0)
        #expect(goals.first?.growthStage == .seedling)
    }

    @Test func recommendationRankingIgnoresGrowth() {
        let engine = RecommendationEngine()
        let amino = TaskItem(
            title: "Review amino acids",
            durationMinutes: 25,
            energyRequired: .good,
            area: "Education",
            goal: "Study for MCAT"
        )
        let flashcards = TaskItem(
            title: "Review flashcards",
            durationMinutes: 15,
            energyRequired: .low,
            area: "Education",
            goal: "Study for MCAT"
        )

        let first = engine.recommendations(tasks: [flashcards, amino], availableTime: .thirty, energy: .good)
        let second = engine.recommendations(tasks: [flashcards, amino], availableTime: .thirty, energy: .good)
        #expect(first.map(\.id) == [amino.id, flashcards.id])
        #expect(first.map(\.id) == second.map(\.id))
    }
}

struct HistoryPresentationTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }

    /// Friday, 25 September 2026, noon UTC. Week (Monday start) is 21–27 Sep.
    private var now: Date {
        date(2026, 9, 25, 12)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func record(
        title: String = "Review amino acids",
        goal: String = "Study for MCAT",
        minutes: Double,
        finished: Bool,
        at completedAt: Date
    ) -> HistorySessionRecord {
        HistorySessionRecord(
            id: UUID(),
            completedAt: completedAt,
            focusedDurationSeconds: minutes * 60,
            taskWasFinished: finished,
            taskTitle: title,
            goalTitle: goal
        )
    }

    @Test func emptySummaryIsZero() {
        let summary = HistoryPresentation.weeklySummary(sessions: [], calendar: calendar, referenceDate: now)
        #expect(summary == .empty)
    }

    @Test func oneFinishedSessionThisWeek() {
        let summary = HistoryPresentation.weeklySummary(
            sessions: [record(minutes: 30, finished: true, at: now)],
            calendar: calendar,
            referenceDate: now
        )
        #expect(summary.focusedDuration == 1_800)
        #expect(summary.sessionCount == 1)
        #expect(summary.tasksFinished == 1)
    }

    @Test func multipleSessionsAccumulateCorrectly() {
        let sessions = [
            record(minutes: 30, finished: true, at: date(2026, 9, 23, 10)),
            record(minutes: 45, finished: false, at: date(2026, 9, 24, 11)),
            record(minutes: 20, finished: true, at: now)
        ]
        let summary = HistoryPresentation.weeklySummary(sessions: sessions, calendar: calendar, referenceDate: now)
        #expect(summary.focusedDuration == 95 * 60)
        #expect(summary.sessionCount == 3)
        #expect(summary.tasksFinished == 2)
    }

    @Test func lastWeekIsExcludedFromThisWeek() {
        let sessions = [
            record(minutes: 30, finished: true, at: now),
            record(minutes: 120, finished: true, at: date(2026, 9, 18, 10))
        ]
        let summary = HistoryPresentation.weeklySummary(sessions: sessions, calendar: calendar, referenceDate: now)
        #expect(summary.focusedDuration == 1_800)
        #expect(summary.sessionCount == 1)
        #expect(summary.tasksFinished == 1)
    }

    @Test func weekBoundaryUsesCalendarInterval() {
        let sundayNight = date(2026, 9, 20, 23)
        let mondayMorning = date(2026, 9, 21, 1)
        let sessions = [
            record(title: "Last week", minutes: 60, finished: true, at: sundayNight),
            record(title: "This week", minutes: 30, finished: true, at: mondayMorning)
        ]
        let summary = HistoryPresentation.weeklySummary(sessions: sessions, calendar: calendar, referenceDate: now)
        #expect(summary.sessionCount == 1)
        #expect(summary.focusedDuration == 1_800)
    }

    @Test func todayGroupUsesReferenceDate() {
        let sections = HistoryPresentation.daySections(
            sessions: [record(minutes: 30, finished: true, at: now)],
            calendar: calendar,
            referenceDate: now
        )
        #expect(sections.map(\.title) == ["TODAY"])
    }

    @Test func yesterdayGroupUsesReferenceDate() {
        let sections = HistoryPresentation.daySections(
            sessions: [record(minutes: 30, finished: true, at: date(2026, 9, 24, 16))],
            calendar: calendar,
            referenceDate: now
        )
        #expect(sections.map(\.title) == ["YESTERDAY"])
    }

    @Test func olderDateUsesLocalizedHeading() {
        let older = date(2026, 9, 18, 10)
        let sections = HistoryPresentation.daySections(
            sessions: [record(minutes: 30, finished: true, at: older)],
            calendar: calendar,
            referenceDate: now
        )
        #expect(sections.count == 1)
        #expect(sections[0].title == HistoryPresentation.dayTitle(for: older, calendar: calendar, referenceDate: now))
        #expect(sections[0].title != "TODAY")
        #expect(sections[0].title != "YESTERDAY")
    }

    @Test func sameDaySessionsAreNewestFirst() {
        let morning = record(title: "Morning", minutes: 20, finished: false, at: date(2026, 9, 25, 9))
        let midday = record(title: "Midday", minutes: 20, finished: false, at: date(2026, 9, 25, 11))
        let afternoon = record(title: "Afternoon", minutes: 20, finished: false, at: date(2026, 9, 25, 14))
        let sections = HistoryPresentation.daySections(
            sessions: [morning, afternoon, midday],
            calendar: calendar,
            referenceDate: now
        )
        #expect(sections[0].sessions.map(\.taskTitle) == ["Afternoon", "Midday", "Morning"])
    }

    @Test func daySectionsAreNewestDayFirst() {
        let sections = HistoryPresentation.daySections(
            sessions: [
                record(title: "Older", minutes: 20, finished: false, at: date(2026, 9, 18, 10)),
                record(title: "Today", minutes: 20, finished: false, at: now),
                record(title: "Yesterday", minutes: 20, finished: false, at: date(2026, 9, 24, 10))
            ],
            calendar: calendar,
            referenceDate: now
        )
        #expect(sections.map(\.title) == ["TODAY", "YESTERDAY", HistoryPresentation.dayTitle(for: date(2026, 9, 18, 10), calendar: calendar, referenceDate: now)])
    }

    @Test func notYetCountsTimeButNotTasksFinished() {
        let summary = HistoryPresentation.weeklySummary(
            sessions: [record(minutes: 25, finished: false, at: now)],
            calendar: calendar,
            referenceDate: now
        )
        #expect(summary.sessionCount == 1)
        #expect(summary.focusedDuration == 25 * 60)
        #expect(summary.tasksFinished == 0)
    }

    @Test func yesCountsTasksFinished() {
        let summary = HistoryPresentation.weeklySummary(
            sessions: [record(minutes: 30, finished: true, at: now)],
            calendar: calendar,
            referenceDate: now
        )
        #expect(summary.tasksFinished == 1)
        #expect(summary.sessionCount == 1)
    }

    @Test func finishEarlyUsesActualDuration() {
        let early = HistorySessionRecord(
            id: UUID(),
            completedAt: now,
            focusedDurationSeconds: 18 * 60,
            taskWasFinished: false,
            taskTitle: "Review amino acids",
            goalTitle: "Study for MCAT"
        )
        let summary = HistoryPresentation.weeklySummary(sessions: [early], calendar: calendar, referenceDate: now)
        #expect(summary.focusedDuration == 1_080)
        #expect(GardenMetrics.durationText(seconds: early.focusedDurationSeconds) == "18 MIN")
    }

    @MainActor
    @Test func historyRecordsSurviveContainerRecreation() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-m9-\(UUID().uuidString).store")

        do {
            let container = try NextPersistence.makeContainer(storeURL: storeURL)
            let context = ModelContext(container)
            let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
            context.insert(goal)
            let task = GoalTask(title: "Review amino acids", durationMinutes: 30, energyRequired: .good, goal: goal)
            context.insert(task)
            context.insert(
                FocusSession(
                    completedAt: now,
                    plannedDurationSeconds: 30 * 60,
                    focusedDurationSeconds: 18 * 60,
                    endedNaturally: false,
                    taskWasFinished: true,
                    taskTitleSnapshot: "Review amino acids",
                    goalTitleSnapshot: "Study for MCAT",
                    goal: goal,
                    task: task
                )
            )
            try context.save()
        }

        let reopened = try NextPersistence.makeContainer(storeURL: storeURL)
        let context = ModelContext(reopened)
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        let records = sessions.map(\.historyRecord)
        let summary = HistoryPresentation.weeklySummary(sessions: records, calendar: calendar, referenceDate: now)

        #expect(sessions.count == 1)
        #expect(sessions.first?.historyTaskTitle == "Review amino acids")
        #expect(sessions.first?.historyGoalTitle == "Study for MCAT")
        #expect(summary.sessionCount == 1)
        #expect(summary.focusedDuration == 1_080)
        #expect(summary.tasksFinished == 1)
    }

    @MainActor
    @Test func historyDoesNotChangeGardenGrowth() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(goal)
        context.insert(
            FocusSession(
                completedAt: now,
                plannedDurationSeconds: 30 * 60,
                focusedDurationSeconds: 30 * 60,
                endedNaturally: true,
                taskWasFinished: true,
                taskTitleSnapshot: "Review amino acids",
                goalTitleSnapshot: "Study for MCAT",
                goal: goal
            )
        )
        try context.save()

        #expect(goal.sessionCount == 1)
        #expect(goal.totalFocusedDuration == 1_800)
        #expect(goal.growthStage == .sprout)
        #expect(GardenGrowth.stage(for: goal.totalFocusedDuration) == .sprout)
    }
}

struct TaskLifecycleTests {
    private let engine = RecommendationEngine()

    @MainActor
    private func makeContext() throws -> ModelContext {
        ModelContext(try NextPersistence.makeInMemoryContainer())
    }

    @MainActor
    private func plantMCAT(in context: ModelContext) throws -> (Goal, GoalTask) {
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(goal)
        let task = GoalTask(
            title: "Review amino acids",
            durationMinutes: 30,
            energyRequired: .good,
            goal: goal
        )
        context.insert(task)
        try context.save()
        return (goal, task)
    }

    private func result(
        for task: GoalTask,
        focused: TimeInterval,
        planned: TimeInterval = 30 * 60,
        endedNaturally: Bool
    ) -> FocusSessionResult {
        FocusSessionResult(
            task: task.asTaskItem,
            plannedDurationSeconds: planned,
            focusedDurationSeconds: focused,
            endedNaturally: endedNaturally
        )
    }

    @MainActor
    private func recommend(
        from context: ModelContext,
        time: TimeOption = .thirty,
        energy: EnergyLevel = .good
    ) throws -> [TaskItem] {
        engine.recommendations(
            tasks: try context.fetch(FetchDescriptor<GoalTask>()).recommendationItems,
            availableTime: time,
            energy: energy
        )
    }

    @MainActor
    @Test func existingGoalTaskDefaultsToActive() throws {
        let context = try makeContext()
        let (_, task) = try plantMCAT(in: context)

        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
        #expect(task.isActive)
    }

    @MainActor
    @Test func completingATaskSetsCompletedState() throws {
        let context = try makeContext()
        let (_, task) = try plantMCAT(in: context)
        let completedAt = Date(timeIntervalSince1970: 1_800_000_000)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 30 * 60, endedNaturally: true),
            taskWasFinished: true,
            context: context,
            completedAt: completedAt
        )

        #expect(task.isCompleted)
        #expect(task.completedAt == completedAt)
        #expect(task.isActive == false)
    }

    @MainActor
    @Test func notYetLeavesTheTaskActive() throws {
        let context = try makeContext()
        let (_, task) = try plantMCAT(in: context)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 25 * 60, endedNaturally: false),
            taskWasFinished: false,
            context: context
        )

        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
        #expect(task.isActive)
    }

    @MainActor
    @Test func completedTasksAreExcludedFromRecommendationEligibility() throws {
        let context = try makeContext()
        let (goal, amino) = try plantMCAT(in: context)
        let flashcards = GoalTask(
            title: "Review flashcards",
            durationMinutes: 15,
            energyRequired: .low,
            goal: goal
        )
        context.insert(flashcards)
        try context.save()

        try FocusSessionStore.commit(
            result: result(for: amino, focused: 30 * 60, endedNaturally: true),
            taskWasFinished: true,
            context: context
        )

        let result = try recommend(from: context)
        #expect(result.contains(where: { $0.id == amino.id }) == false)
        #expect(result.contains(where: { $0.id == flashcards.id }))
    }

    @MainActor
    @Test func reopenedTasksBecomeRecommendationEligibleAgain() throws {
        let context = try makeContext()
        let (_, task) = try plantMCAT(in: context)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 30 * 60, endedNaturally: true),
            taskWasFinished: true,
            context: context
        )
        #expect(try recommend(from: context).isEmpty)

        task.reopen()
        try context.save()

        let result = try recommend(from: context)
        #expect(result.contains(where: { $0.id == task.id }))
    }

    @MainActor
    @Test func reopeningClearsCompletedAt() throws {
        let context = try makeContext()
        let (_, task) = try plantMCAT(in: context)
        task.complete(at: Date())
        try context.save()
        #expect(task.completedAt != nil)

        task.reopen()
        try context.save()

        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
    }

    @MainActor
    @Test func reopeningDoesNotMutateHistoricalFocusSessions() throws {
        let context = try makeContext()
        let (_, task) = try plantMCAT(in: context)
        let completedAt = Date(timeIntervalSince1970: 1_800_000_000)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 30 * 60, endedNaturally: true),
            taskWasFinished: true,
            context: context,
            completedAt: completedAt
        )

        let session = try context.fetch(FetchDescriptor<FocusSession>()).first
        let sessionID = session?.id
        #expect(session?.taskWasFinished == true)
        #expect(session?.completedAt == completedAt)
        #expect(session?.focusedDurationSeconds == 1_800)

        task.reopen()
        try context.save()

        let unchanged = try context.fetch(FetchDescriptor<FocusSession>()).first
        #expect(unchanged?.id == sessionID)
        #expect(unchanged?.taskWasFinished == true)
        #expect(unchanged?.completedAt == completedAt)
        #expect(unchanged?.focusedDurationSeconds == 1_800)
        #expect(unchanged?.taskTitleSnapshot == "Review amino acids")
    }

    @MainActor
    @Test func completingATaskDoesNotDeleteItsFocusSessions() throws {
        let context = try makeContext()
        let (_, task) = try plantMCAT(in: context)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 18 * 60, endedNaturally: false),
            taskWasFinished: false,
            context: context
        )
        try FocusSessionStore.commit(
            result: result(for: task, focused: 30 * 60, endedNaturally: true),
            taskWasFinished: true,
            context: context
        )

        #expect(try context.fetch(FetchDescriptor<FocusSession>()).count == 2)
        #expect(task.focusSessions.count == 2)
        #expect(try context.fetch(FetchDescriptor<GoalTask>()).count == 1)
    }

    @MainActor
    @Test func focusSessionPersistsExactlyOncePerCommit() throws {
        let context = try makeContext()
        let (goal, task) = try plantMCAT(in: context)
        var completion = SessionCompletionState()
        completion.select(.completed)
        completion.select(.notCompleted)
        completion.select(.completed)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 20 * 60, endedNaturally: false),
            taskWasFinished: completion.taskCompletion == .completed,
            context: context
        )

        #expect(goal.sessionCount == 1)
        #expect(try context.fetch(FetchDescriptor<FocusSession>()).count == 1)
        #expect(task.isCompleted)
    }

    @MainActor
    @Test func taskWasFinishedFollowsYesAndNotYet() throws {
        let context = try makeContext()
        let (goal, first) = try plantMCAT(in: context)
        let second = GoalTask(
            title: "Review flashcards",
            durationMinutes: 15,
            energyRequired: .low,
            goal: goal
        )
        context.insert(second)
        try context.save()

        try FocusSessionStore.commit(
            result: result(for: first, focused: 30 * 60, endedNaturally: true),
            taskWasFinished: true,
            context: context
        )
        try FocusSessionStore.commit(
            result: result(for: second, focused: 15 * 60, planned: 15 * 60, endedNaturally: true),
            taskWasFinished: false,
            context: context
        )

        let sessions = try context.fetch(FetchDescriptor<FocusSession>()).sorted { $0.completedAt < $1.completedAt }
        #expect(sessions.map(\.taskWasFinished) == [true, false])
        #expect(first.isCompleted)
        #expect(second.isCompleted == false)
    }

    @MainActor
    @Test func gardenProgressRemainsDerivedFromFocusSessionTime() throws {
        let context = try makeContext()
        let (goal, task) = try plantMCAT(in: context)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 30 * 60, endedNaturally: true),
            taskWasFinished: true,
            context: context
        )

        #expect(goal.totalFocusedDuration == 1_800)
        #expect(goal.growthStage == .sprout)
        #expect(GardenGrowth.stage(for: goal.totalFocusedDuration) == .sprout)

        task.reopen()
        try context.save()

        #expect(goal.totalFocusedDuration == 1_800)
        #expect(goal.growthStage == .sprout)
        #expect(task.isCompleted == false)
    }

    @MainActor
    @Test func historyTasksFinishedUsesSessionNotCurrentTaskState() throws {
        let context = try makeContext()
        let (_, task) = try plantMCAT(in: context)
        let now = Date()

        try FocusSessionStore.commit(
            result: result(for: task, focused: 30 * 60, endedNaturally: true),
            taskWasFinished: true,
            context: context,
            completedAt: now
        )

        task.reopen()
        try context.save()

        let records = try context.fetch(FetchDescriptor<FocusSession>()).map(\.historyRecord)
        let summary = HistoryPresentation.weeklySummary(sessions: records, referenceDate: now)

        #expect(task.isCompleted == false)
        #expect(summary.tasksFinished == 1)
        #expect(records.first?.taskWasFinished == true)
    }

    @MainActor
    @Test func relaunchPreservesTaskCompletionState() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-v2-m1-\(UUID().uuidString).store")
        let taskID: UUID
        let completedAt = Date(timeIntervalSince1970: 1_800_000_000)

        do {
            let container = try NextPersistence.makeContainer(storeURL: storeURL)
            let context = ModelContext(container)
            let (_, task) = try plantMCAT(in: context)
            taskID = task.id
            try FocusSessionStore.commit(
                result: result(for: task, focused: 30 * 60, endedNaturally: true),
                taskWasFinished: true,
                context: context,
                completedAt: completedAt
            )
        }

        let reopened = try NextPersistence.makeContainer(storeURL: storeURL)
        let context = ModelContext(reopened)
        let tasks = try context.fetch(FetchDescriptor<GoalTask>())
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        let task = tasks.first { $0.id == taskID }

        #expect(tasks.count == 1)
        #expect(task?.isCompleted == true)
        #expect(task?.completedAt == completedAt)
        #expect(sessions.count == 1)
        #expect(sessions.first?.taskWasFinished == true)
        #expect(try recommend(from: context).isEmpty)
    }

    @MainActor
    @Test func goalContainingOnlyCompletedTasksIsHandledCorrectly() throws {
        let context = try makeContext()
        let (goal, task) = try plantMCAT(in: context)

        try FocusSessionStore.commit(
            result: result(for: task, focused: 30 * 60, endedNaturally: true),
            taskWasFinished: true,
            context: context
        )

        #expect(goal.activeTasks.isEmpty)
        #expect(goal.completedTasks.map(\.id) == [task.id])
        #expect(goal.tasks.count == 1)
        #expect(goal.tasks.recommendationItems.isEmpty)
        #expect(try recommend(from: context).isEmpty)
    }

    @MainActor
    @Test func whatsNextCannotRecommendACompletedTask() throws {
        let context = try makeContext()
        let (goal, amino) = try plantMCAT(in: context)
        context.insert(
            GoalTask(
                title: "Review flashcards",
                durationMinutes: 15,
                energyRequired: .low,
                goal: goal
            )
        )
        try context.save()

        try FocusSessionStore.commit(
            result: result(for: amino, focused: 30 * 60, endedNaturally: true),
            taskWasFinished: true,
            context: context
        )

        #expect(amino.isCompleted)
        #expect(try recommend(from: context).contains(where: { $0.title == "Review amino acids" }) == false)
        #expect(try recommend(from: context).contains(where: { $0.title == "Review flashcards" }))
    }
}

struct NextInputTests {
    @Test func trimmedTitleRejectsBlankAndWhitespace() {
        #expect(NextInput.trimmedTitle("") == nil)
        #expect(NextInput.trimmedTitle("     ") == nil)
        #expect(NextInput.trimmedTitle("\n\t") == nil)
    }

    @Test func trimmedTitleKeepsMeaningfulText() {
        #expect(NextInput.trimmedTitle("  Study for MCAT  ") == "Study for MCAT")
    }

    @Test func onboardingRejectsWhitespaceCustomGoal() {
        var state = OnboardingState()
        state.selectedAreas = [.creative]
        state.addCustomGoal(title: "   ", area: .creative)
        #expect(state.customGoals.isEmpty)
        #expect(state.canContinueFromGoals == false)
    }

    @Test func completionUsesSharedHourFormatting() {
        let result = FocusSessionResult(
            task: TaskItem(
                title: "Review amino acids",
                durationMinutes: 90,
                energyRequired: .good,
                area: "Education",
                goal: "Study for MCAT"
            ),
            plannedDurationSeconds: 90 * 60,
            focusedDurationSeconds: 85 * 60,
            endedNaturally: false
        )
        #expect(result.focusedDurationLabel == "1H 25M FOCUSED")
    }
}

private extension GoalTask {
    var tasksAreUnchanged: Bool {
        title == "Review amino acids" && durationMinutes == 30
    }
}
