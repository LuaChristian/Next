//
//  NextTests.swift
//  NextTests
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation
import SwiftData
import SwiftUI
import Testing
import UIKit
import UserNotifications
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

    @Test func expectedNaturalCompletionMatchesRemainingActiveTime() {
        let session = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        #expect(session.expectedNaturalCompletion(at: start) == start.addingTimeInterval(25 * 60))
        #expect(session.expectedNaturalCompletion(at: start.addingTimeInterval(5 * 60)) == start.addingTimeInterval(25 * 60))
    }

    @Test func expectedNaturalCompletionIsNilWhilePausedOrEnded() {
        var session = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        session.pause(at: start.addingTimeInterval(5 * 60))
        #expect(session.expectedNaturalCompletion(at: start.addingTimeInterval(8 * 60)) == nil)

        session.resume(at: start.addingTimeInterval(10 * 60))
        #expect(session.expectedNaturalCompletion(at: start.addingTimeInterval(10 * 60)) == start.addingTimeInterval(30 * 60))

        session.finish(at: start.addingTimeInterval(12 * 60))
        #expect(session.expectedNaturalCompletion(at: start.addingTimeInterval(12 * 60)) == nil)
    }

    @Test func backgroundRunningTimeStillCounts() {
        var session = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        let afterBackground = start.addingTimeInterval(8 * 60)
        session.evaluateCompletion(at: afterBackground)
        #expect(session.phase == .running)
        #expect(session.activeElapsed(at: afterBackground) == 8 * 60)
    }

    @Test func backgroundPausedTimeStillDoesNotCount() {
        var session = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        session.pause(at: start.addingTimeInterval(3 * 60))
        let later = start.addingTimeInterval(20 * 60)
        session.evaluateCompletion(at: later)
        #expect(session.phase == .paused)
        #expect(session.activeElapsed(at: later) == 3 * 60)
        #expect(session.expectedNaturalCompletion(at: later) == nil)
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

struct PomodoroConfigurationTests {
    @Test func presetsMatchProductDefaults() {
        #expect(PomodoroConfiguration.recommended == PomodoroConfiguration(focusMinutes: 25, breakMinutes: 5, rounds: 4))
        #expect(PomodoroConfiguration.gentleStart == PomodoroConfiguration(focusMinutes: 15, breakMinutes: 5, rounds: 2))
        #expect(PomodoroConfiguration.deepWork == PomodoroConfiguration(focusMinutes: 50, breakMinutes: 10, rounds: 3))
        #expect(PomodoroPreset.recommended.configuration == .recommended)
    }

    @Test func plannedFocusExcludesBreaksBetweenRounds() {
        let config = PomodoroConfiguration(focusMinutes: 25, breakMinutes: 5, rounds: 4)
        #expect(config.plannedFocusSeconds == 25 * 60 * 4)
        #expect(config.plannedBreakSeconds == 5 * 60 * 3)
        #expect(PomodoroConfiguration(focusMinutes: 15, breakMinutes: 5, rounds: 1).plannedBreakSeconds == 0)
    }

    @Test func sanitizationClampsAndSnapsFocusSteps() {
        #expect(PomodoroConfiguration(focusMinutes: 27, breakMinutes: 0, rounds: 99).sanitized()
            == PomodoroConfiguration(focusMinutes: 25, breakMinutes: 1, rounds: 8))
        #expect(PomodoroConfiguration(focusMinutes: 3, breakMinutes: 40, rounds: 0).sanitized()
            == PomodoroConfiguration(focusMinutes: 5, breakMinutes: 30, rounds: 1))
        #expect(PomodoroConfiguration.clampFocus(22) == 20)
        #expect(PomodoroConfiguration.clampFocus(23) == 25)
    }

    @Test func preferenceDefaultsToRecommendedAndPersistsCustom() {
        let defaults = UserDefaults(suiteName: "next.pomodoro-pref-\(UUID().uuidString)")!
        #expect(PomodoroPreference.configuration(in: defaults) == .recommended)

        let custom = PomodoroConfiguration(focusMinutes: 40, breakMinutes: 8, rounds: 3)
        PomodoroPreference.setConfiguration(custom, in: defaults)
        #expect(PomodoroPreference.configuration(in: defaults) == custom)

        defaults.set(27, forKey: PomodoroPreference.focusMinutesKey)
        defaults.set(0, forKey: PomodoroPreference.breakMinutesKey)
        defaults.set(99, forKey: PomodoroPreference.roundsKey)
        #expect(
            PomodoroPreference.configuration(in: defaults)
                == PomodoroConfiguration(focusMinutes: 25, breakMinutes: 1, rounds: 8)
        )
    }

    @Test func preferenceNeverImpliesEnabledMode() {
        let defaults = UserDefaults(suiteName: "next.pomodoro-enabled-\(UUID().uuidString)")!
        PomodoroPreference.setConfiguration(.deepWork, in: defaults)
        #expect(PomodoroPreference.configuration(in: defaults) == .deepWork)
        #expect(defaults.object(forKey: "pomodoro.enabled") == nil)
    }
}

struct PomodoroSessionTimerTests {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)
    private let amino = TaskItem(
        title: "Review amino acids",
        durationMinutes: 25,
        energyRequired: .good,
        area: "Education",
        goal: "Study for MCAT"
    )

    @Test func startsOnFocusRoundOneWithRecommendedPlan() {
        let session = PomodoroSessionTimer(configuration: .recommended, startedAt: start)
        #expect(session.phase == .running)
        #expect(session.currentRound == 1)
        #expect(!session.isOnBreak)
        #expect(session.remainingDisplay(at: start) == "25:00")
        #expect(session.configuration.plannedFocusSeconds == 100 * 60)
    }

    @Test func breakTimeDoesNotCountAsFocused() {
        var session = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 25, breakMinutes: 5, rounds: 2),
            startedAt: start
        )
        session.evaluateCompletion(at: start.addingTimeInterval(25 * 60))
        #expect(session.isOnBreak)
        #expect(session.focusedElapsed(at: start.addingTimeInterval(25 * 60)) == 1_500.0)

        let midBreak = start.addingTimeInterval(28 * 60)
        #expect(session.focusedElapsed(at: midBreak) == 1_500.0)
        #expect(session.totalElapsedIncludingBreaks(at: midBreak) == 1_680.0)
    }

    @Test func multiRoundNaturalCompletionIsOneSessionResult() {
        var session = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 10, breakMinutes: 2, rounds: 2),
            startedAt: start
        )
        // Fast-forward through focus → break → focus
        session.evaluateCompletion(at: start.addingTimeInterval(10 * 60 + 2 * 60 + 10 * 60))
        #expect(session.phase == .ended)
        #expect(session.endedNaturally)

        let result = session.makeResult(for: amino, at: start.addingTimeInterval(22 * 60))
        #expect(result?.plannedDurationSeconds == 1_200.0)
        #expect(result?.focusedDurationSeconds == 1_200.0)
        #expect(result?.endedNaturally == true)
    }

    @Test func earlyFinishOnBreakKeepsOnlyCompletedFocus() {
        var session = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 25, breakMinutes: 5, rounds: 3),
            startedAt: start
        )
        session.evaluateCompletion(at: start.addingTimeInterval(25 * 60))
        #expect(session.isOnBreak)
        session.finish(at: start.addingTimeInterval(27 * 60))

        let result = session.makeResult(for: amino, at: start.addingTimeInterval(27 * 60))
        #expect(result?.focusedDurationSeconds == 1_500.0)
        #expect(result?.endedNaturally == false)
        #expect(result?.plannedDurationSeconds == 4_500.0)
    }

    @Test func pauseDuringFocusExcludesPausedTimeFromFocusAndElapsed() {
        var session = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 25, breakMinutes: 5, rounds: 2),
            startedAt: start
        )
        session.pause(at: start.addingTimeInterval(5 * 60))
        session.resume(at: start.addingTimeInterval(9 * 60))
        session.finish(at: start.addingTimeInterval(14 * 60))

        let result = session.makeResult(for: amino, at: start.addingTimeInterval(14 * 60))
        #expect(result?.focusedDurationSeconds == 600.0)
    }

    @MainActor
    @Test func pomodoroCommitCreatesSingleFocusSession() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(goal)
        let task = GoalTask(title: "Review amino acids", durationMinutes: 25, energyRequired: .good, goal: goal)
        context.insert(task)
        try context.save()

        var session = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 10, breakMinutes: 2, rounds: 2),
            startedAt: start
        )
        session.evaluateCompletion(at: start.addingTimeInterval(22 * 60))
        let result = session.makeResult(for: task.asTaskItem, at: start.addingTimeInterval(22 * 60))!

        _ = try FocusSessionStore.commit(result: result, taskWasFinished: true, context: context)
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.focusedDurationSeconds == 1_200.0)
        #expect(sessions.first?.plannedDurationSeconds == 1_200.0)
    }

    @Test func focusIntervalTransitionsToBreakWithoutCountingBreakAsFocus() {
        // Shortest valid focus step is 5 minutes; clocks are injected.
        var session = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 5, breakMinutes: 1, rounds: 2),
            startedAt: start
        )
        session.evaluateCompletion(at: start.addingTimeInterval(5 * 60))
        #expect(session.isOnBreak)
        #expect(session.currentRound == 1)
        #expect(session.focusedElapsed(at: start.addingTimeInterval(5 * 60)) == 300.0)

        let midBreak = start.addingTimeInterval(5 * 60 + 30)
        #expect(session.isOnBreak)
        #expect(session.focusedElapsed(at: midBreak) == 300.0)
        #expect(session.totalElapsedIncludingBreaks(at: midBreak) == 330.0)
    }

    @Test func breakEndsStartsNextFocusWithAccurateRoundNumber() {
        var session = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 5, breakMinutes: 1, rounds: 3),
            startedAt: start
        )
        session.evaluateCompletion(at: start.addingTimeInterval(6 * 60))
        #expect(!session.isOnBreak)
        #expect(session.currentRound == 2)
        #expect(session.phase == .running)
        #expect(session.focusedElapsed(at: start.addingTimeInterval(6 * 60)) == 300.0)
        #expect(session.remainingDisplay(at: start.addingTimeInterval(6 * 60)) == "05:00")
    }

    @Test func finalFocusRoundCompletesWithoutTrailingBreak() {
        var session = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 5, breakMinutes: 1, rounds: 2),
            startedAt: start
        )
        // focus (5) + break (1) + focus (5) = 11 minutes
        session.evaluateCompletion(at: start.addingTimeInterval(11 * 60))
        #expect(session.phase == .ended)
        #expect(session.endedNaturally)
        #expect(!session.isOnBreak)
        let result = session.makeResult(for: amino, at: start.addingTimeInterval(11 * 60))
        #expect(result?.focusedDurationSeconds == 600.0)
        #expect(result?.plannedDurationSeconds == 600.0)
    }

    @Test func backgroundCatchUpResolvesCorrectSegmentAcrossBoundaries() {
        var session = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 5, breakMinutes: 1, rounds: 3),
            startedAt: start
        )
        // Through focus1 + break + 30s into focus2
        session.evaluateCompletion(at: start.addingTimeInterval(6 * 60 + 30))
        #expect(!session.isOnBreak)
        #expect(session.currentRound == 2)
        #expect(session.phase == .running)
        #expect(session.focusedElapsed(at: start.addingTimeInterval(6 * 60 + 30)) == 330.0)
        #expect(session.remainingSeconds(at: start.addingTimeInterval(6 * 60 + 30)) == 270)
    }

    @Test func backgroundDuringBreakThenPastEndAdvancesToNextFocus() {
        var session = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 5, breakMinutes: 1, rounds: 2),
            startedAt: start
        )
        session.evaluateCompletion(at: start.addingTimeInterval(5 * 60))
        #expect(session.isOnBreak)
        session.evaluateCompletion(at: start.addingTimeInterval(6 * 60 + 10))
        #expect(!session.isOnBreak)
        #expect(session.currentRound == 2)
        #expect(session.focusedElapsed(at: start.addingTimeInterval(6 * 60 + 10)) == 310.0)
    }

    @Test func pauseDuringBreakDoesNotAddFocusAndResumeContinuesBreak() {
        var session = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 5, breakMinutes: 2, rounds: 2),
            startedAt: start
        )
        session.evaluateCompletion(at: start.addingTimeInterval(5 * 60))
        session.pause(at: start.addingTimeInterval(5 * 60 + 30))
        #expect(session.phase == .paused)
        #expect(session.focusedElapsed(at: start.addingTimeInterval(5 * 60 + 200)) == 300.0)

        session.resume(at: start.addingTimeInterval(5 * 60 + 200))
        #expect(session.isOnBreak)
        #expect(session.remainingSeconds(at: start.addingTimeInterval(5 * 60 + 200)) == 90)
    }

    @Test func breakReassuranceNamesNextFocusRound() {
        var session = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 5, breakMinutes: 1, rounds: 3),
            startedAt: start
        )
        session.evaluateCompletion(at: start.addingTimeInterval(5 * 60))
        #expect(session.isOnBreak)
        #expect(session.nextFocusRound == 2)
        #expect(session.breakReassurance.contains("Round 2"))
        #expect(session.focusedElapsed(at: start.addingTimeInterval(5 * 60 + 20)) == 300.0)
    }

    #if DEBUG
    @Test func debugPreviewHelpersJumpWithoutWaitingRealIntervals() {
        var onBreak = PomodoroSessionTimer(configuration: .recommended, startedAt: start)
        onBreak.debugEnterBreakAfterRound1(at: start)
        #expect(onBreak.isOnBreak)
        #expect(onBreak.currentRound == 1)
        #expect(onBreak.focusedElapsed(at: start) == TimeInterval(25 * 60))

        var roundTwo = PomodoroSessionTimer(configuration: .recommended, startedAt: start)
        roundTwo.debugEnterFocusRound2(at: start)
        #expect(!roundTwo.isOnBreak)
        #expect(roundTwo.currentRound == 2)
        #expect(roundTwo.focusedElapsed(at: start) == TimeInterval(25 * 60))
    }
    #endif
}

