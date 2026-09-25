//
//  NextTests.swift
//  NextTests
//
//  Created by Christian Lua-Lua on 9/25/26.
//

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
