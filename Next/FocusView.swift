//
//  FocusView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftUI

struct FocusView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let task: TaskItem
    let onDone: () -> Void

    @State private var session: FocusSessionTimer
    @State private var now = Date()
    @State private var result: FocusSessionResult?

    init(task: TaskItem, onDone: @escaping () -> Void = {}) {
        self.task = task
        self.onDone = onDone
        _session = State(initialValue: FocusSessionTimer(durationMinutes: task.durationMinutes))
    }

    var body: some View {
        if let result {
            CompletionView(result: result, onFinished: onDone)
        } else {
            focusContent
        }
    }

    private var focusContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NEXT")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(3.2)
                .foregroundStyle(NextTheme.secondary)

            taskHeader
                .padding(.top, 36)

            Spacer(minLength: 32)

            timerDisplay
                .frame(maxWidth: .infinity)

            Spacer(minLength: 32)

            activeControls
        }
        .nextScrollableCanvas(top: 16)
        .task { await runDisplayClock() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refresh(at: Date())
        }
    }

    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(task.title)
                .nextFont(28, relativeTo: .title)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(task.goal.uppercased())
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .contain)
    }

    private var timerDisplay: some View {
        Text(session.remainingDisplay(at: now))
            .font(.system(size: timerSize, weight: .regular, design: .monospaced))
            .monospacedDigit()
            .foregroundStyle(NextTheme.ink)
            .minimumScaleFactor(0.55)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Time remaining")
            .accessibilityValue(accessibilityRemaining)
            .accessibilityIdentifier("focusTimer")
    }

    private var timerSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 48 : 72
    }

    private var accessibilityRemaining: String {
        let total = session.remainingSeconds(at: now)
        let minutes = total / 60
        let seconds = total % 60
        return "\(minutes) minutes, \(seconds) seconds"
    }

    private var activeControls: some View {
        VStack(spacing: 18) {
            NextHairline()

            Button(session.phase == .paused ? "RESUME" : "PAUSE") {
                togglePause()
            }
            .nextFont(13, weight: .semibold)
            .tracking(2.2)
            .foregroundStyle(NextTheme.botanical)
            .frame(maxWidth: .infinity, minHeight: 44)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: session.phase)

            NextHairline()

            Button("Finish early") {
                captureResult(after: { $0.finish(at: $1) }, at: Date())
            }
            .nextFont(16)
            .foregroundStyle(NextTheme.secondary)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    private func togglePause() {
        let current = Date()
        if session.phase == .running {
            session.pause(at: current)
        } else if session.phase == .paused {
            session.resume(at: current)
        }
        now = current
        captureResultIfEnded(at: current)
    }

    private func refresh(at current: Date) {
        now = current
        session.evaluateCompletion(at: current)
        captureResultIfEnded(at: current)
    }

    private func captureResult(
        after mutation: (inout FocusSessionTimer, Date) -> Void,
        at current: Date
    ) {
        mutation(&session, current)
        now = current
        captureResultIfEnded(at: current)
    }

    private func captureResultIfEnded(at current: Date) {
        guard result == nil else { return }
        result = session.makeResult(for: task, at: current)
    }

    private func runDisplayClock() async {
        refresh(at: Date())
        while !Task.isCancelled {
            if result != nil { break }
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { break }
            refresh(at: Date())
        }
    }
}

#Preview("Focus") {
    FocusView(
        task: TaskItem(
            title: "Review amino acids",
            durationMinutes: 25,
            energyRequired: .good,
            area: "Education",
            goal: "Study for MCAT"
        )
    )
}
