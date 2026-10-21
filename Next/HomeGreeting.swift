//
//  HomeGreeting.swift
//  Next
//
//  Local-time daypart greeting. Pure and testable — no timers.
//

import Foundation

enum HomeDayPart: Equatable {
    case morning
    case afternoon
    case evening

    /// Morning 05:00–11:59 · Afternoon 12:00–16:59 · Evening 17:00–04:59
    static func resolve(now: Date, calendar: Calendar = .current) -> HomeDayPart {
        let hour = calendar.component(.hour, from: now)
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        default: return .evening
        }
    }

    var greeting: String {
        switch self {
        case .morning: "Good morning."
        case .afternoon: "Good afternoon."
        case .evening: "Good evening."
        }
    }
}

enum HomeGreeting {
    static func text(now: Date = Date(), calendar: Calendar = .current) -> String {
        HomeDayPart.resolve(now: now, calendar: calendar).greeting
    }
}
