//
//  GTSchedulerParser.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/21/25.
//

import Foundation
import Playgrounds


class GTSchedulerParser {
    static let shared = GTSchedulerParser()
    private init() {

    }

    enum ParserError: Error {
        case malformedSectionName
        case missingCatalog
    }
    
    var catalog: GTSCatalog?

    func fetchCatalog() async throws {
        let request = URLRequest(url: URL(string: "https://gt-scheduler.github.io/crawler-v2/202508.json")!)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("HTTP error fetching GT Scheduler Catalog: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw URLError(.badServerResponse)
        }

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.catalog = try dec.decode(GTSCatalog.self, from: data)
    }

    // MARK: Helper Functions

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

    private func dateComponentsFromTimeSpan(_ timeSpan: String) -> (start: DateComponents, end: DateComponents)? {
        let parts = timeSpan.components(separatedBy: " - ")
        guard parts.count == 2 else { return nil }

        guard let (startHour, startMinute) = componentsFromHHmm(parts[0].trimmingCharacters(in: .whitespaces)),
              let (endHour, endMinute) = componentsFromHHmm(parts[1].trimmingCharacters(in: .whitespaces)) else { return nil }

        var startComponents = DateComponents()
        startComponents.hour = startHour
        startComponents.minute = startMinute
        startComponents.second = 0

        var endComponents = DateComponents()
        endComponents.hour = endHour
        endComponents.minute = endMinute
        endComponents.second = 0

        return (start: startComponents, end: endComponents)
    }

    private func componentsFromHHmm(_ str: String) -> (hour: Int, minute: Int)? {
        guard str.count == 4,
              let hour = Int(str.prefix(2)),
              let minute = Int(str.suffix(2)) else { return nil }
        return (hour, minute)
    }

    func getCanvasCourseScheduleMeetings(course: Course) async throws -> CanvasCourseSchedule {

        if catalog == nil { // should only be fetched once
            try await fetchCatalog()
        }


        guard let catalog else {
            throw ParserError.missingCatalog
        }
        var courseMeetings: [CanvasCourseScheduleMeeting] = []
        
        for section in course.sections {
            let crnPattern = /\d{5}/

            let components = section.name?.split(separator: "/") ?? []
            if components.count < 4 {
                throw ParserError.malformedSectionName
            }

            guard var courseCode = course.courseCode else {
                throw ParserError.malformedSectionName
            }

            if let courseCodeMatch = courseCode.firstMatch(of: /[A-Z]{2,4}-\d{4}/) {
                courseCode = String(courseCodeMatch.0)
            } else {
            }

            courseCode = courseCode.replacingOccurrences(of: "-", with: " ")

            guard let sectionCode = course.courseCode?.split(separator: "-").last else {
                throw ParserError.malformedSectionName
            }

            guard let crn = components.last, !crn.matches(of: crnPattern).isEmpty else {
                throw ParserError.malformedSectionName
            }

            guard let meetings = catalog.courses[courseCode]?.sections[String(sectionCode)]?.meetings else { continue }

            for meeting in meetings {
                let dayList = weekdays(from: meeting.days)

                let timeSpan = catalog.caches.periods[meeting.idx]
                for day in dayList {

                    guard let (startTime, endTime) = dateComponentsFromTimeSpan(timeSpan) else {
                        print("Error getting date from timespan")
                        continue
                    }

                    let meet = CanvasCourseScheduleMeeting(weekday: day, startTime: startTime, endTime: endTime, location: meeting.location)
                    courseMeetings.append(meet)
                }

            }


        }

        return CanvasCourseSchedule(course: course, meetings: courseMeetings)
    }

    private func nextDate(for weekday: Locale.Weekday, includingToday: Bool = true, calendar: Calendar = .current) -> Date? {
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        let targetWeekdayNumber = weekday.number(calendar: calendar)

        if includingToday && todayWeekday == targetWeekdayNumber {
            return today
        }

        return calendar.nextDate(after: today, matching: DateComponents(weekday: targetWeekdayNumber), matchingPolicy: .nextTime)
    }



    // MARK: Helper structs for decoding GT Scheduler JSON payload

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
}

// A single public struct that represents a canvas course and its meeting times
struct CanvasCourseSchedule {
    let course: Course

    // The generic meeting times for a course in a given week
    let meetings: [CanvasCourseScheduleMeeting]
}

struct CanvasCourseScheduleMeeting {
    let weekday: Locale.Weekday
    let startTime: DateComponents
    let endTime: DateComponents
    let location: String

}