struct FocusSessionAccountingTests {
    private let amino = TaskItem(
        title: "Review amino acids",
        durationMinutes: 25,
        energyRequired: .good,
        area: "Education",
        goal: "Study for MCAT"
    )

    @Test func bankFocusPreservesPriorAndCurrentWithoutDuplication() {
        let banked = FocusSessionAccounting.bankFocus(currentFocused: 300, previousBank: 120)
        #expect(banked == 420.0)
        let again = FocusSessionAccounting.bankFocus(currentFocused: 60, previousBank: banked)
        #expect(again == 480.0)
    }

    @Test func breakTimeIsNeverBankedBecauseCallerPassesFocusOnly() {
        // Callers pass focusedElapsed (excludes breaks). Banking zero mid-break keeps prior focus.
        let banked = FocusSessionAccounting.bankFocus(currentFocused: 0, previousBank: 600)
        #expect(banked == 600.0)
    }

    @Test func mergeBankedFocusAddsExactlyOnceToResult() {
        let raw = FocusSessionResult(
            task: amino,
            plannedDurationSeconds: 1_500,
            focusedDurationSeconds: 400,
            endedNaturally: false
        )
        let merged = FocusSessionAccounting.mergeBankedFocus(200, into: raw)
        #expect(merged.focusedDurationSeconds == 600.0)
        #expect(merged.plannedDurationSeconds == 1_500.0)
        #expect(merged.endedNaturally == false)
    }

    @Test func modeSwitchConfirmationRequiredOnlyWhenFocusExists() {
        #expect(!FocusSessionAccounting.requiresModeSwitchConfirmation(currentFocused: 0, bankedFocus: 0))
        #expect(FocusSessionAccounting.requiresModeSwitchConfirmation(currentFocused: 1, bankedFocus: 0))
        #expect(FocusSessionAccounting.requiresModeSwitchConfirmation(currentFocused: 0, bankedFocus: 1))
    }

    @Test func displayedAccumulatedFocusSumsBankedAndCurrentWithoutBreaks() {
        #expect(
            FocusSessionAccounting.displayedAccumulatedFocus(banked: 180, currentFocused: 60) == 240.0
        )
        #expect(
            FocusSessionAccounting.displayedAccumulatedFocus(banked: 300, currentFocused: 0) == 300.0
        )
        #expect(
            FocusSessionAccounting.accumulatedFocusLabel(seconds: 600) == "10 MIN FOCUSED"
        )
    }

    @Test func accumulatedFocusVisibilityRules() {
        #expect(!FocusSessionAccounting.shouldShowAccumulatedFocus(banked: 0, isPomodoroActive: false))
        #expect(FocusSessionAccounting.shouldShowAccumulatedFocus(banked: 1, isPomodoroActive: false))
        #expect(FocusSessionAccounting.shouldShowAccumulatedFocus(banked: 0, isPomodoroActive: true))
    }

    @Test func simpleToPomodoroToSimplePreservesTotalFocusInMergedResult() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        var simple = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        let afterSimple = start.addingTimeInterval(180)
        let bankAfterSimple = FocusSessionAccounting.bankFocus(
            currentFocused: simple.activeElapsed(at: afterSimple),
            previousBank: 0
        )
        #expect(bankAfterSimple == 180.0)

        var pomodoro = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 5, breakMinutes: 1, rounds: 2),
            startedAt: afterSimple
        )
        pomodoro.evaluateCompletion(at: afterSimple.addingTimeInterval(5 * 60))
        #expect(pomodoro.isOnBreak)
        let bankAfterPomodoro = FocusSessionAccounting.bankFocus(
            currentFocused: pomodoro.focusedElapsed(at: afterSimple.addingTimeInterval(5 * 60 + 30)),
            previousBank: bankAfterSimple
        )
        #expect(bankAfterPomodoro == 480.0)

        var simpleAgain = FocusSessionTimer(
            durationMinutes: 25,
            startedAt: afterSimple.addingTimeInterval(5 * 60 + 30)
        )
        simpleAgain.finish(at: afterSimple.addingTimeInterval(5 * 60 + 90))
        let raw = simpleAgain.makeResult(for: amino, at: afterSimple.addingTimeInterval(5 * 60 + 90))!
        let merged = FocusSessionAccounting.mergeBankedFocus(bankAfterPomodoro, into: raw)
        #expect(merged.focusedDurationSeconds == 540.0)
    }

    @MainActor
    @Test func mergedPomodoroCommitRecordsSingleSessionWithBankedFocus() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(goal)
        let task = GoalTask(title: "Review amino acids", durationMinutes: 25, energyRequired: .good, goal: goal)
        context.insert(task)
        try context.save()

        let start = Date(timeIntervalSince1970: 1_700_000_000)
        var pomodoro = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 5, breakMinutes: 1, rounds: 2),
            startedAt: start
        )
        pomodoro.evaluateCompletion(at: start.addingTimeInterval(11 * 60))
        let raw = try #require(pomodoro.makeResult(for: task.asTaskItem, at: start.addingTimeInterval(11 * 60)))
        let merged = FocusSessionAccounting.mergeBankedFocus(90, into: raw)

        _ = try FocusSessionStore.commit(result: merged, taskWasFinished: false, context: context)
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.focusedDurationSeconds == 690.0)
        #expect(sessions.first?.taskWasFinished == false)
        #expect(goal.totalFocusedDuration == 690.0)
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
        #expect(Set(goals.map(\.plantVariant)).count == 2)
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

    @Test func spokenNamesAreUnderstandable() {
        #expect(GardenGrowthStage.seedling.spokenName == "Beginning")
        #expect(GardenGrowthStage.sprout.spokenName == "Establishing")
        #expect(GardenGrowthStage.young.spokenName == "Developing")
        #expect(GardenGrowthStage.growing.spokenName == "Flourishing")
        #expect(GardenGrowthStage.mature.spokenName == "Mature")
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

struct GoalTaskManagementTests {
    private let engine = RecommendationEngine()

    @MainActor
    private func makeContext() throws -> ModelContext {
        ModelContext(try NextPersistence.makeInMemoryContainer())
    }

    @MainActor
    private func plant(
        in context: ModelContext,
        title: String = "Study for MCAT",
        area: GoalArea = .education,
        priority: GoalPriority = .high,
        taskTitle: String = "Review amino acids",
        minutes: Int = 30,
        energy: EnergyLevel = .good
    ) throws -> (Goal, GoalTask) {
        let goal = Goal(title: title, area: area, priority: priority)
        context.insert(goal)
        let task = GoalTask(title: taskTitle, durationMinutes: minutes, energyRequired: energy, goal: goal)
        context.insert(task)
        try context.save()
        return (goal, task)
    }

    @MainActor
    private func session(
        for task: GoalTask,
        in context: ModelContext,
        finished: Bool = false,
        at date: Date = Date(timeIntervalSince1970: 1_800_000_000),
        planned: TimeInterval = 30 * 60,
        focused: TimeInterval = 30 * 60,
        taskSnapshot: String? = nil,
        goalSnapshot: String? = nil
    ) throws -> FocusSession {
        let session = FocusSession(
            completedAt: date,
            plannedDurationSeconds: planned,
            focusedDurationSeconds: focused,
            endedNaturally: true,
            taskWasFinished: finished,
            taskTitleSnapshot: taskSnapshot ?? task.title,
            goalTitleSnapshot: goalSnapshot ?? task.goal?.title ?? "",
            goal: task.goal,
            task: task
        )
        context.insert(session)
        try context.save()
        return session
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
    @Test func editGoalTitlePreservesIdentityAndSnapshot() throws {
        let context = try makeContext()
        let (goal, task) = try plant(in: context)
        let goalID = goal.id
        let persisted = try session(for: task, in: context, goalSnapshot: "Study for MCAT")

        try PlanningStore.updateGoal(goal, title: "MCAT prep", area: .education, priority: .high, context: context)

        #expect(goal.id == goalID)
        #expect(goal.title == "MCAT prep")
        #expect(persisted.goalTitleSnapshot == "Study for MCAT")
        #expect(persisted.historyGoalTitle == "Study for MCAT")
        #expect(try context.fetch(FetchDescriptor<FocusSession>()).count == 1)
        #expect(goal.totalFocusedDuration == 1_800)
        #expect(goal.growthStage == .sprout)
    }

    @MainActor
    @Test func editGoalAreaPreservesSessionsAndProgress() throws {
        let context = try makeContext()
        let (goal, task) = try plant(in: context)
        try session(for: task, in: context)

        try PlanningStore.updateGoal(goal, title: goal.title, area: .career, priority: .high, context: context)

        #expect(goal.area == .career)
        #expect(goal.sessionCount == 1)
        #expect(goal.totalFocusedDuration == 1_800)
        #expect(try context.fetch(FetchDescriptor<FocusSession>()).count == 1)
    }

    @MainActor
    @Test func editGoalPriorityChangesRecommendationRanking() throws {
        let context = try makeContext()
        let (mcat, amino) = try plant(in: context)
        let (portfolio, page) = try plant(
            in: context,
            title: "Portfolio",
            area: .career,
            priority: .normal,
            taskTitle: "Update page",
            minutes: 30
        )

        var result = try recommend(from: context)
        #expect(result.map(\.title) == ["Review amino acids", "Update page"])

        try PlanningStore.updateGoal(portfolio, title: portfolio.title, area: .career, priority: .high, context: context)
        try PlanningStore.updateGoal(mcat, title: mcat.title, area: .education, priority: .normal, context: context)

        result = try recommend(from: context)
        #expect(result.map(\.title) == ["Update page", "Review amino acids"])
        #expect(amino.isCompleted == false)
        #expect(page.isCompleted == false)
    }

    @MainActor
    @Test func editTaskTitlePreservesIdentityAndSnapshot() throws {
        let context = try makeContext()
        let (_, task) = try plant(in: context)
        let taskID = task.id
        let persisted = try session(for: task, in: context, taskSnapshot: "Review amino acids")

        try PlanningStore.updateTask(task, title: "Review organic chemistry", durationMinutes: 30, energyRequired: .good, context: context)

        #expect(task.id == taskID)
        #expect(task.title == "Review organic chemistry")
        #expect(persisted.taskTitleSnapshot == "Review amino acids")
        #expect(persisted.historyTaskTitle == "Review amino acids")
        #expect(persisted.plannedDurationSeconds == 1_800)
        #expect(task.goal?.totalFocusedDuration == 1_800)
    }

    @MainActor
    @Test func editActiveTaskDurationAndEnergyChangeEligibility() throws {
        let context = try makeContext()
        let (_, task) = try plant(in: context, minutes: 60, energy: .ready)

        #expect(try recommend(from: context, time: .thirty, energy: .good).isEmpty)

        try PlanningStore.updateTask(task, title: task.title, durationMinutes: 30, energyRequired: .good, context: context)

        #expect(try recommend(from: context, time: .thirty, energy: .good).map(\.title) == ["Review amino acids"])
        #expect(try context.fetch(FetchDescriptor<FocusSession>()).isEmpty)
    }

    @MainActor
    @Test func editingCompletedTaskKeepsCompletionState() throws {
        let context = try makeContext()
        let (_, task) = try plant(in: context)
        let completedAt = Date(timeIntervalSince1970: 1_800_000_000)
        task.complete(at: completedAt)
        try context.save()

        try PlanningStore.updateTask(task, title: "Renamed completed", durationMinutes: 15, energyRequired: .low, context: context)

        #expect(task.isCompleted)
        #expect(task.completedAt == completedAt)
        #expect(try recommend(from: context).isEmpty)
    }

    @MainActor
    @Test func deleteTaskPreservesSessionsAndRecency() throws {
        let context = try makeContext()
        let (goal, task) = try plant(in: context)
        let lastFocused = Date(timeIntervalSince1970: 1_800_000_000)
        let persisted = try session(for: task, in: context, at: lastFocused, taskSnapshot: "Review amino acids")
        let sessionCount = goal.sessionCount
        let focused = goal.totalFocusedDuration
        let recency = goal.lastFocusedAt

        try PlanningStore.deleteTask(task, context: context)

        #expect(try context.fetch(FetchDescriptor<GoalTask>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<FocusSession>()).count == 1)
        #expect(persisted.task == nil)
        #expect(persisted.taskWasFinished == false)
        #expect(persisted.taskTitleSnapshot == "Review amino acids")
        #expect(persisted.historyTaskTitle == "Review amino acids")
        #expect(goal.sessionCount == sessionCount)
        #expect(goal.totalFocusedDuration == focused)
        #expect(goal.lastFocusedAt == recency)
        #expect(try recommend(from: context).isEmpty)
        #expect(try context.fetch(FetchDescriptor<FocusSession>()).count == 1)
    }

    @MainActor
    @Test func deleteGoalPreservesSessionsAndSnapshots() throws {
        let context = try makeContext()
        let (goal, task) = try plant(in: context)
        let persisted = try session(
            for: task,
            in: context,
            taskSnapshot: "Review amino acids",
            goalSnapshot: "Study for MCAT"
        )

        try PlanningStore.deleteGoal(goal, context: context)

        #expect(try context.fetch(FetchDescriptor<Goal>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<GoalTask>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<FocusSession>()).count == 1)
        #expect(persisted.goal == nil)
        #expect(persisted.task == nil)
        #expect(persisted.goalTitleSnapshot == "Study for MCAT")
        #expect(persisted.taskTitleSnapshot == "Review amino acids")
        #expect(persisted.historyGoalTitle == "Study for MCAT")
        #expect(persisted.historyTaskTitle == "Review amino acids")
        #expect(try recommend(from: context).isEmpty)
        #expect(HistoryPresentation.weeklySummary(sessions: [persisted.historyRecord], referenceDate: persisted.completedAt).sessionCount == 1)
    }

    @MainActor
    @Test func deleteGoalDisappearsFromCurrentGoals() throws {
        let context = try makeContext()
        let (goal, task) = try plant(in: context)
        try session(for: task, in: context)
        try PlanningStore.deleteGoal(goal, context: context)
        #expect(try context.fetch(FetchDescriptor<Goal>()).isEmpty)
    }

    @MainActor
    @Test func renameDoesNotChangeHistoricalHistoryTitles() throws {
        let context = try makeContext()
        let (goal, task) = try plant(in: context)
        let persisted = try session(for: task, in: context, taskSnapshot: "Study chemistry", goalSnapshot: "Study for MCAT")

        try PlanningStore.updateTask(task, title: "Review organic chemistry", durationMinutes: 30, energyRequired: .good, context: context)
        try PlanningStore.updateGoal(goal, title: "MCAT", area: .education, priority: .high, context: context)

        #expect(persisted.historyRecord.taskTitle == "Study chemistry")
        #expect(persisted.historyRecord.goalTitle == "Study for MCAT")
    }

    @MainActor
    @Test func legacySessionWithoutSnapshotFallsBackSafely() throws {
        let context = try makeContext()
        let (_, task) = try plant(in: context)
        let persisted = try session(for: task, in: context, taskSnapshot: nil, goalSnapshot: nil)
        persisted.taskTitleSnapshot = nil
        persisted.goalTitleSnapshot = nil
        try context.save()

        #expect(persisted.historyTaskTitle == "Review amino acids")
        #expect(persisted.historyGoalTitle == "Study for MCAT")

        try PlanningStore.deleteTask(task, context: context)
        #expect(persisted.historyTaskTitle == "Untitled")
        #expect(persisted.historyGoalTitle == "Study for MCAT")
    }

    @MainActor
    @Test func completedTaskRemainsExcludedAfterEditing() throws {
        let context = try makeContext()
        let (_, task) = try plant(in: context)
        task.complete(at: Date())
        try context.save()
        try PlanningStore.updateTask(task, title: "Still done", durationMinutes: 15, energyRequired: .low, context: context)
        #expect(try recommend(from: context).isEmpty)
        task.reopen()
        try context.save()
        #expect(try recommend(from: context).map(\.title) == ["Still done"])
    }

    @MainActor
    @Test func managementDoesNotCreateFocusSessions() throws {
        let context = try makeContext()
        let (goal, task) = try plant(in: context)
        try PlanningStore.updateGoal(goal, title: "MCAT", area: .career, priority: .normal, context: context)
        try PlanningStore.updateTask(task, title: "Amino", durationMinutes: 15, energyRequired: .low, context: context)
        #expect(try context.fetch(FetchDescriptor<FocusSession>()).isEmpty)
        try PlanningStore.deleteTask(task, context: context)
        #expect(try context.fetch(FetchDescriptor<FocusSession>()).isEmpty)
    }

    @MainActor
    @Test func recommendationRankingRemainsDeterministicAfterEdits() throws {
        let high = TaskItem(title: "A", durationMinutes: 20, energyRequired: .good, area: "Education", goal: "MCAT", goalPriority: .high)
        let never = TaskItem(title: "B", durationMinutes: 30, energyRequired: .good, area: "Career", goal: "Portfolio")
        let recent = TaskItem(title: "C", durationMinutes: 30, energyRequired: .good, area: "Fitness", goal: "Fitness", goalPriority: .high, lastFocusedAt: Date())
        let first = engine.recommendations(tasks: [never, recent, high], availableTime: .thirty, energy: .good)
        let second = engine.recommendations(tasks: [never, recent, high], availableTime: .thirty, energy: .good)
        #expect(first.map(\.title) == ["A", "C", "B"])
        #expect(first.map(\.id) == second.map(\.id))
        #expect(first.dropFirst().map(\.title) == ["C", "B"])
    }

    @MainActor
    @Test func deleteGoalAndTaskSurviveContainerRecreation() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-v2-m3-\(UUID().uuidString).store")
        let sessionID: UUID

        do {
            let container = try NextPersistence.makeContainer(storeURL: storeURL)
            let context = ModelContext(container)
            let (goal, task) = try plant(in: context)
            let persisted = try session(
                for: task,
                in: context,
                finished: true,
                taskSnapshot: "Review amino acids",
                goalSnapshot: "Study for MCAT"
            )
            sessionID = persisted.id
            try PlanningStore.deleteTask(task, context: context)
            let leftover = try context.fetch(FetchDescriptor<Goal>()).first
            try PlanningStore.deleteGoal(leftover!, context: context)
        }

        let reopened = try NextPersistence.makeContainer(storeURL: storeURL)
        let context = ModelContext(reopened)
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        #expect(try context.fetch(FetchDescriptor<Goal>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<GoalTask>()).isEmpty)
        #expect(sessions.count == 1)
        #expect(sessions.first?.id == sessionID)
        #expect(sessions.first?.goal == nil)
        #expect(sessions.first?.task == nil)
        #expect(sessions.first?.taskTitleSnapshot == "Review amino acids")
        #expect(sessions.first?.goalTitleSnapshot == "Study for MCAT")
        #expect(sessions.first?.historyTaskTitle == "Review amino acids")
        #expect(sessions.first?.taskWasFinished == true)
    }
}

@MainActor
final class MockFocusNotificationScheduler: FocusNotificationScheduling {
    var status: UNAuthorizationStatus = .authorized
    var grantOnRequest = true
    var authorizationDelayNanoseconds: UInt64 = 0
    private(set) var scheduled: [FocusCompletionNotification] = []
    private(set) var scheduledSegments: [FocusSegmentNotification] = []
    private(set) var cancelCount = 0
    private(set) var requestCount = 0

    func authorizationStatus() async -> UNAuthorizationStatus { status }

    func requestAuthorization() async -> Bool {
        requestCount += 1
        if authorizationDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: authorizationDelayNanoseconds)
        }
        if grantOnRequest { status = .authorized }
        return grantOnRequest
    }

    func schedule(_ notification: FocusCompletionNotification) async {
        scheduled = [notification]
        scheduledSegments = []
    }

    func scheduleSegment(_ notification: FocusSegmentNotification) async {
        scheduledSegments = [notification]
        scheduled = []
    }

    func cancelCompletionNotification() {
        scheduled = []
        scheduledSegments = []
        cancelCount += 1
    }
}

