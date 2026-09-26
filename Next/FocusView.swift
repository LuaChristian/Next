//
//  FocusView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftUI
import UIKit

struct FocusView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let task: TaskItem
    let onDone: () -> Void
    let notifications: FocusNotificationCoordinator

    @State private var session: FocusSessionTimer
    @State private var now = Date()
    @State private var result: FocusSessionResult?
    @State private var keepScreenAwake = FocusPreference.keepScreenAwake()
    @State private var showingFocusSettings = false
    @State private var didPlayCompletionHaptic = false

    init(
        task: TaskItem,
        notifications: FocusNotificationCoordinator = .shared,
        onDone: @escaping () -> Void = {}
    ) {
        self.task = task
        self.notifications = notifications
        self.onDone = onDone
        _session = State(initialValue: FocusSessionTimer(durationMinutes: task.durationMinutes))
    }

    var body: some View {
        Group {
            if let result {
                CompletionView(result: result, onFinished: finishAndRestore)
            } else {
                focusContent
            }
        }
        .onDisappear(perform: restoreIdleTimer)
    }

    private var focusContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
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
            guard phase == .active else {
                applyIdleTimer()
                return
            }
            refresh(at: Date(), allowHaptic: false)
        }
        .onChange(of: keepScreenAwake) { _, isOn in
            FocusPreference.setKeepScreenAwake(isOn)
            applyIdleTimer()
        }
        .sheet(isPresented: $showingFocusSettings) {
            FocusSettingsView(keepScreenAwake: $keepScreenAwake)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("NEXT")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(3.2)
                .foregroundStyle(NextTheme.secondary)

            Spacer()

            Button {
                showingFocusSettings = true
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(NextTheme.ink)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Focus settings")
            .accessibilityIdentifier("focusSettings")
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
                captureResult(after: { $0.finish(at: $1) }, at: Date(), allowHaptic: false)
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
        applyIdleTimer()
        syncNotifications(at: current)
        captureResultIfEnded(at: current, allowHaptic: scenePhase == .active)
    }

    private func refresh(at current: Date, allowHaptic: Bool) {
        now = current
        session.evaluateCompletion(at: current)
        applyIdleTimer()
        captureResultIfEnded(at: current, allowHaptic: allowHaptic)
    }

    private func captureResult(
        after mutation: (inout FocusSessionTimer, Date) -> Void,
        at current: Date,
        allowHaptic: Bool
    ) {
        mutation(&session, current)
        now = current
        applyIdleTimer()
        captureResultIfEnded(at: current, allowHaptic: allowHaptic)
    }

    private func captureResultIfEnded(at current: Date, allowHaptic: Bool) {
        guard result == nil else { return }
        result = session.makeResult(for: task, at: current)
        guard result != nil else { return }
        applyIdleTimer()
        syncNotifications(at: current)
        if allowHaptic, result?.endedNaturally == true {
            playNaturalCompletionHaptic()
        }
    }

    private func playNaturalCompletionHaptic() {
        guard !didPlayCompletionHaptic else { return }
        didPlayCompletionHaptic = true
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    private func syncNotifications(at current: Date) {
        let timer = session
        let title = task.title
        let coordinator = notifications
        Task {
            await coordinator.sync(timer: timer, taskTitle: title, at: current)
        }
    }

    private func applyIdleTimer() {
        FocusIdleTimer.isDisabled = FocusIdleTimerPolicy.isIdleTimerDisabled(
            keepScreenAwake: keepScreenAwake,
            phase: session.phase,
            sceneActive: result == nil && scenePhase == .active
        )
    }

    private func restoreIdleTimer() {
        FocusIdleTimer.isDisabled = false
        notifications.cancel()
    }

    private func finishAndRestore() {
        restoreIdleTimer()
        onDone()
    }

    private func runDisplayClock() async {
        refresh(at: Date(), allowHaptic: scenePhase == .active)
        syncNotifications(at: Date())
        while !Task.isCancelled {
            if result != nil { break }
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { break }
            refresh(at: Date(), allowHaptic: scenePhase == .active)
        }
    }
}

private struct FocusSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var keepScreenAwake: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("FOCUS")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(2.2)
                .foregroundStyle(NextTheme.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Text("Keep Screen Awake")
                    .nextFont(20, relativeTo: .title3)
                    .foregroundStyle(NextTheme.ink)
                Text("Keep the display on while a focus session is actively running.")
                    .nextFont(16)
                    .foregroundStyle(NextTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Toggle("Keep Screen Awake", isOn: $keepScreenAwake)
                    .labelsHidden()
                    .tint(NextTheme.botanical)
                    .accessibilityLabel("Keep Screen Awake")
                    .accessibilityIdentifier("keepScreenAwake")
                    .accessibilityHint("Keep the display on while a focus session is actively running.")
            }
            .padding(.top, 36)

            Spacer(minLength: 24)

            NextPrimaryAction(title: "DONE") {
                dismiss()
            }
        }
        .nextCanvas(top: 16)
        .presentationDetents([.height(320), .medium])
        .presentationDragIndicator(.visible)
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
