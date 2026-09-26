//
//  GardenGrowth.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation

enum GardenGrowthStage: Int, CaseIterable, Equatable {
    case seedling = 0
    case sprout = 1
    case young = 2
    case growing = 3
    case mature = 4
}

enum GardenGrowth {
    static func stage(for focusedDuration: TimeInterval) -> GardenGrowthStage {
        let minutes = focusedDuration / 60
        switch minutes {
        case ..<30: return .seedling
        case ..<120: return .sprout
        case ..<300: return .young
        case ..<600: return .growing
        default: return .mature
        }
    }
}

enum GardenMetrics {
    static func sessionCountLabel(_ count: Int) -> String {
        count == 1 ? "1 SESSION" : "\(count) SESSIONS"
    }

    static func durationText(seconds: TimeInterval) -> String {
        if seconds <= 0 {
            return "0 MIN"
        }
        if seconds < 60 {
            return "<1 MIN"
        }

        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return minutes == 1 ? "1 MIN" : "\(minutes) MIN"
        }

        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 {
            return "\(hours)H"
        }
        return "\(hours)H \(remainder)M"
    }

    static func focusedDurationLabel(seconds: TimeInterval) -> String {
        "\(durationText(seconds: seconds)) FOCUSED"
    }

    static func sessionCountSpoken(_ count: Int) -> String {
        count == 1 ? "1 session" : "\(count) sessions"
    }

    static func focusedDurationSpoken(seconds: TimeInterval) -> String {
        if seconds <= 0 {
            return "0 minutes focused"
        }
        if seconds < 60 {
            return "less than 1 minute focused"
        }

        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return minutes == 1 ? "1 minute focused" : "\(minutes) minutes focused"
        }

        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 {
            return hours == 1 ? "1 hour focused" : "\(hours) hours focused"
        }
        let hourWord = hours == 1 ? "1 hour" : "\(hours) hours"
        let minuteWord = remainder == 1 ? "1 minute" : "\(remainder) minutes"
        return "\(hourWord) \(minuteWord) focused"
    }
}