struct FocusExperienceTests {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)
    private let amino = TaskItem(
        title: "Review amino acids",
        durationMinutes: 25,
        energyRequired: .good,
        area: "Education",
        goal: "Study for MCAT"
    )

    @MainActor
    private func coordinator(
        status: UNAuthorizationStatus = .authorized,
        skipPrompt: Bool = true
    ) -> (FocusNotificationCoordinator, MockFocusNotificationScheduler) {
        let scheduler = MockFocusNotificationScheduler()
        scheduler.status = status
        return (FocusNotificationCoordinator(scheduler: scheduler, skipsSystemPrompt: skipPrompt), scheduler)
    }

    @MainActor
    @Test func runningSessionSchedulesOneCompletionNotificationWhenAuthorized() async {
        let (coordinator, scheduler) = coordinator()
        let timer = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        await coordinator.sync(timer: timer, taskTitle: amino.title, at: start)

        #expect(scheduler.scheduled.count == 1)
        #expect(scheduler.scheduled.first?.taskTitle == "Review amino acids")
        #expect(scheduler.scheduled.first?.fireDate == start.addingTimeInterval(25 * 60))
        #expect(scheduler.scheduled.first?.title == "Focus complete")
        #expect(scheduler.scheduled.first?.body == "You finished your focus session for Review amino acids.")
    }

    @MainActor
    @Test func pauseCancelsPendingNotification() async {
        let (coordinator, scheduler) = coordinator()
        var timer = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        await coordinator.sync(timer: timer, taskTitle: amino.title, at: start)
        timer.pause(at: start.addingTimeInterval(5 * 60))
        await coordinator.sync(timer: timer, taskTitle: amino.title, at: start.addingTimeInterval(5 * 60))

        #expect(scheduler.scheduled.isEmpty)
        #expect(scheduler.cancelCount >= 1)
        #expect(coordinator.scheduled == nil)
    }

    @MainActor
    @Test func resumeSchedulesNotificationFromRemainingTime() async {
        let (coordinator, scheduler) = coordinator()
        var timer = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        timer.pause(at: start.addingTimeInterval(5 * 60))
        timer.resume(at: start.addingTimeInterval(10 * 60))
        await coordinator.sync(timer: timer, taskTitle: amino.title, at: start.addingTimeInterval(10 * 60))

        #expect(scheduler.scheduled.count == 1)
        #expect(scheduler.scheduled.first?.fireDate == start.addingTimeInterval(30 * 60))
    }

    @MainActor
    @Test func finishEarlyCancelsPendingNotification() async {
        let (coordinator, scheduler) = coordinator()
        var timer = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        await coordinator.sync(timer: timer, taskTitle: amino.title, at: start)
        timer.finish(at: start.addingTimeInterval(2 * 60))
        await coordinator.sync(timer: timer, taskTitle: amino.title, at: start.addingTimeInterval(2 * 60))

        #expect(timer.phase == .ended)
        #expect(timer.endedNaturally == false)
        #expect(scheduler.scheduled.isEmpty)
    }

    @MainActor
    @Test func naturalCompletionDoesNotRescheduleNotification() async {
        let (coordinator, scheduler) = coordinator()
        var timer = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        await coordinator.sync(timer: timer, taskTitle: amino.title, at: start)
        timer.evaluateCompletion(at: start.addingTimeInterval(25 * 60))
        await coordinator.sync(timer: timer, taskTitle: amino.title, at: start.addingTimeInterval(25 * 60))
        await coordinator.sync(timer: timer, taskTitle: amino.title, at: start.addingTimeInterval(26 * 60))

        #expect(timer.endedNaturally)
        #expect(scheduler.scheduled.isEmpty)
        #expect(scheduler.scheduled.count != 2)
    }

    @MainActor
    @Test func deniedPermissionDoesNotPreventFocus() async {
        let (coordinator, scheduler) = coordinator(status: .denied)
        var timer = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        await coordinator.sync(timer: timer, taskTitle: amino.title, at: start)
        timer.evaluateCompletion(at: start.addingTimeInterval(3 * 60))

        #expect(scheduler.scheduled.isEmpty)
        #expect(scheduler.requestCount == 0)
        #expect(timer.phase == .running)
        #expect(timer.remainingSeconds(at: start.addingTimeInterval(3 * 60)) == 22 * 60)
    }

    @MainActor
    @Test func notDeterminedPermissionDoesNotCorruptTimer() async {
        let scheduler = MockFocusNotificationScheduler()
        scheduler.status = .notDetermined
        scheduler.grantOnRequest = false
        let coordinator = FocusNotificationCoordinator(scheduler: scheduler, skipsSystemPrompt: false)
        var timer = FocusSessionTimer(durationMinutes: 25, startedAt: start)
        await coordinator.sync(timer: timer, taskTitle: amino.title, at: start)

        #expect(scheduler.requestCount == 1)
        #expect(scheduler.scheduled.isEmpty)
        #expect(timer.phase == .running)
        #expect(timer.remainingSeconds(at: start) == 25 * 60)
    }

    @Test func foregroundCompletionNotificationIsSuppressed() {
        #expect(FocusNotificationPresentation.options(for: FocusCompletionNotification.identifier).isEmpty)
        #expect(FocusNotificationPresentation.options(for: FocusSegmentNotification.identifier).isEmpty)
        #expect(!FocusNotificationPresentation.options(for: "other.notification").isEmpty)
    }

    @MainActor
    @Test func pomodoroSchedulesSegmentThenCompletionNotifications() async {
        let (coordinator, scheduler) = coordinator()
        var pomodoro = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 25, breakMinutes: 5, rounds: 2),
            startedAt: start
        )

        await coordinator.sync(pomodoro: pomodoro, taskTitle: amino.title, at: start)
        #expect(scheduler.scheduled.isEmpty)
        #expect(scheduler.scheduledSegments.count == 1)
        #expect(scheduler.scheduledSegments.first?.title == "Break time")

        pomodoro.evaluateCompletion(at: start.addingTimeInterval(25 * 60))
        await coordinator.sync(pomodoro: pomodoro, taskTitle: amino.title, at: start.addingTimeInterval(25 * 60))
        #expect(pomodoro.isOnBreak)
        #expect(scheduler.scheduledSegments.first?.title == "Back to focus")

        pomodoro.evaluateCompletion(at: start.addingTimeInterval(30 * 60))
        await coordinator.sync(pomodoro: pomodoro, taskTitle: amino.title, at: start.addingTimeInterval(30 * 60))
        #expect(!pomodoro.isOnBreak)
        #expect(pomodoro.willCompleteSessionAtNextNaturalEnd)
        #expect(scheduler.scheduled.count == 1)
        #expect(scheduler.scheduledSegments.isEmpty)
        #expect(scheduler.scheduled.first?.title == "Focus complete")
    }

    @MainActor
    @Test func modeSwitchCancelClearsSegmentAndCompletionNotifications() async {
        let (coordinator, scheduler) = coordinator()
        let pomodoro = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 5, breakMinutes: 1, rounds: 2),
            startedAt: start
        )
        await coordinator.sync(pomodoro: pomodoro, taskTitle: amino.title, at: start)
        #expect(!scheduler.scheduledSegments.isEmpty)

        coordinator.cancel()
        #expect(scheduler.scheduled.isEmpty)
        #expect(scheduler.scheduledSegments.isEmpty)
        #expect(coordinator.scheduled == nil)
        #expect(coordinator.scheduledSegment == nil)
        #expect(scheduler.cancelCount >= 1)

        let simple = FocusSessionTimer(durationMinutes: 25, startedAt: start.addingTimeInterval(30))
        await coordinator.sync(timer: simple, taskTitle: amino.title, at: start.addingTimeInterval(30))
        #expect(scheduler.scheduled.count == 1)
        #expect(scheduler.scheduledSegments.isEmpty)
    }

    @MainActor
    @Test func finishEarlyClearsPendingPomodoroNotifications() async {
        let (coordinator, scheduler) = coordinator()
        var pomodoro = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 5, breakMinutes: 1, rounds: 2),
            startedAt: start
        )
        await coordinator.sync(pomodoro: pomodoro, taskTitle: amino.title, at: start)
        #expect(scheduler.scheduledSegments.count == 1)

        pomodoro.finish(at: start.addingTimeInterval(20))
        coordinator.cancel()
        await coordinator.sync(pomodoro: pomodoro, taskTitle: amino.title, at: start.addingTimeInterval(20))
        #expect(pomodoro.phase == .ended)
        #expect(scheduler.scheduled.isEmpty)
        #expect(scheduler.scheduledSegments.isEmpty)
        #expect(coordinator.scheduled == nil)
        #expect(coordinator.scheduledSegment == nil)
    }

    @MainActor
    @Test func naturalCompletionClearsNotificationsWithoutReschedule() async {
        let (coordinator, scheduler) = coordinator()
        var pomodoro = PomodoroSessionTimer(
            configuration: PomodoroConfiguration(focusMinutes: 5, breakMinutes: 1, rounds: 1),
            startedAt: start
        )
        await coordinator.sync(pomodoro: pomodoro, taskTitle: amino.title, at: start)
        #expect(scheduler.scheduled.count == 1)

        pomodoro.evaluateCompletion(at: start.addingTimeInterval(5 * 60))
        await coordinator.sync(pomodoro: pomodoro, taskTitle: amino.title, at: start.addingTimeInterval(5 * 60))
        #expect(pomodoro.phase == .ended)
        #expect(scheduler.scheduled.isEmpty)
        #expect(scheduler.scheduledSegments.isEmpty)
    }

    @Test func keepScreenAwakeDefaultsOffAndPersists() {
        let defaults = UserDefaults(suiteName: "next.focus-experience-\(UUID().uuidString)")!
        defaults.removePersistentDomain(forName: defaults.dictionaryRepresentation().keys.first ?? "")
        #expect(FocusPreference.keepScreenAwake(in: defaults) == false)

        FocusPreference.setKeepScreenAwake(true, in: defaults)
        #expect(FocusPreference.keepScreenAwake(in: defaults) == true)
        FocusPreference.setKeepScreenAwake(false, in: defaults)
        #expect(FocusPreference.keepScreenAwake(in: defaults) == false)
    }

    @Test func idleTimerOnlyDisablesForRunningForegroundPreference() {
        #expect(
            FocusIdleTimerPolicy.isIdleTimerDisabled(keepScreenAwake: true, phase: .running, sceneActive: true)
        )
        #expect(
            !FocusIdleTimerPolicy.isIdleTimerDisabled(keepScreenAwake: true, phase: .paused, sceneActive: true)
        )
        #expect(
            !FocusIdleTimerPolicy.isIdleTimerDisabled(keepScreenAwake: true, phase: .ended, sceneActive: true)
        )
        #expect(
            !FocusIdleTimerPolicy.isIdleTimerDisabled(keepScreenAwake: true, phase: .running, sceneActive: false)
        )
        #expect(
            !FocusIdleTimerPolicy.isIdleTimerDisabled(keepScreenAwake: false, phase: .running, sceneActive: true)
        )
    }

    @MainActor
    @Test func overlappingPauseAfterScheduleDoesNotResurrectCompletionNotification() async {
        let scheduler = MockFocusNotificationScheduler()
        scheduler.status = .notDetermined
        scheduler.grantOnRequest = true
        scheduler.authorizationDelayNanoseconds = 80_000_000
        let coordinator = FocusNotificationCoordinator(scheduler: scheduler, skipsSystemPrompt: false)
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        var timer = FocusSessionTimer(durationMinutes: 25, startedAt: start)

        async let scheduleFirst: Void = coordinator.sync(timer: timer, taskTitle: amino.title, at: start)
        try? await Task.sleep(for: .milliseconds(10))
        timer.pause(at: start.addingTimeInterval(60))
        await coordinator.sync(timer: timer, taskTitle: amino.title, at: start.addingTimeInterval(60))
        await scheduleFirst

        #expect(scheduler.scheduled.isEmpty)
        #expect(coordinator.scheduled == nil)
    }

    @MainActor
    @Test func preferenceChangeDoesNotMutateDomainData() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(goal)
        context.insert(GoalTask(title: "Review amino acids", durationMinutes: 30, energyRequired: .good, goal: goal))
        try context.save()

        let defaults = UserDefaults(suiteName: "next.focus-pref-\(UUID().uuidString)")!
        FocusPreference.setKeepScreenAwake(true, in: defaults)

        #expect(try context.fetch(FetchDescriptor<Goal>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<GoalTask>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<FocusSession>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Goal>()).first?.title == "Study for MCAT")
    }

    @Test func recommendationEngineRemainsUnaffectedByFocusPreference() {
        let defaults = UserDefaults(suiteName: "next.focus-rank-\(UUID().uuidString)")!
        FocusPreference.setKeepScreenAwake(true, in: defaults)
        let engine = RecommendationEngine()
        let tasks = [
            TaskItem(title: "A", durationMinutes: 20, energyRequired: .good, area: "Education", goal: "MCAT", goalPriority: .high),
            TaskItem(title: "B", durationMinutes: 30, energyRequired: .good, area: "Career", goal: "Portfolio"),
            TaskItem(title: "C", durationMinutes: 30, energyRequired: .good, area: "Fitness", goal: "Fitness", goalPriority: .high, lastFocusedAt: Date())
        ]
        #expect(engine.recommendations(tasks: tasks, availableTime: .thirty, energy: .good).map(\.title) == ["A", "C", "B"])
    }
}

