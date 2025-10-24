//
//  CombinedCalendarManager.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/25/25.
//

import Foundation


@Observable
class CombinedCalendarManager {
    var calendarEvents: [CanvasCalendarEventGroup] = []


    private func decodeCatalog(from data: Data) throws -> GTSCatalog {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try dec.decode(GTSCatalog.self, from: data)
    }

    private func fetchCatalog() async throws -> GTSCatalog {
        let request = URLRequest(url: URL(string: "https://gt-scheduler.github.io/crawler-v2/202508.json")!)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("HTTP error fetching GT Scheduler Catalog: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw URLError(.badServerResponse)
        }

        return try decodeCatalog(from: data)
    }


    func getCalendarEventsForCourses(courses: [Course]) async {
        guard let catalog = try? await fetchCatalog() else {
            print("Failed to fetch catalog")
            return
        }
        calendarEvents = []
        for course in courses {
            let newEvents = getCalendarEventsForCourse(course: course, catalog: catalog)
            calendarEvents.append(contentsOf: newEvents)
        }

    }

    private func getCalendarEventsForCourse(course: Course, catalog: GTSCatalog) -> [CanvasCalendarEventGroup] {

        var allCalendarEvents: [CanvasCalendarEventGroup] = []

        for section in course.sections {
            let crnPattern = /\d{5}/

            let components = section.name?.split(separator: "/") ?? []
            if components.count < 4 {
                return []
            }

            guard var courseCode = course.courseCode else {
                return []
            }

            if let courseCodeMatch = courseCode.firstMatch(of: /[A-Z]{2,4}-\d{4}/) {
                courseCode = String(courseCodeMatch.0)
            } else {
            }

            courseCode = courseCode.replacingOccurrences(of: "-", with: " ")

            guard let sectionCode = course.courseCode?.split(separator: "-").last else {
                return []
            }

            guard let crn = components.last, !crn.matches(of: crnPattern).isEmpty else {
                print("ETHAN: invalid section \(section.name ?? "N/A")")
                return []
            }

            guard let meetings = catalog.courses[courseCode]?.sections[String(sectionCode)]?.meetings else { continue }

            for meeting in meetings {
                let dayList = weekdays(from: meeting.days)

                let timeSpan = catalog.caches.periods[meeting.idx]
                for day in dayList {

                    guard let date = nextDate(for: day) else { continue }


                    guard let (startTime, endTime) = datesFromTimeSpanAndDay(timeSpan, day: date) else {
                        print("Error getting date from timespan")
                        continue
                    }

                    let event = CanvasCalendarEvent(id: UUID().uuidString, course: course, summary: course.displayName, startDate: startTime, endDate: endTime, location: meeting.location)

                    allCalendarEvents.append(CanvasCalendarEventGroup(date: startTime, events: [event]))
                }

            }
        }


        return allCalendarEvents
    }

    func nextDate(for weekday: Locale.Weekday, includingToday: Bool = true, calendar: Calendar = .current) -> Date? {
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        let targetWeekdayNumber = weekday.number(calendar: calendar)

        if includingToday && todayWeekday == targetWeekdayNumber {
            return today
        }

        return calendar.nextDate(after: today, matching: DateComponents(weekday: targetWeekdayNumber), matchingPolicy: .nextTime)
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
