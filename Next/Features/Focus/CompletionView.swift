//
//  CompletionView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftData
import SwiftUI

struct CompletionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Goal.createdAt) private var goals: [Goal]

    let result: FocusSessionResult
    /// Stable id for exactly-once FocusSession persistence across recovery.
    var experienceID: UUID? = nil
    let onFinished: () -> Void

    @State private var completion = SessionCompletionState()
    @State private var didCommit = false

    private var relatedGoal: Goal? {
        if let id = result.task.goalID {
            return goals.first { $0.id == id }
        }
        return goals.first { $0.title == result.task.goal }
    }

    private var botanicalAcknowledgement: String? {
        guard completion.taskCompletion != nil else { return nil }
        let previous = relatedGoal?.growthStage ?? GardenGrowth.stage(for: 0)
        let accumulated = (relatedGoal?.totalFocusedDuration ?? 0) + result.focusedDurationSeconds
        return GardenAcknowledgement.message(
            goalTitle: result.task.goal,
            previousStage: previous,
            nextStage: GardenGrowth.stage(for: accumulated)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NEXT")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(3.2)
                .foregroundStyle(NextTheme.secondary)

            acknowledgement
                .padding(.top, 36)

            sessionSummary
                .padding(.top, 28)

            Spacer(minLength: 36)

            completionQuestion

            Spacer(minLength: 36)

            exitActions
        }
        .nextScrollableCanvas(top: 16)
    }

    private var acknowledgement: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "checkmark")
                .nextFont(22, relativeTo: .title3)
                .foregroundStyle(NextTheme.botanical)
                .accessibilityHidden(true)

            Text("NICE WORK.")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(2.2)
                .foregroundStyle(NextTheme.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nice work")
    }

    private var sessionSummary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(result.task.title)
                .nextFont(28, relativeTo: .title)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(result.focusedDurationLabel)
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.botanical)
                .padding(.top, 14)

            Text(result.task.goal.uppercased())
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 28)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(result.task.title). \(GardenMetrics.focusedDurationSpoken(seconds: result.focusedDurationSeconds)). \(result.task.goal)."
        )
    }

    private var completionQuestion: some View {
        VStack(alignment: .leading, spacing: 22) {
            NextHairline()

            Text("Did you finish it?")
                .nextFont(17)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                completionOption("YES", status: .completed)
                completionOption("NOT YET", status: .notCompleted)
            }

            if let botanicalAcknowledgement {
                Text(botanicalAcknowledgement)
                    .nextFont(17)
                    .foregroundStyle(NextTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                    .accessibilityIdentifier("gardenAcknowledgement")
            }

            NextHairline()
        }
        .accessibilityElement(children: .contain)
    }

    private func completionOption(_ title: String, status: TaskCompletionStatus) -> some View {
        let isSelected = completion.taskCompletion == status

        return Button {
            completion.select(status)
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .nextFont(16, weight: isSelected ? .medium : .regular)
                    .foregroundStyle(isSelected ? NextTheme.botanical : NextTheme.ink)

                Capsule()
                    .fill(isSelected ? NextTheme.botanical : Color.clear)
                    .frame(width: 18, height: 2)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private var exitActions: some View {
        VStack(spacing: 8) {
            Button("WHAT'S NEXT? →") {
                commitAndFinish()
            }
            .nextFont(13, weight: .semibold)
            .tracking(2.2)
            .foregroundStyle(completion.canContinue ? NextTheme.botanical : NextTheme.disabled)
            .frame(maxWidth: .infinity, minHeight: 44)
            .disabled(!completion.canContinue)

            Button("I'M DONE") {
                commitAndFinish()
            }
            .nextFont(16)
            .foregroundStyle(completion.canContinue ? NextTheme.ink : NextTheme.disabled)
            .frame(maxWidth: .infinity, minHeight: 44)
            .disabled(!completion.canContinue)
        }
    }

    private func commitAndFinish() {
        guard !didCommit else { return }
        guard let answer = completion.taskCompletion else { return }
        didCommit = true
        do {
            try FocusSessionStore.commit(
                result: result,
                taskWasFinished: answer == .completed,
                context: modelContext,
                experienceID: experienceID
            )
            // Clear recovery only after a successful commit (or idempotent replay).
            FocusRecoveryStore.clear()
            onFinished()
        } catch {
            // Keep awaiting-completion snapshot; stay on Completion for retry.
            // Idempotent experienceID commit prevents duplicates on success.
            didCommit = false
        }
    }
}

#Preview {
    CompletionView(
        result: FocusSessionResult(
            task: TaskItem(
                title: "Review amino acids",
                durationMinutes: 25,
                energyRequired: .good,
                area: "Education",
                goal: "Study for MCAT"
            ),
            plannedDurationSeconds: 25 * 60,
            focusedDurationSeconds: 23 * 60,
            endedNaturally: false
        ),
        onFinished: {}
    )
    .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