struct AppearancePreferenceTests {
    @Test func defaultAndUnknownFallBackToSystem() {
        #expect(AppearancePreference.resolve(stored: nil) == .system)
        #expect(AppearancePreference.resolve(stored: "") == .system)
        #expect(AppearancePreference.resolve(stored: "lavender") == .system)
        #expect(AppearancePreference.resolve(stored: "system") == .system)
        #expect(AppearancePreference.resolve(stored: "light") == .light)
        #expect(AppearancePreference.resolve(stored: "dark") == .dark)
    }

    @Test func preferredColorSchemeMapping() {
        #expect(AppearancePreference.system.preferredColorScheme == nil)
        #expect(AppearancePreference.light.preferredColorScheme == .light)
        #expect(AppearancePreference.dark.preferredColorScheme == .dark)
    }

    @Test func preferencePersistsInUserDefaults() {
        let defaults = UserDefaults(suiteName: "next.appearance-\(UUID().uuidString)")!
        defaults.removeObject(forKey: AppearancePreference.key)
        #expect(AppearancePreference.current(in: defaults) == .system)

        AppearancePreference.set(.light, in: defaults)
        #expect(AppearancePreference.current(in: defaults) == .light)
        AppearancePreference.set(.dark, in: defaults)
        #expect(AppearancePreference.current(in: defaults) == .dark)
        AppearancePreference.set(.system, in: defaults)
        #expect(AppearancePreference.current(in: defaults) == .system)
    }

    @Test func launchOverrideSeedsStandardKey() {
        let defaults = UserDefaults(suiteName: "next.appearance-launch-\(UUID().uuidString)")!
        defaults.removeObject(forKey: AppearancePreference.key)
        AppearancePreference.applyLaunchOverrides(
            arguments: ["UITEST_APPEARANCE", "dark"],
            defaults: defaults
        )
        #expect(AppearancePreference.current(in: defaults) == .dark)
        AppearancePreference.applyLaunchOverrides(
            arguments: ["UITEST_APPEARANCE", "bogus"],
            defaults: defaults
        )
        #expect(AppearancePreference.current(in: defaults) == .system)
    }

    @MainActor
    @Test func appearancePreferenceDoesNotTouchSwiftData() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(goal)
        context.insert(GoalTask(title: "Review amino acids", durationMinutes: 30, energyRequired: .good, goal: goal))
        try context.save()

        let defaults = UserDefaults(suiteName: "next.appearance-domain-\(UUID().uuidString)")!
        AppearancePreference.set(.dark, in: defaults)

        #expect(try context.fetch(FetchDescriptor<Goal>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<GoalTask>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<FocusSession>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Goal>()).first?.plantVariantRaw == "broadLeaf")
    }

    @Test func lightAndDarkTextMeetWCAGAAAgainstCanvas() {
        func luminance(_ color: UIColor) -> CGFloat {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            func channel(_ c: CGFloat) -> CGFloat {
                c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
        }
        func contrast(_ a: UIColor, _ b: UIColor) -> CGFloat {
            let l1 = luminance(a)
            let l2 = luminance(b)
            let lighter = max(l1, l2)
            let darker = min(l1, l2)
            return (lighter + 0.05) / (darker + 0.05)
        }

        #expect(contrast(NextTheme.Palette.lightPrimary, NextTheme.Palette.lightCanvas) >= 4.5)
        #expect(contrast(NextTheme.Palette.lightSecondary, NextTheme.Palette.lightCanvas) >= 4.5)
        #expect(contrast(NextTheme.Palette.darkPrimary, NextTheme.Palette.darkCanvas) >= 4.5)
        #expect(contrast(NextTheme.Palette.darkSecondary, NextTheme.Palette.darkCanvas) >= 4.5)
        #expect(contrast(NextTheme.Palette.lightInteractive, NextTheme.Palette.lightCanvas) >= 3.0)
        #expect(contrast(NextTheme.Palette.darkInteractive, NextTheme.Palette.darkCanvas) >= 3.0)
        #expect(contrast(NextTheme.Palette.lightBotanicalInk, NextTheme.Palette.lightCanvas) >= 3.0)
        #expect(contrast(NextTheme.Palette.darkBotanicalInk, NextTheme.Palette.darkCanvas) >= 3.0)
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

struct PlantIdentityTests {
    @MainActor
    private func makeContext() throws -> ModelContext {
        ModelContext(try NextPersistence.makeInMemoryContainer())
    }

    @Test func nextVariantPrefersLeastUsedInStableOrder() {
        #expect(PlantVariant.next(among: []) == .broadLeaf)

        let first = Goal(title: "A", area: .education, priority: .normal, plantVariant: .broadLeaf)
        #expect(PlantVariant.next(among: [first]) == .narrowLeaf)

        let second = Goal(title: "B", area: .career, priority: .normal, plantVariant: .narrowLeaf)
        #expect(PlantVariant.next(among: [first, second]) == .branching)

        let third = Goal(title: "C", area: .creative, priority: .normal, plantVariant: .branching)
        #expect(PlantVariant.next(among: [first, second, third]) == .roundedLeaf)

        let fourth = Goal(title: "D", area: .personal, priority: .normal, plantVariant: .roundedLeaf)
        #expect(PlantVariant.next(among: [first, second, third, fourth]) == .broadLeaf)
    }

    @MainActor
    @Test func newGoalReceivesValidVariant() throws {
        let context = try makeContext()
        let goal = Goal(
            title: "Study for MCAT",
            area: .education,
            priority: .high,
            plantVariant: PlantVariant.next(in: context)
        )
        context.insert(goal)
        try context.save()
        #expect(PlantVariant.allCases.contains(goal.plantVariant))
        #expect(goal.plantVariant == .broadLeaf)
    }

    @MainActor
    @Test func differentGoalsCanReceiveDifferentVariants() throws {
        let context = try makeContext()
        var planted: [Goal] = []
        for title in ["MCAT", "Next", "Interview", "Book"] {
            let goal = Goal(
                title: title,
                area: .education,
                priority: .normal,
                plantVariant: .next(among: planted)
            )
            context.insert(goal)
            planted.append(goal)
        }
        try context.save()
        #expect(Set(planted.map(\.plantVariant)) == Set(PlantVariant.allCases))
    }

    @MainActor
    @Test func renameAreaAndPriorityDoNotChangeVariant() throws {
        let context = try makeContext()
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high, plantVariant: .branching)
        context.insert(goal)
        try context.save()

        try PlanningStore.updateGoal(goal, title: "MCAT prep", area: .career, priority: .low, context: context)

        #expect(goal.plantVariant == .branching)
        #expect(goal.title == "MCAT prep")
        #expect(goal.area == .career)
        #expect(goal.priority == .low)
    }

    @MainActor
    @Test func taskEditDoesNotChangeVariant() throws {
        let context = try makeContext()
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high, plantVariant: .narrowLeaf)
        let task = GoalTask(title: "Review amino acids", durationMinutes: 30, energyRequired: .good, goal: goal)
        context.insert(goal)
        context.insert(task)
        try context.save()

        try PlanningStore.updateTask(
            task,
            title: "Review flashcards",
            durationMinutes: 15,
            energyRequired: .low,
            context: context
        )

        #expect(goal.plantVariant == .narrowLeaf)
        #expect(goal.growthStage == .seedling)
    }

    @MainActor
    @Test func focusSessionDoesNotChangeVariant() throws {
        let context = try makeContext()
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high, plantVariant: .roundedLeaf)
        let task = GoalTask(title: "Review amino acids", durationMinutes: 30, energyRequired: .good, goal: goal)
        context.insert(goal)
        context.insert(task)
        try FocusSessionStore.commit(
            result: FocusSessionResult(
                task: task.asTaskItem,
                plannedDurationSeconds: 30 * 60,
                focusedDurationSeconds: 30 * 60,
                endedNaturally: true
            ),
            taskWasFinished: true,
            context: context
        )

        #expect(goal.plantVariant == .roundedLeaf)
        #expect(goal.growthStage == .sprout)
    }

    @MainActor
    @Test func plantIdentityDoesNotAffectRecommendations() throws {
        let engine = RecommendationEngine()
        let context = try makeContext()
        let mcat = Goal(title: "MCAT", area: .education, priority: .high, plantVariant: .broadLeaf)
        let portfolio = Goal(title: "Portfolio", area: .career, priority: .high, plantVariant: .roundedLeaf)
        context.insert(mcat)
        context.insert(portfolio)
        let amino = GoalTask(title: "Review amino acids", durationMinutes: 30, energyRequired: .good, goal: mcat)
        let page = GoalTask(title: "Update project description", durationMinutes: 30, energyRequired: .good, goal: portfolio)
        context.insert(amino)
        context.insert(page)
        try context.save()

        let first = engine.recommendations(
            tasks: [amino, page].recommendationItems,
            availableTime: .thirty,
            energy: .good
        )
        mcat.plantVariant = .branching
        portfolio.plantVariant = .narrowLeaf
        let second = engine.recommendations(
            tasks: [amino, page].recommendationItems,
            availableTime: .thirty,
            energy: .good
        )
        #expect(first.map(\.id) == second.map(\.id))
        #expect(first.map(\.title) == ["Review amino acids", "Update project description"]
            || first.map(\.title) == ["Update project description", "Review amino acids"])
    }

    @Test func rendererSignatureIsDeterministic() {
        for variant in PlantVariant.allCases {
            for stage in GardenGrowthStage.allCases {
                let first = PlantDrawing.signature(variant: variant, stage: stage)
                let second = PlantDrawing.signature(variant: variant, stage: stage)
                #expect(first == second)
                #expect(first == "\(variant.rawValue)-\(stage.rawValue)")
                #expect(PlantArtwork.signature(variant: variant, stage: stage) == first)
            }
        }
    }
}

