//
//  OnboardingState.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation
import SwiftData

struct OnboardingGoalSuggestion: Identifiable, Hashable {
    let title: String
    let area: GoalArea

    var id: String {
        "\(area.rawValue)|\(title)"
    }

    static let all: [OnboardingGoalSuggestion] = [
        .init(title: "Study for an exam", area: .education),
        .init(title: "Learn a new skill", area: .education),
        .init(title: "Read more", area: .education),
        .init(title: "Complete a course", area: .education),
        .init(title: "Prepare for interviews", area: .career),
        .init(title: "Improve a professional skill", area: .career),
        .init(title: "Build my portfolio", area: .career),
        .init(title: "Work toward a career goal", area: .career),
        .init(title: "Exercise consistently", area: .fitness),
        .init(title: "Build strength", area: .fitness),
        .init(title: "Improve endurance", area: .fitness),
        .init(title: "Become more active", area: .fitness),
        .init(title: "Build a project", area: .creative),
        .init(title: "Make more time to create", area: .creative),
        .init(title: "Practice a creative skill", area: .creative),
        .init(title: "Finish something I started", area: .creative),
        .init(title: "Build a healthier routine", area: .wellness),
        .init(title: "Make time to recharge", area: .wellness),
        .init(title: "Improve my sleep routine", area: .wellness),
        .init(title: "Practice mindfulness", area: .wellness),
        .init(title: "Build my savings", area: .finance),
        .init(title: "Create a budget", area: .finance),
        .init(title: "Pay down debt", area: .finance),
        .init(title: "Save for something important", area: .finance),
        .init(title: "Spend more time with friends", area: .social),
        .init(title: "Stay in touch with family", area: .social),
        .init(title: "Meet new people", area: .social),
        .init(title: "Make time for relationships", area: .social),
        .init(title: "Get more organized", area: .personal),
        .init(title: "Build a new habit", area: .personal),
        .init(title: "Make time for myself", area: .personal),
        .init(title: "Work on a personal goal", area: .personal)
    ]

    static func suggestion(titled title: String) -> OnboardingGoalSuggestion? {
        all.first { $0.title == title }
    }

    static func suggestions(for areas: Set<GoalArea>) -> [OnboardingGoalSuggestion] {
        all.filter { areas.contains($0.area) }
    }
}

struct OnboardingPendingGoal: Identifiable, Hashable {
    let id: UUID
    let title: String
    let area: GoalArea

    init(id: UUID = UUID(), title: String, area: GoalArea) {
        self.id = id
        self.title = title
        self.area = area
    }
}

struct OnboardingState: Equatable {
    var selectedAreas: Set<GoalArea> = []
    var selectedSuggestionIDs: Set<String> = []
    var customGoals: [OnboardingPendingGoal] = []
    var didCommit = false

    var visibleSuggestions: [OnboardingGoalSuggestion] {
        OnboardingGoalSuggestion.suggestions(for: selectedAreas)
    }

    var pendingGoals: [OnboardingPendingGoal] {
        let suggested = OnboardingGoalSuggestion.all
            .filter { selectedSuggestionIDs.contains($0.id) }
            .map { OnboardingPendingGoal(title: $0.title, area: $0.area) }
        return suggested + customGoals
    }

    var canContinueFromAreas: Bool {
        !selectedAreas.isEmpty
    }

    var canContinueFromGoals: Bool {
        !pendingGoals.isEmpty
    }

    mutating func toggleArea(_ area: GoalArea) {
        if selectedAreas.contains(area) {
            selectedAreas.remove(area)
        } else {
            selectedAreas.insert(area)
        }
        removeGoalsOutsideSelectedAreas()
    }

    mutating func toggleSuggestion(_ suggestion: OnboardingGoalSuggestion) {
        guard selectedAreas.contains(suggestion.area) else { return }
        if selectedSuggestionIDs.contains(suggestion.id) {
            selectedSuggestionIDs.remove(suggestion.id)
        } else {
            selectedSuggestionIDs.insert(suggestion.id)
        }
    }

    mutating func addCustomGoal(title: String, area: GoalArea) {
        guard let trimmed = NextInput.trimmedTitle(title), selectedAreas.contains(area) else { return }
        customGoals.append(OnboardingPendingGoal(title: trimmed, area: area))
    }

    mutating func removeCustomGoal(_ goal: OnboardingPendingGoal) {
        customGoals.removeAll { $0.id == goal.id }
    }

    mutating func removeGoalsOutsideSelectedAreas() {
        selectedSuggestionIDs = Set(
            OnboardingGoalSuggestion.all
                .filter { selectedSuggestionIDs.contains($0.id) && selectedAreas.contains($0.area) }
                .map(\.id)
        )
        customGoals.removeAll { !selectedAreas.contains($0.area) }
    }

    mutating func complete(into context: ModelContext, defaults: UserDefaults? = nil) {
        guard !didCommit else { return }
        didCommit = true

        for pending in pendingGoals {
            context.insert(Goal(title: pending.title, area: pending.area, priority: .normal))
        }
        try? context.save()
        OnboardingPreference.markCompleted(in: defaults)
    }

    mutating func skip(defaults: UserDefaults? = nil) {
        guard !didCommit else { return }
        didCommit = true
        OnboardingPreference.markCompleted(in: defaults)
    }
}
