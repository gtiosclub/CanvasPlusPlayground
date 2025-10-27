//
//  Date+ConvenienceMethods.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/26/25.
//

import Foundation

extension Date {
    /// Returns the day abbreviation and day number as a string (e.g., "Mon 20").
    var dayNumberString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "E d" // e.g., "Mon 20"
        return formatter.string(from: self)
    }
}

extension Locale.Weekday {
    func number(calendar: Calendar) -> Int {
        // Map Locale.Weekday to Calendar weekday number (1 for Sunday...7 for Saturday)
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        default: return 1 // Fallback to Sunday
        }
    }
}
