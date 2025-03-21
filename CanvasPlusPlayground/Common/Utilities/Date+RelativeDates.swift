//
//  Date+RelativeDates.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/4/25.
//
import Foundation

extension Date {
    func dayOfWeekString() -> String {
        let date = self
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    static var tomorrowAt8am: Date {
        let calendar = Calendar.current
        let now = Date.now

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)  else {
            return Date.now
        }

        let tomorrowAt8AM = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: tomorrow)
        return tomorrowAt8AM ?? Date.now
    }

    static func nextOrdinalAt8am(weekday: Int) -> Date {
        if weekday < 1 || weekday > 7 {
            return .now
        }
        let calendar = Calendar.current
        let now = Date.now

        // Find the next ordinal day
        guard let nextDay = calendar.nextDate(after: now, matching: DateComponents(weekday: weekday), matchingPolicy: .nextTime) else {
            return Date.now
        }
        // Set the time to 8 AM
        return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: nextDay) ?? Date.now
    }
}

extension Date {
    static func timeDeltaString(from startDate: Date, to endDate: Date) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full // Use .short or .abbreviated for different styles
        formatter.allowedUnits = [.day, .hour]
        return formatter.string(from: startDate, to: endDate) ?? "N/A"
    }
}