struct PlantArtworkResolutionTests {
    @Test func assetNamesFollowConventionForAllPairs() {
        let expected: [(PlantVariant, GardenGrowthStage, String)] = [
            (.broadLeaf, .seedling, "plant-broadLeaf-beginning"),
            (.broadLeaf, .sprout, "plant-broadLeaf-establishing"),
            (.broadLeaf, .young, "plant-broadLeaf-developing"),
            (.broadLeaf, .growing, "plant-broadLeaf-flourishing"),
            (.broadLeaf, .mature, "plant-broadLeaf-mature"),
            (.narrowLeaf, .seedling, "plant-narrowLeaf-beginning"),
            (.narrowLeaf, .mature, "plant-narrowLeaf-mature"),
            (.branching, .young, "plant-branching-developing"),
            (.roundedLeaf, .growing, "plant-roundedLeaf-flourishing"),
            (.roundedLeaf, .mature, "plant-roundedLeaf-mature")
        ]
        for (variant, stage, name) in expected {
            #expect(PlantArtwork.assetName(variant: variant, stage: stage) == name)
        }

        let allNames = Set(
            PlantVariant.allCases.flatMap { variant in
                GardenGrowthStage.allCases.map { PlantArtwork.assetName(variant: variant, stage: $0) }
            }
        )
        #expect(allNames.count == PlantVariant.allCases.count * GardenGrowthStage.allCases.count)
    }

    @Test func missingAssetsFallBackToCanvas() {
        PlantArtwork.assetAvailability = { _ in false }
        defer { PlantArtwork.resetTestOverrides() }

        for variant in PlantVariant.allCases {
            for stage in GardenGrowthStage.allCases {
                #expect(PlantArtwork.resolve(variant: variant, stage: stage) == .canvas)
            }
        }
    }

    @Test func presentAssetsResolveToNamedSource() {
        let available = Set([
            "plant-broadLeaf-beginning",
            "plant-roundedLeaf-mature"
        ])
        PlantArtwork.assetAvailability = { available.contains($0) }
        defer { PlantArtwork.resetTestOverrides() }

        #expect(
            PlantArtwork.resolve(variant: .broadLeaf, stage: .seedling)
                == .asset("plant-broadLeaf-beginning")
        )
        #expect(
            PlantArtwork.resolve(variant: .roundedLeaf, stage: .mature)
                == .asset("plant-roundedLeaf-mature")
        )
        #expect(PlantArtwork.resolve(variant: .narrowLeaf, stage: .sprout) == .canvas)
        #expect(PlantArtwork.resolve(variant: .branching, stage: .growing) == .canvas)
    }

    @Test func resolutionIsDeterministic() {
        PlantArtwork.assetAvailability = { $0.hasSuffix("-mature") }
        defer { PlantArtwork.resetTestOverrides() }

        for variant in PlantVariant.allCases {
            for stage in GardenGrowthStage.allCases {
                let first = PlantArtwork.resolve(variant: variant, stage: stage)
                let second = PlantArtwork.resolve(variant: variant, stage: stage)
                #expect(first == second)
            }
        }
    }

    @Test func noCatalogAssetsMeansFullCanvasFallback() {
        // Production catalog currently ships no plant-* images.
        PlantArtwork.resetTestOverrides()
        for variant in PlantVariant.allCases {
            for stage in GardenGrowthStage.allCases {
                #expect(PlantArtwork.resolve(variant: variant, stage: stage) == .canvas)
            }
        }
    }
}

struct GardenEvolutionPersistenceTests {
    @MainActor
    @Test func existingGoalLoadsDefaultVariantAndStaysStable() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-m5-\(UUID().uuidString).store")
        let goalID: UUID

        do {
            let container = try NextPersistence.makeContainer(storeURL: storeURL)
            let context = ModelContext(container)
            let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
            context.insert(goal)
            let task = GoalTask(title: "Review amino acids", durationMinutes: 30, energyRequired: .good, goal: goal)
            context.insert(task)
            try context.save()
            #expect(goal.plantVariant == .broadLeaf)

            try PlanningStore.updateGoal(goal, title: "MCAT prep", area: .career, priority: .normal, context: context)
            try PlanningStore.updateTask(
                task,
                title: "Review flashcards",
                durationMinutes: 15,
                energyRequired: .low,
                context: context
            )
            try FocusSessionStore.commit(
                result: FocusSessionResult(
                    task: task.asTaskItem,
                    plannedDurationSeconds: 15 * 60,
                    focusedDurationSeconds: 15 * 60,
                    endedNaturally: true
                ),
                taskWasFinished: false,
                context: context
            )
            goalID = goal.id
            #expect(goal.plantVariant == .broadLeaf)
        }

        let reopened = try NextPersistence.makeContainer(storeURL: storeURL)
        let context = ModelContext(reopened)
        let goals = try context.fetch(FetchDescriptor<Goal>())
        let tasks = try context.fetch(FetchDescriptor<GoalTask>())
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())

        #expect(goals.count == 1)
        #expect(goals.first?.id == goalID)
        #expect(goals.first?.title == "MCAT prep")
        #expect(goals.first?.area == .career)
        #expect(goals.first?.plantVariant == .broadLeaf)
        #expect(tasks.count == 1)
        #expect(tasks.first?.title == "Review flashcards")
        #expect(sessions.count == 1)
        #expect(sessions.first?.focusedDurationSeconds == 900.0)
    }

    @MainActor
    @Test func assignedVariantPersistsAcrossRelaunch() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-m5-variant-\(UUID().uuidString).store")

        do {
            let container = try NextPersistence.makeContainer(storeURL: storeURL)
            let context = ModelContext(container)
            context.insert(Goal(title: "Build Next", area: .creative, priority: .normal, plantVariant: .branching))
            try context.save()
        }

        let reopened = try NextPersistence.makeContainer(storeURL: storeURL)
        let context = ModelContext(reopened)
        #expect(try context.fetch(FetchDescriptor<Goal>()).first?.plantVariant == .branching)
    }
}

struct GardenGrowthDerivationTests {
    @MainActor
    private func makeContext() throws -> ModelContext {
        ModelContext(try NextPersistence.makeInMemoryContainer())
    }

    @MainActor
    private func goal(
        in context: ModelContext,
        minutes: [Double],
        finished: Bool = false
    ) throws -> Goal {
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high, plantVariant: .narrowLeaf)
        context.insert(goal)
        let task = GoalTask(title: "Review amino acids", durationMinutes: 30, energyRequired: .good, goal: goal)
        context.insert(task)
        for value in minutes {
            try FocusSessionStore.commit(
                result: FocusSessionResult(
                    task: task.asTaskItem,
                    plannedDurationSeconds: value * 60,
                    focusedDurationSeconds: value * 60,
                    endedNaturally: true
                ),
                taskWasFinished: finished,
                context: context
            )
        }
        return goal
    }

    @MainActor
    @Test func thresholdsMatchExistingStages() throws {
        #expect(try goal(in: makeContext(), minutes: []).growthStage == .seedling)
        #expect(try goal(in: makeContext(), minutes: [29]).growthStage == .seedling)
        #expect(try goal(in: makeContext(), minutes: [30]).growthStage == .sprout)
        #expect(try goal(in: makeContext(), minutes: [119]).growthStage == .sprout)
        #expect(try goal(in: makeContext(), minutes: [120]).growthStage == .young)
        #expect(try goal(in: makeContext(), minutes: [299]).growthStage == .young)
        #expect(try goal(in: makeContext(), minutes: [300]).growthStage == .growing)
        #expect(try goal(in: makeContext(), minutes: [599]).growthStage == .growing)
        #expect(try goal(in: makeContext(), minutes: [600]).growthStage == .mature)
    }

    @MainActor
    @Test func multipleSessionsSumAndBothAnswersCount() throws {
        let context = try makeContext()
        let planted = Goal(title: "Study for MCAT", area: .education, priority: .high, plantVariant: .broadLeaf)
        context.insert(planted)
        let task = GoalTask(title: "Review amino acids", durationMinutes: 30, energyRequired: .good, goal: planted)
        context.insert(task)
        try FocusSessionStore.commit(
            result: FocusSessionResult(
                task: task.asTaskItem,
                plannedDurationSeconds: 20 * 60,
                focusedDurationSeconds: 20 * 60,
                endedNaturally: false
            ),
            taskWasFinished: false,
            context: context
        )
        try FocusSessionStore.commit(
            result: FocusSessionResult(
                task: task.asTaskItem,
                plannedDurationSeconds: 15 * 60,
                focusedDurationSeconds: 15 * 60,
                endedNaturally: true
            ),
            taskWasFinished: true,
            context: context
        )
        #expect(planted.totalFocusedDuration == 35 * 60)
        #expect(planted.growthStage == .sprout)
        #expect(planted.plantVariant == .broadLeaf)
    }

    @MainActor
    @Test func deletedTaskHistoryStillGrowsGoal() throws {
        let context = try makeContext()
        let planted = try goal(in: context, minutes: [30])
        let variant = planted.plantVariant
        let task = planted.tasks.first
        #expect(task != nil)
        if let task {
            try PlanningStore.deleteTask(task, context: context)
        }
        #expect(planted.totalFocusedDuration == 30 * 60)
        #expect(planted.growthStage == .sprout)
        #expect(planted.plantVariant == variant)
        #expect(try context.fetch(FetchDescriptor<FocusSession>()).count == 1)
    }

    @MainActor
    @Test func editingGoalOrTaskDoesNotChangeStage() throws {
        let context = try makeContext()
        let planted = try goal(in: context, minutes: [120])
        try PlanningStore.updateGoal(planted, title: "MCAT", area: .career, priority: .low, context: context)
        if let task = planted.tasks.first {
            try PlanningStore.updateTask(
                task,
                title: "Passage",
                durationMinutes: 45,
                energyRequired: .ready,
                context: context
            )
        }
        #expect(planted.growthStage == .young)
        #expect(planted.totalFocusedDuration == 120 * 60)
        #expect(planted.plantVariant == .narrowLeaf)
    }
}

struct GardenAcknowledgementTests {
    @Test func genericCopyWhenStageDoesNotChange() {
        #expect(
            GardenAcknowledgement.message(
                goalTitle: "Study for MCAT",
                previousStage: .seedling,
                nextStage: .seedling
            ) == "This session helped your Study for MCAT plant grow."
        )
    }

    @Test func newGrowthCopyWhenStageCrosses() {
        #expect(
            GardenAcknowledgement.message(
                goalTitle: "Study for MCAT",
                previousStage: .seedling,
                nextStage: .sprout
            ) == "Your Study for MCAT plant has new growth."
        )
    }

    @Test func acknowledgementDoesNotMutateSessionSemantics() {
        var completion = SessionCompletionState()
        completion.select(.notCompleted)
        let message = GardenAcknowledgement.message(
            goalTitle: "Study for MCAT",
            previousStage: .young,
            nextStage: .young
        )
        #expect(completion.taskCompletion == .notCompleted)
        #expect(message.contains("Study for MCAT"))
    }
}

private extension GoalTask {
    var tasksAreUnchanged: Bool {
        title == "Review amino acids" && durationMinutes == 30
    }
}

// MARK: - V2-M7 Smart Reminders

@MainActor
final class MockDailyReminderScheduler: DailyReminderScheduling {
    var status: UNAuthorizationStatus = .authorized
    var grantOnRequest = true
    private(set) var pending: [UNNotificationRequest] = []
    private(set) var cancelCount = 0
    private(set) var requestCount = 0
    private(set) var scheduledIdentifiers: [String] = []

    func authorizationStatus() async -> UNAuthorizationStatus { status }

