//
//  FocusView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftUI

struct FocusView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    let task: TaskItem
    let onDone: () -> Void

    @State private var session: FocusSessionTimer
    @State private var now = Date()

    init(task: TaskItem, onDone: @escaping () -> Void = {}) {
        self.task = task
        self.onDone = onDone
        _session = State(initialValue: FocusSessionTimer(durationMinutes: task.durationMinutes))
    }

    private var canvasColor: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.12, blue: 0.11)
            : Color(red: 0.98, green: 0.97, blue: 0.94)
    }

    private var isEnded: Bool {
        session.phase == .ended
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NEXT")
                .font(.system(size: 13, weight: .medium))
                .tracking(3.2)
                .foregroundStyle(.secondary)

            taskHeader
                .padding(.top, 36)

            Spacer(minLength: 32)

            timerDisplay
                .frame(maxWidth: .infinity)

            Spacer(minLength: 32)

            controls
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(canvasColor.ignoresSafeArea())
        .task { await runDisplayClock() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refresh(at: Date())
        }
    }

    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(task.title)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.primary)

            Text(task.goal.uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(1.8)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var timerDisplay: some View {
        Text(session.remainingDisplay(at: now))
            .font(.system(size: 72, weight: .regular, design: .monospaced))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Time remaining")
            .accessibilityValue(accessibilityRemaining)
            .accessibilityIdentifier("focusTimer")
    }

    private var accessibilityRemaining: String {
        let total = session.remainingSeconds(at: now)
        let minutes = total / 60
        let seconds = total % 60
        return "\(minutes) minutes, \(seconds) seconds"
    }

    @ViewBuilder
    private var controls: some View {
        if isEnded {
            endedControls
        } else {
            activeControls
        }
    }

    private var activeControls: some View {
        VStack(spacing: 18) {
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)

            Button(session.phase == .paused ? "RESUME" : "PAUSE") {
                togglePause()
            }
            .font(.system(size: 13, weight: .semibold))
            .tracking(2.2)
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, minHeight: 44)
            .animation(.easeInOut(duration: 0.18), value: session.phase)

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)

            Button("Finish early") {
                session.finish(at: Date())
                now = Date()
            }
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    private var endedControls: some View {
        VStack(spacing: 18) {
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)

            Text("SESSION ENDED")
                .font(.system(size: 13, weight: .medium))
                .tracking(2.2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 44)

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)

            Button("Done") {
                onDone()
            }
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .accessibilityElement(children: .contain)
    }

    private func togglePause() {
        let current = Date()
        if session.phase == .running {
            session.pause(at: current)
        } else if session.phase == .paused {
            session.resume(at: current)
        }
        now = current
    }

    private func refresh(at current: Date) {
        now = current
        session.evaluateCompletion(at: current)
    }

    private func runDisplayClock() async {
        refresh(at: Date())
        while !Task.isCancelled {
            if session.phase == .ended { break }
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
