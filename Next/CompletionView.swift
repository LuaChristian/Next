//
//  CompletionView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftData
import SwiftUI

struct CompletionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    let result: FocusSessionResult
    let onFinished: () -> Void

    @State private var completion = SessionCompletionState()
    @State private var didCommit = false

    private var canvasColor: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.12, blue: 0.11)
            : Color(red: 0.98, green: 0.97, blue: 0.94)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NEXT")
                .font(.system(size: 13, weight: .medium))
                .tracking(3.2)
                .foregroundStyle(.secondary)

            acknowledgement
                .padding(.top, 36)

            sessionSummary
                .padding(.top, 28)

            Spacer(minLength: 36)

            completionQuestion

            Spacer(minLength: 36)

            exitActions
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(canvasColor.ignoresSafeArea())
    }

    private var acknowledgement: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "checkmark")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            Text("NICE WORK.")
                .font(.system(size: 13, weight: .medium))
                .tracking(2.2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nice work")
    }

    private var sessionSummary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(result.task.title)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.primary)

            Text(result.focusedDurationLabel)
                .font(.system(size: 13, weight: .medium))
                .tracking(1.8)
                .foregroundStyle(Color.accentColor)
                .padding(.top, 14)

            Text(result.task.goal.uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(1.8)
                .foregroundStyle(.secondary)
                .padding(.top, 28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var completionQuestion: some View {
        VStack(alignment: .leading, spacing: 22) {
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)

            Text("Did you finish it?")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                completionOption("YES", status: .completed)
                completionOption("NOT YET", status: .notCompleted)
            }

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)
        }
    }

    private func completionOption(_ title: String, status: TaskCompletionStatus) -> some View {
        let isSelected = completion.taskCompletion == status

        return Button {
            completion.select(status)
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.primary)

                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(width: 18, height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var exitActions: some View {
        VStack(spacing: 8) {
            Button("WHAT'S NEXT? →") {
                commitAndFinish()
            }
            .font(.system(size: 13, weight: .semibold))
            .tracking(2.2)
            .foregroundStyle(completion.canContinue ? Color.accentColor : Color.secondary.opacity(0.45))
            .frame(maxWidth: .infinity, minHeight: 44)
            .disabled(!completion.canContinue)

            Button("I'M DONE") {
                commitAndFinish()
            }
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(completion.canContinue ? Color.primary : Color.secondary.opacity(0.45))
            .frame(maxWidth: .infinity, minHeight: 44)
            .disabled(!completion.canContinue)
        }
    }

    private func commitAndFinish() {
        guard !didCommit else { return }
        didCommit = true
        if let answer = completion.taskCompletion {
            do {
                try FocusSessionStore.commit(
                    result: result,
                    taskWasFinished: answer == .completed,
                    context: modelContext
                )
            } catch {
                // Leave Completion without claiming Garden progress.
            }
        }
        onFinished()
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