    func requestAuthorization() async -> Bool {
        requestCount += 1
        if grantOnRequest { status = .authorized }
        return grantOnRequest
    }

    func pendingReminderIdentifiers() async -> [String] {
        pending.map(\.identifier).filter { $0 == DailyReminder.identifier }
    }

    func scheduleReminder(_ request: UNNotificationRequest) async {
        pending.removeAll { $0.identifier == request.identifier }
        pending.append(request)
        scheduledIdentifiers.append(request.identifier)
    }

    func cancelReminderNotifications() {
        pending.removeAll { $0.identifier == DailyReminder.identifier }
        cancelCount += 1
    }
}

struct SmartRemindersTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    @Test func remindersDefaultOff() {
        let defaults = UserDefaults(suiteName: "next.reminder-default-\(UUID().uuidString)")!
        #expect(ReminderPreference.isEnabled(in: defaults) == false)
        #expect(ReminderPreference.hour(in: defaults) == 9)
        #expect(ReminderPreference.minute(in: defaults) == 0)
    }

    @Test func reminderTimePersistsLocally() {
        let defaults = UserDefaults(suiteName: "next.reminder-time-\(UUID().uuidString)")!
        ReminderPreference.setTime(hour: 14, minute: 45, in: defaults)
        #expect(ReminderPreference.hour(in: defaults) == 14)
        #expect(ReminderPreference.minute(in: defaults) == 45)
        ReminderPreference.setEnabled(true, in: defaults)
        #expect(ReminderPreference.isEnabled(in: defaults))
        ReminderPreference.setEnabled(false, in: defaults)
        #expect(!ReminderPreference.isEnabled(in: defaults))
    }

    @Test func nextFireUsesLocalCalendarAndSkipsTodayAfterFocus() {
        let now = day(2026, 3, 8, hour: 8, minute: 0)
        let todayFire = DailyReminder.nextFireDate(
            now: now,
            hour: 9,
            minute: 0,
            hasFocusedToday: false,
            calendar: calendar
        )
        #expect(calendar.component(.day, from: todayFire) == 8)
        #expect(calendar.component(.hour, from: todayFire) == 9)

        let afterFocus = DailyReminder.nextFireDate(
            now: now,
            hour: 9,
            minute: 0,
            hasFocusedToday: true,
            calendar: calendar
        )
        #expect(calendar.component(.day, from: afterFocus) == 9)

        let afterClock = DailyReminder.nextFireDate(
            now: day(2026, 3, 8, hour: 10),
            hour: 9,
            minute: 0,
            hasFocusedToday: false,
            calendar: calendar
        )
        #expect(calendar.component(.day, from: afterClock) == 9)
    }

    @Test func hasFocusedTodayIgnoresTaskCompletionSemantics() {
        let now = day(2026, 3, 8, hour: 12)
        #expect(
            DailyReminder.hasFocusedToday(
                completedAtDates: [day(2026, 3, 8, hour: 7)],
                now: now,
                calendar: calendar
            )
        )
        #expect(
            !DailyReminder.hasFocusedToday(
                completedAtDates: [day(2026, 3, 7, hour: 18)],
                now: now,
                calendar: calendar
            )
        )
    }

    @Test func reminderCopyIsCalmAndNonPersonalized() {
        for message in DailyReminder.messages {
            #expect(!message.lowercased().contains("streak"))
            #expect(!message.lowercased().contains("missed"))
            #expect(!message.lowercased().contains("urgent"))
        }
        let body = DailyReminder.message(for: day(2026, 1, 1, hour: 9), calendar: calendar)
        #expect(DailyReminder.messages.contains(body))
    }

    @Test func reminderAndFocusCompletionIdentifiersStayDistinct() {
        #expect(DailyReminder.identifier == "next.reminder.daily")
        #expect(FocusCompletionNotification.identifier == "next.focus.completion")
        #expect(FocusSegmentNotification.identifier == "next.focus.segment")
        #expect(DailyReminder.identifier != FocusCompletionNotification.identifier)
        #expect(FocusCompletionNotification.identifier != FocusSegmentNotification.identifier)
        #expect(FocusNotificationPresentation.options(for: FocusCompletionNotification.identifier).isEmpty)
        #expect(FocusNotificationPresentation.options(for: FocusSegmentNotification.identifier).isEmpty)
        #expect(!FocusNotificationPresentation.options(for: DailyReminder.identifier).isEmpty)
    }

    @MainActor
    @Test func enableSchedulesOneReminderWhenAuthorized() async {
        let defaults = UserDefaults(suiteName: "next.reminder-enable-\(UUID().uuidString)")!
        let scheduler = MockDailyReminderScheduler()
        let coordinator = DailyReminderCoordinator(
            scheduler: scheduler,
            skipsSystemPrompt: true,
            defaults: defaults,
            calendar: calendar
        )
        let now = day(2026, 3, 8, hour: 8)

        let auth = await coordinator.enable(now: now, hasFocusedToday: false)
        #expect(auth == .authorized)
        #expect(ReminderPreference.isEnabled(in: defaults))
        #expect(scheduler.pending.count == 1)
        #expect(scheduler.pending.first?.identifier == DailyReminder.identifier)
        #expect(coordinator.lastScheduledFireDate == day(2026, 3, 8, hour: 9))
    }

    @MainActor
    @Test func deniedPermissionLeavesRemindersOff() async {
        let defaults = UserDefaults(suiteName: "next.reminder-denied-\(UUID().uuidString)")!
        let scheduler = MockDailyReminderScheduler()
        scheduler.status = .denied
        let coordinator = DailyReminderCoordinator(
            scheduler: scheduler,
            skipsSystemPrompt: true,
            defaults: defaults,
            calendar: calendar
        )

        let auth = await coordinator.enable(now: day(2026, 3, 8, hour: 8), hasFocusedToday: false)
        #expect(auth == .denied)
        #expect(!ReminderPreference.isEnabled(in: defaults))
        #expect(scheduler.pending.isEmpty)
        #expect(scheduler.requestCount == 0)
    }

    @MainActor
    @Test func disableCancelsOnlyReminderNotifications() async {
        let defaults = UserDefaults(suiteName: "next.reminder-disable-\(UUID().uuidString)")!
        let scheduler = MockDailyReminderScheduler()
        let coordinator = DailyReminderCoordinator(
            scheduler: scheduler,
            skipsSystemPrompt: true,
            defaults: defaults,
            calendar: calendar
        )
        _ = await coordinator.enable(now: day(2026, 3, 8, hour: 8), hasFocusedToday: false)
        coordinator.disable()

        #expect(!ReminderPreference.isEnabled(in: defaults))
        #expect(scheduler.pending.isEmpty)
        #expect(scheduler.cancelCount >= 2)
        #expect(!scheduler.scheduledIdentifiers.contains(FocusCompletionNotification.identifier))
    }

    @MainActor
    @Test func timeChangeReschedulesWithoutDuplicates() async {
        let defaults = UserDefaults(suiteName: "next.reminder-reschedule-\(UUID().uuidString)")!
        let scheduler = MockDailyReminderScheduler()
        let coordinator = DailyReminderCoordinator(
            scheduler: scheduler,
            skipsSystemPrompt: true,
            defaults: defaults,
            calendar: calendar
        )
        let now = day(2026, 3, 8, hour: 8)
        _ = await coordinator.enable(now: now, hasFocusedToday: false)
        await coordinator.updateTime(hour: 18, minute: 30, now: now, hasFocusedToday: false)

        #expect(ReminderPreference.hour(in: defaults) == 18)
        #expect(ReminderPreference.minute(in: defaults) == 30)
        #expect(scheduler.pending.count == 1)
        #expect(scheduler.pending.first?.identifier == DailyReminder.identifier)
        #expect(coordinator.lastScheduledFireDate == day(2026, 3, 8, hour: 18, minute: 30))
        let pendingIds = await scheduler.pendingReminderIdentifiers()
        #expect(pendingIds == [DailyReminder.identifier])
    }

    @MainActor
    @Test func reconcileSuppressesTodayWhenFocused() async {
        let defaults = UserDefaults(suiteName: "next.reminder-suppress-\(UUID().uuidString)")!
        ReminderPreference.setEnabled(true, in: defaults)
        ReminderPreference.setTime(hour: 9, minute: 0, in: defaults)
        let scheduler = MockDailyReminderScheduler()
        let coordinator = DailyReminderCoordinator(
            scheduler: scheduler,
            skipsSystemPrompt: true,
            defaults: defaults,
            calendar: calendar
        )
        let now = day(2026, 3, 8, hour: 8)
        await coordinator.reconcile(now: now, hasFocusedToday: true)

        #expect(coordinator.lastScheduledFireDate == day(2026, 3, 9, hour: 9))
        #expect(scheduler.pending.count == 1)
    }

    @MainActor
    @Test func reconcileDisablesWhenAuthorizationRevoked() async {
        let defaults = UserDefaults(suiteName: "next.reminder-revoke-\(UUID().uuidString)")!
        ReminderPreference.setEnabled(true, in: defaults)
        let scheduler = MockDailyReminderScheduler()
        scheduler.status = .denied
        let coordinator = DailyReminderCoordinator(
            scheduler: scheduler,
            skipsSystemPrompt: true,
            defaults: defaults,
            calendar: calendar
        )
        await coordinator.reconcile(now: day(2026, 3, 8, hour: 8), hasFocusedToday: false)

        #expect(!ReminderPreference.isEnabled(in: defaults))
        #expect(scheduler.pending.isEmpty)
    }

    @MainActor
    @Test func requestingAuthorizationOnlyWhenEnabling() async {
        let defaults = UserDefaults(suiteName: "next.reminder-prompt-\(UUID().uuidString)")!
        let scheduler = MockDailyReminderScheduler()
        scheduler.status = .notDetermined
        scheduler.grantOnRequest = true
        let coordinator = DailyReminderCoordinator(
            scheduler: scheduler,
            skipsSystemPrompt: false,
            defaults: defaults,
            calendar: calendar
        )
        #expect(coordinator.authorizationRequests == 0)
        _ = await coordinator.enable(now: day(2026, 3, 8, hour: 8), hasFocusedToday: false)
        #expect(coordinator.authorizationRequests == 1)
        #expect(scheduler.requestCount == 1)
        #expect(ReminderPreference.isEnabled(in: defaults))
    }

    @MainActor
    @Test func reminderPreferencesDoNotMutateFocusSessions() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
        context.insert(goal)
        context.insert(GoalTask(title: "Review amino acids", durationMinutes: 30, energyRequired: .good, goal: goal))
        let session = FocusSession(
            completedAt: day(2026, 3, 8, hour: 7),
            plannedDurationSeconds: 25 * 60,
            focusedDurationSeconds: 25 * 60,
            endedNaturally: true,
            taskWasFinished: false,
            taskTitleSnapshot: "Review amino acids",
            goalTitleSnapshot: "Study for MCAT",
            goal: goal
        )
        context.insert(session)
        try context.save()

        let defaults = UserDefaults(suiteName: "next.reminder-domain-\(UUID().uuidString)")!
        ReminderPreference.setEnabled(true, in: defaults)
        ReminderPreference.setTime(hour: 16, minute: 0, in: defaults)

        let fetched = try context.fetch(FetchDescriptor<FocusSession>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.taskWasFinished == false)
        #expect(fetched.first?.taskTitleSnapshot == "Review amino acids")
        #expect(DailyReminderCoordinator.hasFocusedToday(context: context, now: day(2026, 3, 8, hour: 12), calendar: calendar))
    }
}

// MARK: - V2-M9 Home Greeting + Theme Separation

struct HomeGreetingTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: hour, minute: minute))!
    }

    @Test func morningBoundaryUsesLocalHour() {
        #expect(HomeDayPart.resolve(now: date(hour: 5), calendar: calendar) == .morning)
        #expect(HomeDayPart.resolve(now: date(hour: 11, minute: 59), calendar: calendar) == .morning)
        #expect(HomeGreeting.text(now: date(hour: 8), calendar: calendar) == "Good morning.")
    }

    @Test func noonBoundaryIsAfternoon() {
        #expect(HomeDayPart.resolve(now: date(hour: 12), calendar: calendar) == .afternoon)
        #expect(HomeDayPart.resolve(now: date(hour: 16, minute: 59), calendar: calendar) == .afternoon)
        #expect(HomeGreeting.text(now: date(hour: 14), calendar: calendar) == "Good afternoon.")
    }

    @Test func eveningSpansOvernight() {
        #expect(HomeDayPart.resolve(now: date(hour: 17), calendar: calendar) == .evening)
        #expect(HomeDayPart.resolve(now: date(hour: 4, minute: 59), calendar: calendar) == .evening)
        #expect(HomeGreeting.text(now: date(hour: 21), calendar: calendar) == "Good evening.")
    }

    @Test func timeZoneChangeAffectsGreetingWhenHourCrossesBoundary() {
        var eastern = Calendar(identifier: .gregorian)
        eastern.timeZone = TimeZone(secondsFromGMT: -5 * 3600)!
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        // 16:30 UTC = 11:30 EST → morning in eastern, afternoon in UTC
        let instant = utc.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 16, minute: 30))!
        #expect(HomeDayPart.resolve(now: instant, calendar: utc) == .afternoon)
        #expect(HomeDayPart.resolve(now: instant, calendar: eastern) == .morning)
    }
}

struct ThemeSeparationTests {
    @Test func interactiveAccentDiffersFromBotanicalInk() {
        #expect(NextTheme.Palette.lightInteractive != NextTheme.Palette.lightBotanicalInk)
        #expect(NextTheme.Palette.darkInteractive != NextTheme.Palette.darkBotanicalInk)
    }

