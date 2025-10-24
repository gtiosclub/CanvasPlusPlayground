//
//  CalendarThing.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/21/25.
//

import Foundation
import Playgrounds




struct GTSCatalog: Decodable {
    let courses: [String: GTSCourse]
    let caches: GTSCache
}

struct GTSCache: Decodable {
  let periods: [String] // just an array of strings representing possible times (1100 -- 1215, 1330 -- 1500...)
}

struct GTSCourse: Decodable {
    let title: String
    let sections: [String: GTSSection] // map of section name to section type

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.title = try container.decode(String.self)
        self.sections = try container.decode([String: GTSSection].self)
    }
}

// MARK: - Sections

struct GTSSection: Decodable {
    let crn: String
    let meetings: [GTSMeeting]
    init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        self.crn = try c.decode(String.self)
        self.meetings = try c.decode([GTSMeeting].self)
    }
}

struct GTSMeeting: Decodable {
    let idx: Int
    let days: String
    let location: String
    let mode: Int
    let instructors: [String]

    init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        self.idx = try c.decode(Int.self)
        self.days = try c.decode(String.self)
        self.location = try c.decode(String.self)
        self.mode = try c.decode(Int.self)
        self.instructors = try c.decode([String].self)
    }
}

func weekdays(from dayString: String) -> [Locale.Weekday] {
    let map: [Character: Locale.Weekday] = [
        "M": .monday,
        "T": .tuesday,
        "W": .wednesday,
        "R": .thursday,
        "F": .friday,
        "S": .saturday,
        "U": .sunday // Sometimes "U" is used for Sunday
    ]
    return dayString.compactMap { map[$0] }
}

func datesFromTimeSpanAndDay(_ timeSpan: String, day: Date) -> (start: Date, end: Date)? {
    let parts = timeSpan.components(separatedBy: " - ")
    guard parts.count == 2 else { return nil }

    func componentsFromHHmm(_ str: String) -> (hour: Int, minute: Int)? {
        guard str.count == 4,
              let hour = Int(str.prefix(2)),
              let minute = Int(str.suffix(2)) else { return nil }
        return (hour, minute)
    }

    guard let (startHour, startMinute) = componentsFromHHmm(parts[0].trimmingCharacters(in: .whitespaces)),
          let (endHour, endMinute) = componentsFromHHmm(parts[1].trimmingCharacters(in: .whitespaces)) else { return nil }

    let calendar = Calendar.current
    var startComponents = calendar.dateComponents([.year, .month, .day], from: day)
    startComponents.hour = startHour
    startComponents.minute = startMinute
    startComponents.second = 0

    var endComponents = calendar.dateComponents([.year, .month, .day], from: day)
    endComponents.hour = endHour
    endComponents.minute = endMinute
    endComponents.second = 0

    guard let startDate = calendar.date(from: startComponents),
          let endDate = calendar.date(from: endComponents) else {
        return nil
    }

    return (start: startDate, end: endDate)
}
