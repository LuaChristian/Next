//
//  PomodoroConfiguration.swift
//  Next
//
//  Optional Pomodoro presets and custom ranges. Lightweight local prefs only.
//

import Foundation

struct PomodoroConfiguration: Equatable, Codable, Hashable {
    var focusMinutes: Int
    var breakMinutes: Int
    var rounds: Int

    static let recommended = PomodoroConfiguration(focusMinutes: 25, breakMinutes: 5, rounds: 4)
    static let gentleStart = PomodoroConfiguration(focusMinutes: 15, breakMinutes: 5, rounds: 2)
    static let deepWork = PomodoroConfiguration(focusMinutes: 50, breakMinutes: 10, rounds: 3)

    static let focusStepMinutes = 5
    static let focusMinutesRange = 5...90
    static let breakMinutesRange = 1...30
    static let roundsRange = 1...8

    /// Sum of focus segments only.
    var plannedFocusSeconds: TimeInterval {
        TimeInterval(focusMinutes * 60 * rounds)
    }

    /// Breaks between rounds only (no trailing break after the last focus).
    var plannedBreakSeconds: TimeInterval {
        guard rounds > 1 else { return 0 }
        return TimeInterval(breakMinutes * 60 * (rounds - 1))
    }

    func sanitized() -> PomodoroConfiguration {
        PomodoroConfiguration(
            focusMinutes: Self.clampFocus(focusMinutes),
            breakMinutes: Self.clampBreak(breakMinutes),
            rounds: Self.clampRounds(rounds)
        )
    }

    static func clampFocus(_ minutes: Int) -> Int {
        let stepped = Int((Double(minutes) / Double(focusStepMinutes)).rounded()) * focusStepMinutes
        return min(max(stepped, focusMinutesRange.lowerBound), focusMinutesRange.upperBound)
    }

    static func clampBreak(_ minutes: Int) -> Int {
        min(max(minutes, breakMinutesRange.lowerBound), breakMinutesRange.upperBound)
    }

    static func clampRounds(_ value: Int) -> Int {
        min(max(value, roundsRange.lowerBound), roundsRange.upperBound)
    }
}

enum PomodoroPreset: String, CaseIterable, Identifiable {
    case recommended
    case gentleStart
    case deepWork

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recommended: return "Recommended"
        case .gentleStart: return "Gentle Start"
        case .deepWork: return "Deep Work"
        }
    }

    var configuration: PomodoroConfiguration {
        switch self {
        case .recommended: return .recommended
        case .gentleStart: return .gentleStart
        case .deepWork: return .deepWork
        }
    }

    static func matching(_ configuration: PomodoroConfiguration) -> PomodoroPreset? {
        let clean = configuration.sanitized()
        return allCases.first { $0.configuration == clean }
    }
}

enum PomodoroPreference {
    static let focusMinutesKey = "pomodoro.focusMinutes"
    static let breakMinutesKey = "pomodoro.breakMinutes"
    static let roundsKey = "pomodoro.rounds"

    static func store(arguments: [String] = ProcessInfo.processInfo.arguments) -> UserDefaults {
        FocusPreference.store(arguments: arguments)
    }

    /// Last customized Pomodoro settings. Never implies Pomodoro is enabled on entry.
    static func configuration(
        in defaults: UserDefaults? = nil,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> PomodoroConfiguration {
        let defaults = defaults ?? store(arguments: arguments)
        guard defaults.object(forKey: focusMinutesKey) != nil,
              defaults.object(forKey: breakMinutesKey) != nil,
              defaults.object(forKey: roundsKey) != nil
        else {
            return .recommended
        }

        return PomodoroConfiguration(
            focusMinutes: defaults.integer(forKey: focusMinutesKey),
            breakMinutes: defaults.integer(forKey: breakMinutesKey),
            rounds: defaults.integer(forKey: roundsKey)
        ).sanitized()
    }

    static func setConfiguration(
        _ configuration: PomodoroConfiguration,
        in defaults: UserDefaults? = nil,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        let clean = configuration.sanitized()
        let defaults = defaults ?? store(arguments: arguments)
        defaults.set(clean.focusMinutes, forKey: focusMinutesKey)
        defaults.set(clean.breakMinutes, forKey: breakMinutesKey)
        defaults.set(clean.rounds, forKey: roundsKey)
    }
}