    @Test func interactiveAccentIsLavenderNotPlantGreen() {
        var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        NextTheme.Palette.lightInteractive.getRed(&lr, green: &lg, blue: &lb, alpha: &la)
        NextTheme.Palette.lightBotanicalInk.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        // Lavender is more blue/red-balanced; plant ink is greener.
        #expect(lb > lg)
        #expect(bg > br)
        #expect(bg > bb)
    }
}

// MARK: - V2-M8 Release Candidate

struct ReleaseCandidateTests {
    @Test func uitestHooksAreExplicitlyPrefixed() {
        #expect(NextPersistence.seedArgument.hasPrefix("UITEST_"))
        #expect(NextPersistence.inMemoryArgument.hasPrefix("UITEST_"))
        #expect(AppearancePreference.launchArgument.hasPrefix("UITEST_"))
        #expect(ReminderPreference.authLaunchArgument.hasPrefix("UITEST_"))
        #expect(ReminderPreference.enabledLaunchArgument.hasPrefix("UITEST_"))
        #expect(OnboardingPreference.freshArgument.hasPrefix("UITEST_"))
    }

    @Test func notificationIdentifiersRemainIsolated() {
        #expect(FocusCompletionNotification.identifier == "next.focus.completion")
        #expect(DailyReminder.identifier == "next.reminder.daily")
        #expect(FocusCompletionNotification.identifier != DailyReminder.identifier)
    }

    @Test func reminderDefaultsStayOffAndLocal() {
        let defaults = UserDefaults(suiteName: "next.rc-reminder-\(UUID().uuidString)")!
        #expect(ReminderPreference.isEnabled(in: defaults) == false)
        #expect(ReminderPreference.hour(in: defaults) == 9)
        #expect(ReminderPreference.minute(in: defaults) == 0)
    }

    @Test func appearanceDefaultsToSystem() {
        let defaults = UserDefaults(suiteName: "next.rc-appearance-\(UUID().uuidString)")!
        #expect(AppearancePreference.current(in: defaults) == .system)
    }

    @MainActor
    @Test func reminderDisableDoesNotEmitFocusCompletionIdentifier() async {
        let defaults = UserDefaults(suiteName: "next.rc-cancel-\(UUID().uuidString)")!
        let scheduler = MockDailyReminderScheduler()
        let coordinator = DailyReminderCoordinator(
            scheduler: scheduler,
            skipsSystemPrompt: true,
            defaults: defaults,
            calendar: .current
        )
        _ = await coordinator.enable(now: Date(), hasFocusedToday: false)
        coordinator.disable()
        #expect(scheduler.pending.isEmpty)
        #expect(!scheduler.scheduledIdentifiers.contains(FocusCompletionNotification.identifier))
        #expect(scheduler.scheduledIdentifiers.allSatisfy { $0 == DailyReminder.identifier })
    }

    @MainActor
    @Test func focusCompletionCancelLeavesReminderIdentifierUntouched() async {
        let focusScheduler = MockFocusNotificationScheduler()
        let focus = FocusNotificationCoordinator(scheduler: focusScheduler, skipsSystemPrompt: true)
        let timer = FocusSessionTimer(durationMinutes: 25, startedAt: Date(timeIntervalSince1970: 1_700_000_000))
        await focus.sync(timer: timer, taskTitle: "Review amino acids", at: Date(timeIntervalSince1970: 1_700_000_000))
        focus.cancel()
        #expect(focusScheduler.scheduled.isEmpty)
        #expect(focusScheduler.cancelCount >= 1)
    }

    @Test func keepScreenAwakeOnlyWhileRunningAndActive() {
        #expect(
            FocusIdleTimerPolicy.isIdleTimerDisabled(keepScreenAwake: true, phase: .running, sceneActive: true)
        )
        #expect(
            !FocusIdleTimerPolicy.isIdleTimerDisabled(keepScreenAwake: true, phase: .paused, sceneActive: true)
        )
        #expect(
            !FocusIdleTimerPolicy.isIdleTimerDisabled(keepScreenAwake: true, phase: .running, sceneActive: false)
        )
    }

    @MainActor
    @Test func persistentStoreSurvivesRelaunchWithoutSeeding() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("next-rc-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            let container = try NextPersistence.makeContainer(storeURL: url)
            let context = ModelContext(container)
            let goal = Goal(title: "Study for MCAT", area: .education, priority: .high)
            context.insert(goal)
            context.insert(GoalTask(title: "Review amino acids", durationMinutes: 25, energyRequired: .good, goal: goal))
            try context.save()
        }

        let reopened = try NextPersistence.makeContainer(storeURL: url)
        let context = ModelContext(reopened)
        let goals = try context.fetch(FetchDescriptor<Goal>())
        let tasks = try context.fetch(FetchDescriptor<GoalTask>())
        #expect(goals.count == 1)
        #expect(goals.first?.title == "Study for MCAT")
        #expect(tasks.count == 1)
        #expect(tasks.first?.isCompleted == false)
    }
}

// MARK: - V3-M1 Goal Organization & Recommendation Filtering

struct MultiAreaGoalTests {
    @MainActor
    @Test func zeroOneAndMultiAreaPersistAndDeduplicate() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())

        let none = Goal(title: "Open", areas: [], priority: .normal)
        let one = Goal(title: "MCAT", areas: [.education], priority: .high)
        let multi = Goal(
            title: "Build Next",
            areas: [.creative, .career, .creative, .education],
            priority: .high
        )
        [none, one, multi].forEach(context.insert)
        try context.save()

        #expect(none.areas.isEmpty)
        #expect(none.areasRaw.isEmpty)
        #expect(none.areasMigrated)
        #expect(one.areas == [.education])
        #expect(multi.areas == [.education, .career, .creative])
        #expect(multi.areasDisplayLabel == "EDUCATION · CAREER · CREATIVE")
        #expect(try context.fetch(FetchDescriptor<Goal>()).count == 3)
    }

    @MainActor
    @Test func legacySingleAreaBackfillPreservesIdentityTasksAndSessions() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-v3m1-migrate-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        let goalID = UUID()
        let taskID = UUID()
        let sessionID = UUID()

        do {
            let container = try NextPersistence.makeContainer(storeURL: url)
            let context = ModelContext(container)
            let goal = Goal(
                id: goalID,
                title: "Study for MCAT",
                area: .education,
                priority: .high
            )
            // Simulate a pre-multi-area row after lightweight property defaults land.
            goal.areasRaw = ""
            goal.areasMigrated = false
            context.insert(goal)
            let task = GoalTask(
                id: taskID,
                title: "Review amino acids",
                durationMinutes: 30,
                energyRequired: .good,
                goal: goal
            )
            context.insert(task)
            context.insert(
                FocusSession(
                    id: sessionID,
                    plannedDurationSeconds: 1800,
                    focusedDurationSeconds: 1800,
                    endedNaturally: true,
                    taskWasFinished: false,
                    taskTitleSnapshot: "Review amino acids",
                    goalTitleSnapshot: "Study for MCAT",
                    goal: goal,
                    task: task
                )
            )
            try context.save()
            #expect(goal.areasMigrated == false)
            #expect(goal.areas == [.education])
        }

        let reopened = try NextPersistence.makeContainer(storeURL: url)
        let context = ModelContext(reopened)
        let goals = try context.fetch(FetchDescriptor<Goal>())
        let tasks = try context.fetch(FetchDescriptor<GoalTask>())
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())

        #expect(goals.count == 1)
        #expect(goals.first?.id == goalID)
        #expect(goals.first?.title == "Study for MCAT")
        #expect(goals.first?.priority == .high)
        #expect(goals.first?.areasMigrated == true)
        #expect(goals.first?.areas == [.education])
        #expect(goals.first?.areasRaw == "education")
        #expect(tasks.count == 1)
        #expect(tasks.first?.id == taskID)
        #expect(tasks.first?.goal?.id == goalID)
        #expect(sessions.count == 1)
        #expect(sessions.first?.id == sessionID)
        #expect(sessions.first?.goalTitleSnapshot == "Study for MCAT")
        #expect(sessions.first?.taskTitleSnapshot == "Review amino acids")
        #expect(goals.first?.totalFocusedDuration == 1800)
        #expect(goals.first?.sessionCount == 1)
    }

    @MainActor
    @Test func editingAreasDoesNotResetProgressAndCancelPreservesSelectionSemantics() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let goal = Goal(title: "Build Next", areas: [.creative], priority: .normal)
        context.insert(goal)
        let task = GoalTask(title: "Sketch", durationMinutes: 30, energyRequired: .good, goal: goal)
        context.insert(task)
        context.insert(
            FocusSession(
                plannedDurationSeconds: 7200,
                focusedDurationSeconds: 7200,
                endedNaturally: true,
                taskWasFinished: false,
                goal: goal,
                task: task
            )
        )
        try context.save()

        let beforeMinutes = goal.totalFocusedDuration
        let beforeSessions = goal.sessionCount
        let beforeID = goal.id

        try PlanningStore.updateGoal(
            goal,
            title: goal.title,
            areas: [.creative, .career, .education],
            priority: .high,
            context: context
        )

        #expect(goal.id == beforeID)
        #expect(goal.areas == [.education, .career, .creative])
        #expect(goal.totalFocusedDuration == beforeMinutes)
        #expect(goal.sessionCount == beforeSessions)
        #expect(goal.tasks.count == 1)

        // "Cancel" path: mutate in-memory draft only; persisted areas stay until save.
        let draft = Set(goal.areas)
        var canceled = draft
        canceled.remove(.education)
        canceled.insert(.fitness)
        #expect(goal.areas == [.education, .career, .creative])
        #expect(canceled != draft)
    }

    @MainActor
    @Test func multiAreaGoalAppearsOnceAndDoesNotDoubleCountProgress() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let goal = Goal(title: "Build Next", areas: [.creative, .career], priority: .high)
        context.insert(goal)
        context.insert(
            FocusSession(
                plannedDurationSeconds: 3600,
                focusedDurationSeconds: 3600,
                endedNaturally: true,
                taskWasFinished: false,
                goal: goal
            )
        )
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        #expect(goals.count == 1)
        #expect(goals.first?.sessionCount == 1)
        #expect(goals.first?.totalFocusedDuration == 3600)
        #expect(goals.first?.areasDisplayLabel == "CAREER · CREATIVE")
    }
}

struct RecommendationScopeTests {
    private let engine = RecommendationEngine()

    @MainActor
    @Test func anythingLifeAreaAndSpecificGoalFilteringPreserveRankingAndDedup() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let next = Goal(title: "Build Next", areas: [.creative, .career], priority: .high)
        let mcat = Goal(title: "MCAT", areas: [.education], priority: .high)
        let portfolio = Goal(title: "Portfolio", areas: [.career], priority: .normal)
        [next, mcat, portfolio].forEach(context.insert)

        let sketch = GoalTask(title: "Sketch garden", durationMinutes: 30, energyRequired: .good, goal: next)
        let amino = GoalTask(title: "Amino acids", durationMinutes: 30, energyRequired: .good, goal: mcat)
        let page = GoalTask(title: "Update page", durationMinutes: 30, energyRequired: .good, goal: portfolio)
        [sketch, amino, page].forEach(context.insert)
        try context.save()

        let allTasks = try context.fetch(FetchDescriptor<GoalTask>())
        let anything = allTasks.recommendationItems(matching: .anything)
        #expect(Set(anything.map(\.id)).count == 3)
        #expect(anything.count == 3)

        var careerScope = RecommendationScope()
        careerScope.mode = .lifeArea
        careerScope.selectedArea = .career
        let careerItems = allTasks.recommendationItems(matching: careerScope)
        #expect(Set(careerItems.map(\.title)) == ["Sketch garden", "Update page"])
        #expect(careerItems.count == 2)

        var creativeScope = RecommendationScope()
        creativeScope.mode = .lifeArea
        creativeScope.selectedArea = .creative
        let creativeItems = allTasks.recommendationItems(matching: creativeScope)
        #expect(creativeItems.map(\.title) == ["Sketch garden"])

        var goalScope = RecommendationScope()
        goalScope.mode = .specificGoal
        goalScope.selectedGoalID = mcat.id
        let goalItems = allTasks.recommendationItems(matching: goalScope)
        #expect(goalItems.map(\.title) == ["Amino acids"])

