//
//  NextTests.swift
//  NextTests
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation
import Testing
@testable import Next

struct RecommendationEngineTests {
    private let engine = RecommendationEngine()

    private let amino = TaskItem(
        title: "Review amino acids",
        durationMinutes: 25,
        energyRequired: .good,
        area: "Education",
        goal: "Study for MCAT"
    )
    private let clean = TaskItem(
        title: "Clean your space",
        durationMinutes: 15,
        energyRequired: .low,
        area: "Personal",
        goal: "Keep your space organized"
    )
    private let coding = TaskItem(
        title: "Coding practice",
        durationMinutes: 45,
        energyRequired: .ready,
        area: "Career",
        goal: "Improve programming"
    )
    private let flashcards = TaskItem(
        title: "Review flashcards",
        durationMinutes: 15,
        energyRequired: .low,
        area: "Education",
        goal: "Study for MCAT"
    )

    @Test func timeFilterExcludesTasksThatExceedAvailableTime() {
        let result = engine.recommendations(
            tasks: [coding, amino],
            availableTime: .thirty,
            energy: .ready
        )

        #expect(result.contains(where: { $0.id == coding.id }) == false)
        #expect(result.contains(where: { $0.id == amino.id }))
    }

    @Test func energyFilterExcludesTasksThatRequireMoreEnergy() {
        let result = engine.recommendations(
            tasks: [coding, amino],
            availableTime: .sixty,
            energy: .good
        )

        #expect(result.contains(where: { $0.id == coding.id }) == false)
        #expect(result.contains(where: { $0.id == amino.id }))
    }

    @Test func lowerEnergyTasksRemainEligible() {
        let result = engine.recommendations(
            tasks: [clean],
            availableTime: .thirty,
            energy: .good
        )

        #expect(result.contains(where: { $0.id == clean.id }))
    }

    @Test func betterTimeFitRanksHigher() {
        let result = engine.recommendations(
            tasks: [flashcards, amino],
            availableTime: .thirty,
            energy: .good
        )

        #expect(result.map(\.id) == [amino.id, flashcards.id])
    }

    @Test func closerEnergyRanksHigherWhenDurationMatches() {
        let low = TaskItem(
            title: "Low energy match",
            durationMinutes: 20,
            energyRequired: .low,
            area: "Personal",
            goal: "Rest"
        )
        let good = TaskItem(
            title: "Good energy match",
            durationMinutes: 20,
            energyRequired: .good,
            area: "Education",
            goal: "Study"
        )

        let result = engine.recommendations(
            tasks: [low, good],
            availableTime: .thirty,
            energy: .good
        )

        #expect(result.map(\.id) == [good.id, low.id])
    }

    @Test func rankingIsDeterministic() {
        let tasks = [coding, flashcards, amino, clean]

        let first = engine.recommendations(
            tasks: tasks,
            availableTime: .thirty,
            energy: .good
        )
        let second = engine.recommendations(
            tasks: tasks,
            availableTime: .thirty,
            energy: .good
        )

        #expect(first.map(\.id) == second.map(\.id))
        #expect(first.map(\.id) == [amino.id, flashcards.id, clean.id])
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

struct AppStoreTests {
    private let engine = RecommendationEngine()

    @Test func addGoalStoresTitleAreaAndPriority() {
        let store = AppStore()
        let goal = store.addGoal(title: "Study for MCAT", area: .education, priority: .high)

        #expect(store.goals.count == 1)
        #expect(goal.title == "Study for MCAT")
        #expect(goal.area == .education)
        #expect(goal.priority == .high)
        #expect(goal.tasks.isEmpty)
    }

    @Test func addTaskAppearsOnTheCorrectGoal() {
        let store = AppStore()
        let goal = store.addGoal(title: "Study for MCAT", area: .education, priority: .high)
        let task = store.addTask(
            to: goal.id,
            title: "Review amino acids",
            durationMinutes: 30,
            energyRequired: .good
        )

        #expect(store.goal(id: goal.id)?.tasks.count == 1)
        #expect(task?.title == "Review amino acids")
        #expect(task?.durationMinutes == 30)
        #expect(task?.energyRequired == .good)
        #expect(task?.area == "Education")
        #expect(task?.goal == "Study for MCAT")
    }

    @Test func taskDoesNotAppearOnADifferentGoal() {
        let store = AppStore()
        let mcat = store.addGoal(title: "Study for MCAT", area: .education, priority: .high)
        let next = store.addGoal(title: "Build Next", area: .creative, priority: .normal)
        store.addTask(
            to: mcat.id,
            title: "Review amino acids",
            durationMinutes: 30,
            energyRequired: .good
        )

        #expect(store.goal(id: mcat.id)?.tasks.count == 1)
        #expect(store.goal(id: next.id)?.tasks.isEmpty == true)
        #expect(store.allTasks.count == 1)
    }

    @Test func userCreatedTaskCanBeRecommended() {
        let store = AppStore()
        let goal = store.addGoal(title: "Study for MCAT", area: .education, priority: .high)
        store.addTask(
            to: goal.id,
            title: "Review amino acids",
            durationMinutes: 30,
            energyRequired: .good
        )

        let result = engine.recommendations(
            tasks: store.allTasks,
            availableTime: .thirty,
            energy: .good
        )

        #expect(result.count == 1)
        #expect(result.first?.title == "Review amino acids")
        #expect(result.first?.area == "Education")
        #expect(result.first?.goal == "Study for MCAT")
    }

    @Test func userCreatedTaskStillRespectsTimeFilter() {
        let store = AppStore()
        let goal = store.addGoal(title: "Study for MCAT", area: .education, priority: .high)
        store.addTask(
            to: goal.id,
            title: "Practice biology questions",
            durationMinutes: 45,
            energyRequired: .good
        )

        let result = engine.recommendations(
            tasks: store.allTasks,
            availableTime: .thirty,
            energy: .good
        )

        #expect(result.isEmpty)
    }

    @Test func userCreatedTaskStillRespectsEnergyFilter() {
        let store = AppStore()
        let goal = store.addGoal(title: "Study for MCAT", area: .education, priority: .high)
        store.addTask(
            to: goal.id,
            title: "Practice biology questions",
            durationMinutes: 30,
            energyRequired: .ready
        )

        let result = engine.recommendations(
            tasks: store.allTasks,
            availableTime: .thirty,
            energy: .good
        )

        #expect(result.isEmpty)
    }

    @Test func productionStoreStartsEmpty() {
        #expect(AppStore().goals.isEmpty)
        #expect(AppStore().allTasks.isEmpty)
    }
}
