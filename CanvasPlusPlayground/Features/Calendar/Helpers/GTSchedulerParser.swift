//
//  GTSchedulerParser.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/21/25.
//

import Foundation

class GTSchedulerParser {
    static let shared = GTSchedulerParser()
    private init() { }

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

    /// Converts a string of weekday codes to an array of Locale.Weekday values.
    ///
    /// Example:
    ///   Input: "MWF" => Output: [.monday, .wednesday, .friday]
    ///   Input: "TR"  => Output: [.tuesday, .thursday]
    ///   Input: "U"   => Output: [.sunday]
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

    /// Parses a time span string (e.g., "1100 - 1215") into start/end DateComponents.
    ///
    /// Example:
    ///   Input: "1100 - 1215" => Output: (start: hour=11, minute=0, end: hour=12, minute=15)
    ///   Input: "0830 - 0945" => Output: (start: hour=8, minute=30, end: hour=9, minute=45)
    ///   Returns nil if format is invalid.
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

    /// Parses a 4-digit string in HHmm format into hour and minute components.
    ///
    /// Example:
    ///   Input: "1100" => Output: (11, 0)
    ///   Input: "0945" => Output: (9, 45)
    ///   Returns nil if input is not 4 digits.
    private func componentsFromHHmm(_ str: String) -> (hour: Int, minute: Int)? {
        guard str.count == 4,
              let hour = Int(str.prefix(2)),
              let minute = Int(str.suffix(2)) else { return nil }
        return (hour, minute)
    }

    /// Parses the given Course object and returns a CanvasCourseSchedule containing meeting times with weekdays, start/end times, and locations.
    ///
    /// Example:
    ///   - Suppose you have a Course representing CS 1331 Section A with section name "CS-1331/A/REG/12345"
    ///   - The catalog will have an entry courses["CS 1331"] -> sections["A"] -> meetings array
    ///   - Each meeting indicates days (e.g., "MWF"), period index (idx), and location
    ///   - This function matches those up to return CanvasCourseScheduleMeeting entries for each weekday/period/location combination
    func getCanvasCourseScheduleMeetings(course: Course) async throws -> CanvasCourseSchedule {

        // 1. If catalog has not been fetched yet, fetch it
        if catalog == nil { // should only be fetched once
            try await fetchCatalog()
        }

        // 2. Ensure we have a catalog after fetching
        guard let catalog else {
            throw ParserError.missingCatalog
        }

        var courseMeetings: [CanvasCourseScheduleMeeting] = []

        // 3. Iterate over each section in the course (most of the times, will just be a single section)
        for section in course.sections {
            let crnPattern = /\d{5}/

            // 4. Parse the section name, expected format: "CS-1331/A/REG/12345"
            let components = section.name?.split(separator: "/") ?? []
            if components.count < 4 {
                throw ParserError.malformedSectionName
            }

            // 5. Extract the course code string, e.g. "CS-1331"
            guard var courseCode = course.courseCode else {
                throw ParserError.malformedSectionName
            }

            // 6. Normalize course code to format like "CS 1331"
            if let courseCodeMatch = courseCode.firstMatch(of: /[A-Z]{2,4}-\d{4}/) {
                courseCode = String(courseCodeMatch.0)
            } else {
                // If no match, keep as is (no-op)
            }
            courseCode = courseCode.replacingOccurrences(of: "-", with: " ")

            // 7. Extract the section code from course code, e.g. "A" from "CS-1331-A" or similar
            guard let sectionCode = course.courseCode?.split(separator: "-").last else {
                throw ParserError.malformedSectionName
            }

            // 8. Validate that the last component is a CRN number matching 5 digits
            guard let crn = components.last, !crn.matches(of: crnPattern).isEmpty else {
                throw ParserError.malformedSectionName
            }

            // 9. Lookup meetings for this course code and section code in the catalog dictionary
            guard let meetings = catalog.courses[courseCode]?.sections[String(sectionCode)]?.meetings else { continue }

            // 10. For each meeting entry, expand to individual weekday/time/location objects
            for meeting in meetings {
                // Get the list of weekdays from the meeting.days string (e.g., "MWF" -> [.monday, .wednesday, .friday])
                let dayList = weekdays(from: meeting.days)

                // Get the time span string (e.g. "1100 - 1215") from the catalog's periods array using the meeting's idx
                let timeSpan = catalog.caches.periods[meeting.idx]

                // For each weekday, create a CanvasCourseScheduleMeeting object with the appropriate times and location
                for day in dayList {

                    // Convert the time span string to start and end DateComponents
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

// A single public struct that represents a canvas course and its meeting times (instead of a collection of many different objects with data everywhere
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