        let rankedAnything = engine.rankedRecommendations(
            tasks: anything,
            availableTime: .thirty,
            energy: .good
        ).map(\.task.title)
        let rankedCareer = engine.rankedRecommendations(
            tasks: careerItems,
            availableTime: .thirty,
            energy: .good
        ).map(\.task.title)
        #expect(rankedAnything.count == 3)
        #expect(Set(rankedAnything) == Set(["Sketch garden", "Amino acids", "Update page"]))
        // Filtered ranking is the Anything order with out-of-scope titles removed — no reordering rules.
        #expect(rankedCareer == rankedAnything.filter { ["Sketch garden", "Update page"].contains($0) })
        #expect(Set(rankedCareer).count == rankedCareer.count)
    }

    @Test func notThisOneStaysWithinScopeAndEmptyDoesNotFallback() {
        let engine = RecommendationEngine()
        let a = TaskItem(
            title: "A",
            durationMinutes: 30,
            energyRequired: .good,
            area: "Career",
            goal: "Next",
            goalPriority: .high
        )
        let b = TaskItem(
            title: "B",
            durationMinutes: 30,
            energyRequired: .good,
            area: "Career",
            goal: "Portfolio",
            goalPriority: .normal
        )
        let ranked = engine.rankedRecommendations(tasks: [a, b], availableTime: .thirty, energy: .good)
        #expect(ranked.count == 2)
        #expect(ranked[0].task.title != ranked[1].task.title)

        #expect(
            RecommendationEmptyKindResolver.resolve(
                scope: .anything,
                scopedActiveTaskCount: 0,
                rankedCount: 0,
                hasAnyTasksInApp: true
            ) == .scopeHasNoActiveTasks
        )
        var needsArea = RecommendationScope()
        needsArea.mode = .lifeArea
        #expect(
            RecommendationEmptyKindResolver.resolve(
                scope: needsArea,
                scopedActiveTaskCount: 0,
                rankedCount: 0,
                hasAnyTasksInApp: true
            ) == .scopeNeedsSelection
        )
        #expect(
            RecommendationEmptyKindResolver.resolve(
                scope: .anything,
                scopedActiveTaskCount: 2,
                rankedCount: 0,
                hasAnyTasksInApp: true
            ) == .noneFitTimeAndEnergy
        )
    }

    @Test func deletedGoalInvalidatesSpecificScope() {
        var scope = RecommendationScope()
        scope.mode = .specificGoal
        let missing = UUID()
        scope.selectedGoalID = missing
        scope.validate(against: [])
        #expect(scope.selectedGoalID == nil)
        #expect(scope.isReady == false)
    }

    @Test func changingScopeModeClearsForeignSelection() {
        var scope = RecommendationScope()
        scope.mode = .lifeArea
        scope.selectedArea = .career
        scope.selectMode(.specificGoal)
        #expect(scope.selectedArea == nil)
        #expect(scope.selectedGoalID == nil)
        #expect(scope.isReady == false)
    }

    @Test func rankingHierarchyUnchangedWithinFilteredCandidates() {
        let engine = RecommendationEngine()
        let high = TaskItem(
            title: "High",
            durationMinutes: 30,
            energyRequired: .good,
            area: "Education",
            goal: "MCAT",
            goalPriority: .high
        )
        let normal = TaskItem(
            title: "Normal",
            durationMinutes: 45,
            energyRequired: .good,
            area: "Education",
            goal: "Book",
            goalPriority: .normal
        )
        let ranked = engine.rankedRecommendations(
            tasks: [normal, high],
            availableTime: .sixty,
            energy: .good
        )
        #expect(ranked.map(\.task.title) == ["High", "Normal"])
    }
}

// MARK: - V3-M2 Focus History Management

struct FocusSessionDeletionTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }

    /// Friday, 25 September 2026, noon UTC. Week (Monday start) is 21–27 Sep.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 25, hour: 12))!
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @MainActor
    @Test func deleteOneSessionAmongSeveralPreservesOthers() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let goal = Goal(title: "MCAT", area: .education, priority: .high)
        context.insert(goal)
        let keep = FocusSession(
            id: UUID(),
            completedAt: now,
            plannedDurationSeconds: 1800,
            focusedDurationSeconds: 1800,
            endedNaturally: true,
            taskWasFinished: false,
            taskTitleSnapshot: "Keep me",
            goalTitleSnapshot: "MCAT",
            goal: goal
        )
        let remove = FocusSession(
            id: UUID(),
            completedAt: now.addingTimeInterval(-3600),
            plannedDurationSeconds: 900,
            focusedDurationSeconds: 900,
            endedNaturally: true,
            taskWasFinished: true,
            taskTitleSnapshot: "Remove me",
            goalTitleSnapshot: "MCAT",
            goal: goal
        )
        context.insert(keep)
        context.insert(remove)
        try context.save()

        try PlanningStore.deleteFocusSession(remove, context: context)

        let remaining = try context.fetch(FetchDescriptor<FocusSession>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == keep.id)
        #expect(remaining.first?.taskTitleSnapshot == "Keep me")
        #expect(try context.fetch(FetchDescriptor<Goal>()).count == 1)
    }

    @MainActor
    @Test func deleteOneOfTwoIdenticalTitlesIndependently() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let goal = Goal(title: "MCAT", area: .education, priority: .high)
        context.insert(goal)
        let first = FocusSession(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!,
            completedAt: now,
            plannedDurationSeconds: 1800,
            focusedDurationSeconds: 1800,
            endedNaturally: true,
            taskWasFinished: false,
            taskTitleSnapshot: "Review amino acids",
            goalTitleSnapshot: "MCAT",
            goal: goal
        )
        let second = FocusSession(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!,
            completedAt: now.addingTimeInterval(-7200),
            plannedDurationSeconds: 1200,
            focusedDurationSeconds: 1200,
            endedNaturally: true,
            taskWasFinished: false,
            taskTitleSnapshot: "Review amino acids",
            goalTitleSnapshot: "MCAT",
            goal: goal
        )
        context.insert(first)
        context.insert(second)
        try context.save()

        try PlanningStore.deleteFocusSession(first, context: context)

        let remaining = try context.fetch(FetchDescriptor<FocusSession>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == second.id)
        #expect(remaining.first?.taskTitleSnapshot == "Review amino acids")
        #expect(remaining.first?.focusedDurationSeconds == 1200)
    }

    @MainActor
    @Test func weeklyMetricsRecalculateAndOlderDeletionLeavesCurrentWeekUnchanged() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let goal = Goal(title: "MCAT", area: .education, priority: .high)
        context.insert(goal)
        let thisWeek = FocusSession(
            completedAt: now,
            plannedDurationSeconds: 1800,
            focusedDurationSeconds: 1800,
            endedNaturally: true,
            taskWasFinished: true,
            taskTitleSnapshot: "This week",
            goalTitleSnapshot: "MCAT",
            goal: goal
        )
        let alsoThisWeek = FocusSession(
            completedAt: date(2026, 9, 23, 10),
            plannedDurationSeconds: 2700,
            focusedDurationSeconds: 2700,
            endedNaturally: true,
            taskWasFinished: false,
            taskTitleSnapshot: "Also this week",
            goalTitleSnapshot: "MCAT",
            goal: goal
        )
        let lastWeek = FocusSession(
            completedAt: date(2026, 9, 18, 10),
            plannedDurationSeconds: 3600,
            focusedDurationSeconds: 3600,
            endedNaturally: true,
            taskWasFinished: true,
            taskTitleSnapshot: "Last week",
            goalTitleSnapshot: "MCAT",
            goal: goal
        )
        [thisWeek, alsoThisWeek, lastWeek].forEach(context.insert)
        try context.save()

        let before = HistoryPresentation.weeklySummary(
            sessions: try context.fetch(FetchDescriptor<FocusSession>()).map(\.historyRecord),
            calendar: calendar,
            referenceDate: now
        )
        #expect(before.focusedDuration == 4500)
        #expect(before.sessionCount == 2)
        #expect(before.tasksFinished == 1)

        try PlanningStore.deleteFocusSession(lastWeek, context: context)

        let afterOlderDelete = HistoryPresentation.weeklySummary(
            sessions: try context.fetch(FetchDescriptor<FocusSession>()).map(\.historyRecord),
            calendar: calendar,
            referenceDate: now
        )
        #expect(afterOlderDelete == before)

        try PlanningStore.deleteFocusSession(alsoThisWeek, context: context)

        let afterWeekDelete = HistoryPresentation.weeklySummary(
            sessions: try context.fetch(FetchDescriptor<FocusSession>()).map(\.historyRecord),
            calendar: calendar,
            referenceDate: now
        )
        #expect(afterWeekDelete.focusedDuration == 1800)
        #expect(afterWeekDelete.sessionCount == 1)
        #expect(afterWeekDelete.tasksFinished == 1)
    }

    @MainActor
    @Test func gardenGrowthDropsBelowThresholdAfterDeletion() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let goal = Goal(title: "Build Next", area: .creative, priority: .normal)
        context.insert(goal)
        // 120 minutes → young; removing 90 leaves 30 → sprout.
        let long = FocusSession(
            completedAt: now,
            plannedDurationSeconds: 90 * 60,
            focusedDurationSeconds: 90 * 60,
            endedNaturally: true,
            taskWasFinished: false,
            goal: goal
        )
        let short = FocusSession(
            completedAt: now.addingTimeInterval(-100),
            plannedDurationSeconds: 30 * 60,
            focusedDurationSeconds: 30 * 60,
            endedNaturally: true,
            taskWasFinished: false,
            goal: goal
        )
        context.insert(long)
        context.insert(short)
        try context.save()
        #expect(goal.totalFocusedDuration == 120 * 60)
        #expect(goal.growthStage == .young)
        #expect(goal.sessionCount == 2)

        try PlanningStore.deleteFocusSession(long, context: context)

        #expect(goal.totalFocusedDuration == 30 * 60)
        #expect(goal.sessionCount == 1)
        #expect(goal.growthStage == .sprout)
        #expect(goal.plantVariant == .broadLeaf)
    }

    @MainActor
    @Test func recommendationRecencyFallsBackAfterDeletingLatestSession() throws {
        let engine = RecommendationEngine()
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let goal = Goal(title: "MCAT", area: .education, priority: .high)
        let other = Goal(title: "Portfolio", area: .career, priority: .high)
        context.insert(goal)
        context.insert(other)
        let task = GoalTask(title: "Amino", durationMinutes: 30, energyRequired: .good, goal: goal)
        let otherTask = GoalTask(title: "Page", durationMinutes: 30, energyRequired: .good, goal: other)
        context.insert(task)
        context.insert(otherTask)

        let older = now.addingTimeInterval(-3 * 24 * 60 * 60)
        let latest = now.addingTimeInterval(-20 * 60)
        context.insert(
            FocusSession(
                completedAt: older,
                plannedDurationSeconds: 1800,
                focusedDurationSeconds: 1800,
                endedNaturally: true,
                taskWasFinished: false,
                goal: goal,
                task: task
            )
        )
        let latestSession = FocusSession(
            completedAt: latest,
            plannedDurationSeconds: 1800,
            focusedDurationSeconds: 1800,
            endedNaturally: true,
            taskWasFinished: false,
            goal: goal,
            task: task
        )
        context.insert(latestSession)
        try context.save()

        #expect(goal.lastFocusedAt == latest)

        try PlanningStore.deleteFocusSession(latestSession, context: context)
        #expect(goal.lastFocusedAt == older)

        let items = [task, otherTask].recommendationItems
        #expect(items.first(where: { $0.title == "Amino" })?.lastFocusedAt == older)

        // Delete remaining session → never-focused semantics for this goal.
        let remaining = try context.fetch(FetchDescriptor<FocusSession>()).first { $0.goal?.id == goal.id }
        if let remaining {
            try PlanningStore.deleteFocusSession(remaining, context: context)
        }
        #expect(goal.lastFocusedAt == nil)
        let neverFocused = [task, otherTask].recommendationItems
        #expect(neverFocused.first(where: { $0.title == "Amino" })?.lastFocusedAt == nil)

        let ranked = engine.rankedRecommendations(
            tasks: neverFocused,
            availableTime: .thirty,
            energy: .good
        )
        #expect(ranked.map(\.task.title).contains("Amino"))
    }

    @MainActor
    @Test func deleteSessionWithNullGoalAndTaskRelationships() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let orphan = FocusSession(
            completedAt: now,
            plannedDurationSeconds: 1800,
            focusedDurationSeconds: 1800,
            endedNaturally: true,
            taskWasFinished: false,
            taskTitleSnapshot: "Orphan task",
            goalTitleSnapshot: "Orphan goal",
            goal: nil,
            task: nil
        )
        context.insert(orphan)
        let untouched = Goal(title: "Keep", area: .personal, priority: .normal)
        context.insert(untouched)
        try context.save()

        try PlanningStore.deleteFocusSession(orphan, context: context)

        #expect(try context.fetch(FetchDescriptor<FocusSession>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Goal>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Goal>()).first?.title == "Keep")
    }

    @MainActor
    @Test func deletionPersistsAcrossContainerRelaunch() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-v3m2-delete-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        let keepID = UUID()
        let removeID = UUID()

        do {
            let container = try NextPersistence.makeContainer(storeURL: url)
            let context = ModelContext(container)
            let goal = Goal(title: "MCAT", area: .education, priority: .high)
            context.insert(goal)
            context.insert(
                FocusSession(
                    id: keepID,
                    completedAt: now,
                    plannedDurationSeconds: 1800,
                    focusedDurationSeconds: 1800,
                    endedNaturally: true,
                    taskWasFinished: false,
                    taskTitleSnapshot: "Keep",
                    goalTitleSnapshot: "MCAT",
                    goal: goal
                )
            )
            let remove = FocusSession(
                id: removeID,
                completedAt: now.addingTimeInterval(-60),
                plannedDurationSeconds: 600,
                focusedDurationSeconds: 600,
                endedNaturally: true,
                taskWasFinished: false,
                taskTitleSnapshot: "Remove",
                goalTitleSnapshot: "MCAT",
                goal: goal
            )
            context.insert(remove)
            try context.save()
            try PlanningStore.deleteFocusSession(remove, context: context)
        }

        let reopened = try NextPersistence.makeContainer(storeURL: url)
        let context = ModelContext(reopened)
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.id == keepID)
        #expect(sessions.contains(where: { $0.id == removeID }) == false)
        #expect(try context.fetch(FetchDescriptor<Goal>()).count == 1)
    }

    @MainActor
    @Test func hasFocusedTodayReflectsRemainingSessionsAfterDeletion() throws {
        let context = ModelContext(try NextPersistence.makeInMemoryContainer())
        let goal = Goal(title: "MCAT", area: .education, priority: .high)
        context.insert(goal)
        let today = FocusSession(
            completedAt: now,
            plannedDurationSeconds: 1800,
            focusedDurationSeconds: 1800,
            endedNaturally: true,
            taskWasFinished: false,
            goal: goal
        )
        context.insert(today)
        try context.save()
        #expect(DailyReminderCoordinator.hasFocusedToday(context: context, now: now, calendar: calendar))

        try PlanningStore.deleteFocusSession(today, context: context)
        #expect(!DailyReminderCoordinator.hasFocusedToday(context: context, now: now, calendar: calendar))
    }
}


