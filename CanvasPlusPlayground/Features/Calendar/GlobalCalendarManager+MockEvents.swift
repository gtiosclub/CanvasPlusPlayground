//
//  GlobalCalendarManager+MockEvents.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 11/22/26.
//

#if DEBUG
import Foundation

extension GlobalCalendarManager {
    /// Fake events around `date` for eyeballing each view mode: overlaps, a crowded day,
    /// zero-length "due" items, long titles, and days in the neighbouring months.
    static func mockEvents(courses: [Course], around date: Date, calendar: Calendar) -> [CanvasCalendarEvent] {
        guard !courses.isEmpty else { return [] }

        // (day offset from `date`, start hour, start minute, duration in minutes, title, location)
        let specs: [(Int, Int, Int, Int, String, String)] = [
            (0, 10, 0, 90, "Lecture: Graph Algorithms", "Klaus 1443"),
            (0, 11, 0, 60, "Office Hours", "CoC 052"),
            (0, 11, 30, 45, "Study Group", "Library 3rd Floor"),
            (0, 23, 59, 0, "Homework 5 due", ""),
            (1, 9, 0, 50, "Recitation with an unusually long title that should truncate", "Skiles 249"),
            (2, 8, 0, 30, "Quiz 4", "Online"),
            (2, 10, 0, 60, "Lab Section", "Howey L1"),
            (2, 13, 0, 60, "Project Check-in", "Zoom"),
            (2, 15, 0, 90, "Midterm Review", "Clough 144"),
            (2, 18, 0, 30, "TA Meeting", "CoC 052"),
            (2, 23, 59, 0, "Lab Report due", ""),
            (-3, 14, 0, 75, "Guest Lecture", "Ferst Center"),
            (4, 7, 30, 105, "Early Exam", "Instructional Center"),
            (9, 12, 0, 60, "Career Fair", "Student Center"),
            (9, 17, 0, 0, "Essay draft due", ""),
            (-20, 10, 0, 60, "Previous Month Event", "Klaus 1443"),
            (25, 10, 0, 60, "Next Month Event", "Klaus 1443"),
        ]

        let today = calendar.startOfDay(for: date)
        return specs.enumerated().compactMap { index, spec in
            let (dayOffset, hour, minute, duration, title, location) = spec
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today),
                  let start = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else { return nil }

            return CanvasCalendarEvent(
                id: "mock-\(index)",
                course: courses[index % courses.count],
                summary: title,
                startDate: start,
                endDate: start.addingTimeInterval(TimeInterval(duration * 60)),
                location: location
            )
        }
    }
}
#endif
