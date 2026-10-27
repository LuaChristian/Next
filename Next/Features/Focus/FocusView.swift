//
//  FocusView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftUI
import UIKit

private enum FocusRunMode: Equatable {
    case simple(FocusSessionTimer)
    case pomodoro(PomodoroSessionTimer)

    var phase: FocusSessionPhase {
        switch self {
        case .simple(let timer): return timer.phase
        case .pomodoro(let timer): return timer.phase
        }
    }
}

/// Focus UI and its default notification coordinator are MainActor-bound.
/// Explicit isolation removes the Swift 6 warning on `FocusNotificationCoordinator.shared`
/// as a default argument (evaluated in a nonisolated context otherwise).
@MainActor
struct FocusView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let task: TaskItem
    let onDone: () -> Void
    let notifications: FocusNotificationCoordinator

    @State private var experienceID: UUID
    @State private var mode: FocusRunMode
    @State private var now = Date()
    @State private var result: FocusSessionResult?
    @State private var bankedFocusSeconds: TimeInterval = 0
    @State private var keepScreenAwake = FocusPreference.keepScreenAwake()
    @State private var showingFocusSettings = false
    @State private var showingPomodoroConfig = false
    @State private var pomodoroDraft = PomodoroPreference.configuration()
    @State private var confirmingSwitchToSimple = false
    @State private var didPlayCompletionHaptic = false
    @State private var isEndingSession = false
    @State private var isSwitchingMode = false
    @State private var didClearRecovery = false

    /// Convenience for production call sites. Resolves `.shared` in the
    /// MainActor-isolated body (default-argument expressions stay nonisolated).
    init(
        task: TaskItem,
        bootstrap: FocusRecoveryBootstrap? = nil,
        onDone: @escaping () -> Void = {}
    ) {
        self.init(
            task: task,
            bootstrap: bootstrap,
            notifications: FocusNotificationCoordinator.shared,
            onDone: onDone
        )
    }

    init(
        task: TaskItem,
        bootstrap: FocusRecoveryBootstrap? = nil,
        notifications: FocusNotificationCoordinator,
        onDone: @escaping () -> Void = {}
    ) {
        self.task = bootstrap?.task ?? task
        self.notifications = notifications
        self.onDone = onDone

        if let bootstrap {
            _experienceID = State(initialValue: bootstrap.experienceID)
            _bankedFocusSeconds = State(initialValue: bootstrap.bankedFocusSeconds)
            _result = State(initialValue: bootstrap.result)
            switch bootstrap.mode {
            case .simple(let timer):
                _mode = State(initialValue: .simple(timer))
            case .pomodoro(let timer):
                _mode = State(initialValue: .pomodoro(timer))
            }
            if bootstrap.result != nil {
                _isEndingSession = State(initialValue: true)
            }
        } else {
            // Write durable recovery state immediately at session construction —
            // do not wait for onAppear / scenePhase / the 1s display clock.
            let id = UUID()
            let timer = FocusSessionTimer(durationMinutes: task.durationMinutes)
            let resolvedTask = task
            _experienceID = State(initialValue: id)
            _mode = State(initialValue: .simple(timer))
            FocusRecoveryPersistence.writeImmediate(
                experienceID: id,
                task: resolvedTask,
                bankedFocusSeconds: 0,
                simple: timer.snapshot,
                pomodoro: nil,
                at: Date()
            )
        }
    }

    var body: some View {
        Group {
            if let result {
                CompletionView(
                    result: result,
                    experienceID: experienceID,
                    onFinished: finishAndRestore
                )
            } else {
                focusContent
            }
        }
        .onAppear {
            FocusSessionPresence.isActive = true
            persistRecoverySnapshot(at: Date())
            syncNotifications(at: Date())
        }
        .onDisappear {
            if !didClearRecovery {
                persistRecoverySnapshot(at: Date())
            }
            FocusSessionPresence.isActive = false
            restoreIdleTimer()
        }
    }

    private var focusContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            taskHeader
                .padding(.top, dynamicTypeSize.isAccessibilitySize ? 28 : 36)

            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 16 : 28)

            timerDisplay
                .frame(maxWidth: .infinity)

            sessionStatus
                .padding(.top, 20)
                .frame(maxWidth: .infinity)

            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 16 : 28)

            activeControls
        }
        .nextScrollableCanvas(top: 16)
        .task { await runDisplayClock() }
        .onChange(of: scenePhase) { _, phase in
            let current = Date()
            if phase != .active {
                persistRecoverySnapshot(at: current)
                applyIdleTimer()
                return
            }
            refresh(at: current, allowHaptic: false)
            persistRecoverySnapshot(at: current)
        }
        .onChange(of: keepScreenAwake) { _, isOn in
            FocusPreference.setKeepScreenAwake(isOn)
            applyIdleTimer()
        }
        .sheet(isPresented: $showingFocusSettings) {
            FocusSettingsView(
                keepScreenAwake: $keepScreenAwake,
                isPomodoroActive: isPomodoroActive,
                onConfigurePomodoro: {
                    showingFocusSettings = false
                    pomodoroDraft = PomodoroPreference.configuration()
                    showingPomodoroConfig = true
                },
                onReturnToSimpleFocus: isPomodoroActive ? {
                    showingFocusSettings = false
                    requestSwitchToSimpleFocus()
                } : nil
            )
        }
        .sheet(isPresented: $showingPomodoroConfig) {
            PomodoroConfigSheet(
                configuration: $pomodoroDraft,
                onBegin: { config in
                    PomodoroPreference.setConfiguration(config)
                    showingPomodoroConfig = false
                    // BEGIN POMODORO is the explicit confirmation; focused time is banked, not discarded.
                    applyBeginPomodoro(config)
                }
            )
        }
        .confirmationDialog(
            "Switch to Simple Focus?",
            isPresented: $confirmingSwitchToSimple,
            titleVisibility: .visible
        ) {
            Button("Switch to Simple Focus") {
                applyBeginSimpleFocus()
            }
            .accessibilityIdentifier("confirmSwitchToSimpleFocus")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Focused time so far will be kept. The timer will restart with this task's usual duration. Break time is not kept as focus.")
        }
    }

    private var isPomodoroActive: Bool {
        if case .pomodoro = mode { return true }
        return false
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

            Text(sessionContextLine)
                .nextFont(12, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("focusSessionContext")
        }
        .accessibilityElement(children: .contain)
    }

    /// Quiet mode + duration context under the goal — never competes with the timer.
    private var sessionContextLine: String {
        switch mode {
        case .simple:
            return "SIMPLE FOCUS · \(task.durationMinutes) MIN"
        case .pomodoro:
            return isPomodoroBreak ? "POMODORO · BREAK" : "POMODORO"
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: 12) {
            Text(remainingDisplay)
                .font(.system(size: timerSize, weight: .regular, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(timerForeground)
                .opacity(mode.phase == .paused ? 0.72 : 1)
                .minimumScaleFactor(0.55)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: mode.phase)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isPomodoroBreak)
                .accessibilityLabel(timerAccessibilityLabel)
                .accessibilityValue(accessibilityRemaining)
                .accessibilityIdentifier("focusTimer")

            if mode.phase == .paused {
                Text("PAUSED")
                    .nextFont(12, weight: .medium, relativeTo: .caption)
                    .tracking(2.2)
                    .foregroundStyle(NextTheme.secondary)
                    .accessibilityIdentifier("focusPausedLabel")
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: mode.phase)
    }

    private var timerForeground: Color {
        if mode.phase == .paused { return NextTheme.secondary }
        if isPomodoroBreak { return NextTheme.secondary }
        return NextTheme.ink
    }

    private var timerAccessibilityLabel: String {
        if isPomodoroBreak { return "Break time remaining" }
        if mode.phase == .paused { return "Time remaining, paused" }
        return "Time remaining"
    }

    private var isPomodoroBreak: Bool {
        if case .pomodoro(let session) = mode { return session.isOnBreak }
        return false
    }

    private var accumulatedFocusSeconds: TimeInterval {
        FocusSessionAccounting.displayedAccumulatedFocus(
            banked: bankedFocusSeconds,
            currentFocused: currentFocusedSeconds(at: now)
        )
    }

    private var showsAccumulatedFocus: Bool {
        FocusSessionAccounting.shouldShowAccumulatedFocus(
            banked: bankedFocusSeconds,
            isPomodoroActive: isPomodoroActive
        )
    }

    @ViewBuilder
    private var sessionStatus: some View {
        switch mode {
        case .simple:
            VStack(spacing: 12) {
                if showsAccumulatedFocus {
                    accumulatedFocusText
                }

                Button {
                    guard !isEndingSession, !isSwitchingMode else { return }
                    pomodoroDraft = PomodoroPreference.configuration()
                    showingPomodoroConfig = true
                } label: {
                    Text("POMODORO")
                        .nextFont(12, weight: .medium, relativeTo: .caption)
                        .tracking(2.0)
                        .foregroundStyle(NextTheme.secondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Enable Pomodoro")
                .accessibilityIdentifier("enablePomodoro")
                .accessibilityHint("Optional. Opens Pomodoro setup for this session.")
            }

        case .pomodoro(let session):
            if session.isOnBreak {
                breakStatus(session)
            } else {
                focusStatus(session)
            }
        }
    }

    private var accumulatedFocusText: some View {
        Text(FocusSessionAccounting.accumulatedFocusLabel(seconds: accumulatedFocusSeconds))
            .nextFont(13, weight: .medium, relativeTo: .caption)
            .tracking(1.6)
            .foregroundStyle(NextTheme.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("accumulatedFocus")
            .accessibilityLabel("Accumulated focus")
            .accessibilityValue(
                GardenMetrics.focusedDurationSpoken(seconds: accumulatedFocusSeconds)
            )
    }

    private func focusStatus(_ session: PomodoroSessionTimer) -> some View {
        VStack(spacing: 8) {
            Text("FOCUS")
                .nextFont(13, weight: .semibold, relativeTo: .caption)
                .tracking(2.4)
                .foregroundStyle(NextTheme.botanical)
                .accessibilityIdentifier("pomodoroPhase")

            Text("ROUND \(session.currentRound) OF \(session.totalRounds)")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.6)
                .foregroundStyle(NextTheme.secondary)
                .accessibilityIdentifier("pomodoroRound")

            if showsAccumulatedFocus {
                accumulatedFocusText
                    .padding(.top, 4)
            }

            Text(pomodoroPlannedLabel(session))
                .nextFont(12, weight: .regular, relativeTo: .caption)
                .tracking(1.4)
                .foregroundStyle(NextTheme.secondary.opacity(0.85))
                .accessibilityIdentifier("pomodoroPlanned")
        }
        .accessibilityElement(children: .contain)
    }

    private func breakStatus(_ session: PomodoroSessionTimer) -> some View {
        VStack(spacing: 10) {
            Text("BREAK")
                .nextFont(13, weight: .semibold, relativeTo: .caption)
                .tracking(2.4)
                .foregroundStyle(NextTheme.secondary)
                .accessibilityIdentifier("pomodoroPhase")

            Text("AFTER ROUND \(session.currentRound) OF \(session.totalRounds)")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.6)
                .foregroundStyle(NextTheme.secondary)
                .accessibilityIdentifier("pomodoroRound")

            Text(session.breakReassurance)
                .nextFont(17)
                .foregroundStyle(NextTheme.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
                .accessibilityIdentifier("pomodoroBreakMessage")

            if let next = session.nextFocusRound {
                Text("NEXT · ROUND \(next) OF \(session.totalRounds)")
                    .nextFont(12, weight: .medium, relativeTo: .caption)
                    .tracking(1.8)
                    .foregroundStyle(NextTheme.secondary)
                    .accessibilityIdentifier("pomodoroNextRound")
            }

            if showsAccumulatedFocus {
                accumulatedFocusText
                    .padding(.top, 2)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func pomodoroPlannedLabel(_ session: PomodoroSessionTimer) -> String {
        let planned = GardenMetrics.durationText(seconds: session.configuration.plannedFocusSeconds)
        return "\(planned) PLANNED FOCUS"
    }

    private var timerSize: CGFloat {
        if dynamicTypeSize.isAccessibilitySize { return 52 }
        return 76
    }

    private var remainingDisplay: String {
        switch mode {
        case .simple(let timer): return timer.remainingDisplay(at: now)
        case .pomodoro(let timer): return timer.remainingDisplay(at: now)
        }
    }

    private var accessibilityRemaining: String {
        let total: Int
        switch mode {
        case .simple(let timer): total = timer.remainingSeconds(at: now)
        case .pomodoro(let timer): total = timer.remainingSeconds(at: now)
        }
        let minutes = total / 60
        let seconds = total % 60
        var spoken = "\(minutes) minutes, \(seconds) seconds"
        if mode.phase == .paused {
            spoken += ". Paused"
        }
        return spoken
    }

    private var pauseResumeTitle: String {
        mode.phase == .paused ? "RESUME" : "PAUSE"
    }

    private var endSessionTitle: String {
        isPomodoroBreak ? "End session" : "Finish early"
    }

    private var activeControls: some View {
        VStack(spacing: 16) {
            NextHairline()

            Button(pauseResumeTitle) {
                togglePause()
            }
            .nextFont(13, weight: .semibold)
            .tracking(2.2)
            .foregroundStyle(NextTheme.botanical)
            .frame(maxWidth: .infinity, minHeight: 48)
            .disabled(isEndingSession || isSwitchingMode || result != nil)
            .accessibilityIdentifier("focusPauseResume")
            .accessibilityHint(mode.phase == .paused ? "Continues the focus session" : "Pauses the focus session")
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: mode.phase)

            NextHairline()
                .padding(.top, 4)

            Button(endSessionTitle) {
                finishEarly()
            }
            .nextFont(16)
            .foregroundStyle(NextTheme.secondary)
            .frame(maxWidth: .infinity, minHeight: 48)
            .disabled(isEndingSession || isSwitchingMode || result != nil)
            .accessibilityIdentifier("focusEndSession")
            .accessibilityHint(
                isPomodoroBreak
                    ? "Ends the Pomodoro session and moves to completion"
                    : "Ends this focus session early and moves to completion"
            )
        }
    }

    private func currentFocusedSeconds(at current: Date) -> TimeInterval {
        switch mode {
        case .simple(let timer):
            guard timer.phase != .ended else { return 0 }
            return timer.activeElapsed(at: current)
        case .pomodoro(let timer):
            guard timer.phase != .ended else { return 0 }
            return timer.focusedElapsed(at: current)
        }
    }

    private func requestSwitchToSimpleFocus() {
        guard !isEndingSession, !isSwitchingMode, result == nil else { return }
        let current = Date()
        if FocusSessionAccounting.requiresModeSwitchConfirmation(
            currentFocused: currentFocusedSeconds(at: current),
            bankedFocus: bankedFocusSeconds
        ) {
            confirmingSwitchToSimple = true
        } else {
            applyBeginSimpleFocus(at: current)
        }
    }

    private func applyBeginPomodoro(_ configuration: PomodoroConfiguration, at current: Date = Date()) {
        guard !isEndingSession, result == nil else { return }
        isSwitchingMode = true
        let wasPaused = mode.phase == .paused
        bankedFocusSeconds = FocusSessionAccounting.bankFocus(
            currentFocused: currentFocusedSeconds(at: current),
            previousBank: bankedFocusSeconds
        )
        notifications.cancel()
        didPlayCompletionHaptic = false
        var session = PomodoroSessionTimer(configuration: configuration, startedAt: current)
        applyPomodoroPreviewIfNeeded(&session, at: current)
        if wasPaused || NextUITestLaunch.pomodoroPreview() == .paused {
            session.pause(at: current)
        }
        mode = .pomodoro(session)
        now = current
        isSwitchingMode = false
        applyIdleTimer()
        syncNotifications(at: current)
        persistRecoverySnapshot(at: current)
    }

    private func applyBeginSimpleFocus(at current: Date = Date()) {
        guard !isEndingSession, result == nil else { return }
        isSwitchingMode = true
        let wasPaused = mode.phase == .paused
        bankedFocusSeconds = FocusSessionAccounting.bankFocus(
            currentFocused: currentFocusedSeconds(at: current),
            previousBank: bankedFocusSeconds
        )
        notifications.cancel()
        didPlayCompletionHaptic = false
        var timer = FocusSessionTimer(durationMinutes: task.durationMinutes, startedAt: current)
        if wasPaused {
            timer.pause(at: current)
        }
        mode = .simple(timer)
        now = current
        isSwitchingMode = false
        applyIdleTimer()
        syncNotifications(at: current)
        persistRecoverySnapshot(at: current)
    }

    private func applyPomodoroPreviewIfNeeded(_ session: inout PomodoroSessionTimer, at current: Date) {
        #if DEBUG
        switch NextUITestLaunch.pomodoroPreview() {
        case .breakTime:
            session.debugEnterBreakAfterRound1(at: current)
        case .focusRound2:
            session.debugEnterFocusRound2(at: current)
        case .paused, .none:
            break
        }
        #else
        _ = (session, current)
        #endif
    }

    private func togglePause() {
        guard !isEndingSession, !isSwitchingMode, result == nil else { return }
        let current = Date()
        switch mode {
        case .simple(var timer):
            if timer.phase == .running {
                timer.pause(at: current)
            } else if timer.phase == .paused {
                timer.resume(at: current)
            }
            mode = .simple(timer)
        case .pomodoro(var timer):
            if timer.phase == .running {
                timer.pause(at: current)
            } else if timer.phase == .paused {
                timer.resume(at: current)
            }
            mode = .pomodoro(timer)
        }
        now = current
        applyIdleTimer()
        syncNotifications(at: current)
        captureResultIfEnded(at: current, allowHaptic: scenePhase == .active)
        persistRecoverySnapshot(at: current)
    }

    private func finishEarly() {
        guard !isEndingSession, !isSwitchingMode, result == nil else { return }
        isEndingSession = true
        let current = Date()
        switch mode {
        case .simple(var timer):
            timer.finish(at: current)
            mode = .simple(timer)
        case .pomodoro(var timer):
            timer.finish(at: current)
            mode = .pomodoro(timer)
        }
        now = current
        applyIdleTimer()
        notifications.cancel()
        captureResultIfEnded(at: current, allowHaptic: false)
        persistRecoverySnapshot(at: current)
    }

    private func refresh(at current: Date, allowHaptic: Bool) {
        now = current
        switch mode {
        case .simple(var timer):
            timer.evaluateCompletion(at: current)
            mode = .simple(timer)
        case .pomodoro(var timer):
            let previousKind = timer.kind
            let previousPhase = timer.phase
            timer.evaluateCompletion(at: current)
            mode = .pomodoro(timer)
            if allowHaptic,
               timer.phase != .ended,
               previousPhase != .ended,
               previousKind != timer.kind {
                playSegmentTransitionHaptic()
            }
        }
        applyIdleTimer()
        syncNotifications(at: current)
        captureResultIfEnded(at: current, allowHaptic: allowHaptic)
        persistRecoverySnapshot(at: current)
    }

    private func captureResultIfEnded(at current: Date, allowHaptic: Bool) {
        guard result == nil else { return }
        let raw: FocusSessionResult?
        switch mode {
        case .simple(let timer):
            raw = timer.makeResult(for: task, at: current)
        case .pomodoro(let timer):
            raw = timer.makeResult(for: task, at: current)
        }
        guard let raw else {
            if !isEndingSession { return }
            // finishEarly already ended the timer; keep ending latch only when result lands.
            return
        }
        result = FocusSessionAccounting.mergeBankedFocus(bankedFocusSeconds, into: raw)
        isEndingSession = true
        applyIdleTimer()
        notifications.cancel()
        if allowHaptic, result?.endedNaturally == true {
            playNaturalCompletionHaptic()
        }
    }

    private func persistRecoverySnapshot(at current: Date) {
        guard !didClearRecovery else { return }

        let simple: FocusSessionTimer.Snapshot?
        let pomodoro: PomodoroSessionTimer.Snapshot?
        switch mode {
        case .simple(let timer):
            simple = timer.snapshot
            pomodoro = nil
        case .pomodoro(let timer):
            simple = nil
            pomodoro = timer.snapshot
        }

        FocusRecoveryPersistence.writeImmediate(
            experienceID: experienceID,
            task: task,
            bankedFocusSeconds: bankedFocusSeconds,
            simple: simple,
            pomodoro: pomodoro,
            result: result,
            at: current
        )
    }

    private func playNaturalCompletionHaptic() {
        guard !didPlayCompletionHaptic else { return }
        didPlayCompletionHaptic = true
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    private func playSegmentTransitionHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    private func syncNotifications(at current: Date) {
        let title = task.title
        let coordinator = notifications
        switch mode {
        case .simple(let timer):
            Task { await coordinator.sync(timer: timer, taskTitle: title, at: current) }
        case .pomodoro(let timer):
            Task { await coordinator.sync(pomodoro: timer, taskTitle: title, at: current) }
        }
    }

    private func applyIdleTimer() {
        FocusIdleTimer.isDisabled = FocusIdleTimerPolicy.isIdleTimerDisabled(
            keepScreenAwake: keepScreenAwake,
            phase: mode.phase,
            sceneActive: result == nil && scenePhase == .active
        )
    }

    private func restoreIdleTimer() {
        FocusIdleTimer.isDisabled = false
        notifications.cancel()
    }

    private func finishAndRestore() {
        // After a successful commit, CompletionView clears the snapshot.
        // If clear succeeded (or this experience is no longer the pending one),
        // skip rewriting recovery state from onDisappear.
        if FocusRecoveryStore.load()?.experienceID != experienceID {
            didClearRecovery = true
        }
        restoreIdleTimer()
        notifications.cancel()
        onDone()
    }

    private func runDisplayClock() async {
        refresh(at: Date(), allowHaptic: scenePhase == .active)
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
    let isPomodoroActive: Bool
    let onConfigurePomodoro: () -> Void
    let onReturnToSimpleFocus: (() -> Void)?

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
                    .tint(NextTheme.interactiveAccent)
                    .accessibilityLabel("Keep Screen Awake")
                    .accessibilityIdentifier("keepScreenAwake")
                    .accessibilityHint("Keep the display on while a focus session is actively running.")
            }
            .padding(.top, 36)

            NextHairline()
                .padding(.vertical, 28)

            VStack(alignment: .leading, spacing: 12) {
                Text("Pomodoro")
                    .nextFont(20, relativeTo: .title3)
                    .foregroundStyle(NextTheme.ink)
                Text(
                    isPomodoroActive
                        ? "Pomodoro is active. Focused time so far is kept if you switch back. Breaks never count as focus."
                        : "Optional. Stay with Simple Focus, or set up timed rounds for this session."
                )
                .nextFont(16)
                .foregroundStyle(NextTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)

                if isPomodoroActive {
                    if let onReturnToSimpleFocus {
                        Button("Switch to Simple Focus") {
                            onReturnToSimpleFocus()
                        }
                        .nextFont(16)
                        .foregroundStyle(NextTheme.botanical)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .accessibilityIdentifier("switchToSimpleFocus")
                    }
                } else {
                    Button("Set up Pomodoro") {
                        onConfigurePomodoro()
                    }
                    .nextFont(16)
                    .foregroundStyle(NextTheme.botanical)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .accessibilityIdentifier("setupPomodoro")
                }
            }

            Spacer(minLength: 24)

            NextPrimaryAction(title: "DONE") {
                dismiss()
            }
        }
        .nextCanvas(top: 16)
        .presentationDetents([.height(460), .medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(NextTheme.canvas)
    }
}

private struct PomodoroConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var configuration: PomodoroConfiguration
    let onBegin: (PomodoroConfiguration) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("POMODORO")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(2.2)
                    .foregroundStyle(NextTheme.secondary)

                Text("Choose a suggested rhythm, or customize.")
                    .nextFont(16)
                    .foregroundStyle(NextTheme.secondary)
                    .padding(.top, 12)
                    .fixedSize(horizontal: false, vertical: true)

                presetRow
                    .padding(.top, 28)

                customControls
                    .padding(.top, 28)

                totals
                    .padding(.top, 24)

                Button("Reset to Recommended") {
                    configuration = .recommended
                }
                .nextFont(16)
                .foregroundStyle(NextTheme.secondary)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.top, 8)
                .accessibilityIdentifier("resetPomodoroRecommended")

                NextPrimaryAction(title: "BEGIN POMODORO") {
                    onBegin(configuration.sanitized())
                }
                .padding(.top, 20)

                Button("Cancel") {
                    dismiss()
                }
                .nextFont(16)
                .foregroundStyle(NextTheme.secondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.top, 8)
            }
            .padding(.horizontal, NextTheme.pagePadding)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(NextTheme.canvas.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(NextTheme.canvas)
        .accessibilityIdentifier("pomodoroConfigSheet")
    }

    private var presetRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUGGESTED")
                .nextFont(12, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondary)

            VStack(spacing: 10) {
                ForEach(PomodoroPreset.allCases) { preset in
                    let selected = PomodoroPreset.matching(configuration) == preset
                    Button {
                        configuration = preset.configuration
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.title)
                                    .nextFont(17)
                                    .foregroundStyle(NextTheme.ink)
                                Text(presetSummary(preset.configuration))
                                    .nextFont(14)
                                    .foregroundStyle(NextTheme.secondary)
                            }
                            Spacer(minLength: 12)
                            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selected ? NextTheme.botanical : NextTheme.secondary)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(preset.title)
                    .accessibilityValue(selected ? "Selected" : "Not selected")
                    .accessibilityIdentifier("pomodoroPreset_\(preset.rawValue)")
                }
            }
        }
    }

    private var customControls: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("CUSTOM")
                .nextFont(12, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondary)

            stepperRow(
                title: "Focus",
                valueLabel: "\(configuration.focusMinutes) min",
                accessibilityID: "pomodoroFocusStepper"
            ) {
                configuration.focusMinutes = PomodoroConfiguration.clampFocus(
                    configuration.focusMinutes - PomodoroConfiguration.focusStepMinutes
                )
            } onIncrement: {
                configuration.focusMinutes = PomodoroConfiguration.clampFocus(
                    configuration.focusMinutes + PomodoroConfiguration.focusStepMinutes
                )
            }

            stepperRow(
                title: "Break",
                valueLabel: "\(configuration.breakMinutes) min",
                accessibilityID: "pomodoroBreakStepper"
            ) {
                configuration.breakMinutes = PomodoroConfiguration.clampBreak(
                    configuration.breakMinutes - 1
                )
            } onIncrement: {
                configuration.breakMinutes = PomodoroConfiguration.clampBreak(
                    configuration.breakMinutes + 1
                )
            }

            stepperRow(
                title: "Rounds",
                valueLabel: "\(configuration.rounds)",
                accessibilityID: "pomodoroRoundsStepper"
            ) {
                configuration.rounds = PomodoroConfiguration.clampRounds(configuration.rounds - 1)
            } onIncrement: {
                configuration.rounds = PomodoroConfiguration.clampRounds(configuration.rounds + 1)
            }
        }
    }

    private var totals: some View {
        let planned = GardenMetrics.durationText(seconds: configuration.sanitized().plannedFocusSeconds)
        return Text("\(planned) PLANNED FOCUS")
            .nextFont(13, weight: .medium, relativeTo: .caption)
            .tracking(1.4)
            .foregroundStyle(NextTheme.secondary)
            .accessibilityIdentifier("pomodoroPlannedFocus")
    }

    private func presetSummary(_ configuration: PomodoroConfiguration) -> String {
        "\(configuration.focusMinutes) min focus · \(configuration.breakMinutes) min break · \(configuration.rounds) rounds"
    }

    private func stepperRow(
        title: String,
        valueLabel: String,
        accessibilityID: String,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
                .nextFont(17)
                .foregroundStyle(NextTheme.ink)
            Spacer()
            Text(valueLabel)
                .nextFont(16)
                .foregroundStyle(NextTheme.secondary)
                .monospacedDigit()
                .accessibilityIdentifier("\(accessibilityID)_value")
            Button(action: onDecrement) {
                Image(systemName: "minus.circle")
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(NextTheme.botanical)
            .accessibilityLabel("Decrease \(title)")
            .accessibilityIdentifier("\(accessibilityID)_decrement")

            Button(action: onIncrement) {
                Image(systemName: "plus.circle")
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(NextTheme.botanical)
            .accessibilityLabel("Increase \(title)")
            .accessibilityIdentifier("\(accessibilityID)_increment")
        }
        .accessibilityElement(children: .contain)
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
