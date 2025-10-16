//
//  TodayWidgetManager.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 10/11/25.
//


import Foundation
import SwiftUI

@Observable
class TodayWidgetManager: @MainActor ListWidgetDataSource {
    var fetchStatus: WidgetFetchStatus = .loading

    struct CourseEvent: Identifiable {
        let event: CanvasCalendarEvent
        let course: Course?

        var id: String { event.id }
    }

    // ID prefixes for different data types
    private static let eventPrefix = "event-"
    private static let announcementPrefix = "announcement-"
    private static let assignmentPrefix = "assignment-"

    var todayEvents: [CourseEvent] = []
    var todayAnnouncements: [AllAnnouncementsManager.CourseAnnouncement] = []
    var todayAssignments: [ToDoItem] = []
    private var courses: [Course] = []

    private let announcementsManager = AllAnnouncementsManager()
    private let toDoManager = ToDoListManager()


    var widgetData: [ListWidgetData] {
        get {
            var data: [ListWidgetData] = []

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            let todayString = dateFormatter.string(from: Date())

    
            data.append(ListWidgetData(
                id: "today-date",
                title: todayString,
                description: " "
            ))


            for courseEvent in todayEvents {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                let timeString = timeFormatter.string(from: courseEvent.event.startDate)
                let courseName = courseEvent.course?.displayName ?? "Unknown Course"

                data.append(ListWidgetData(
                    id: "\(Self.eventPrefix)\(courseEvent.event.id)",
                    title: courseEvent.event.summary,
                    description: "📅 \(timeString) • \(courseName)"
                ))
            }

            for announcement in todayAnnouncements {
                let courseName = announcement.course?.displayName ?? "Unknown Course"
                data.append(ListWidgetData(
                    id: "\(Self.announcementPrefix)\(announcement.id)",
                    title: announcement.announcement.title ?? "Announcement",
                    description: "📢 \(courseName)"
                ))
            }


            for assignment in todayAssignments {
                // Dynamically look up course using courseID to handle race conditions
                let course = courses.first { $0.id == assignment.courseID.asString }
                let courseName = course?.displayName ?? "Unknown Course"
                data.append(ListWidgetData(
                    id: "\(Self.assignmentPrefix)\(assignment.id)",
                    title: assignment.title,
                    description: "✅ Due today • \(courseName)"
                ))
            }

            
            if todayEvents.isEmpty && todayAnnouncements.isEmpty && todayAssignments.isEmpty {
                data.append(ListWidgetData(
                    id: "no-events",
                    title: "No events today",
                    description: "You're all clear for the day!"
                ))
            }

            return data
        }
        set { }
    }

    @MainActor
    func fetchData(context: WidgetContext) async throws {
        guard let courseManager = context.courseManager else {
            fetchStatus = .error
            return
        }

        fetchStatus = .loading

        let courses = courseManager.activeCourses
        self.courses = courses

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.fetchTodayCalendarEvents(
                    courses: courses,
                    today: today,
                    tomorrow: tomorrow
                )
            }


            group.addTask { [weak self] in
                await self?.fetchTodayAnnouncements(
                    courses: courses,
                    today: today,
                    tomorrow: tomorrow
                )
            }


            group.addTask { [weak self] in
                await self?.fetchTodayAssignments(
                    courses: courses,
                    today: today,
                    tomorrow: tomorrow
                )
            }
        }
        fetchStatus = .loaded
    }

    private func fetchTodayCalendarEvents(courses: [Course], today: Date, tomorrow: Date) async {
        var allEvents: [CourseEvent] = []

        for course in courses {
            guard let icsURL = course.calendarIcs,
                  let url = URL(string: icsURL) else {
                continue
            }

            let eventGroups = await ICSParser.parseEvents(from: url)


            for group in eventGroups {
                if group.date >= today && group.date < tomorrow {
                    let courseEvents = group.events.map { event in
                        CourseEvent(event: event, course: course)
                    }
                    allEvents.append(contentsOf: courseEvents)
                }
            }
        }

        self.todayEvents = allEvents.sorted { $0.event.startDate < $1.event.startDate }
    }

    private func fetchTodayAnnouncements(courses: [Course], today: Date, tomorrow: Date) async {
        guard !courses.isEmpty else { return }

        await announcementsManager.fetchAnnouncements(courses: courses)

        self.todayAnnouncements = announcementsManager.displayedAnnouncements.filter { announcement in
            guard let date = announcement.announcement.date else { return false }
            return date >= today && date < tomorrow
        }
    }

    private func fetchTodayAssignments(courses: [Course], today: Date, tomorrow: Date) async {
        guard !courses.isEmpty else { return }

        await toDoManager.fetchToDoItems(courses: courses)

        self.todayAssignments = toDoManager.displayedToDoItems.filter { item in
            guard let dueDate = item.dueDate else { return false }
            return dueDate >= today && dueDate < tomorrow
        }
    }


    func destinationView(for data: ListWidgetData) -> NavigationModel.Destination {
        let id = data.id

        if id.hasPrefix(Self.eventPrefix) {
            let eventID = String(id.dropFirst(Self.eventPrefix.count))
            if let courseEvent = todayEvents.first(where: { $0.event.id == eventID }),
               let course = courseEvent.course {
                return .calendarEvent(courseEvent.event, course)
            }
            return .today
        }

        if id.hasPrefix(Self.announcementPrefix) {
            let announcementID = String(id.dropFirst(Self.announcementPrefix.count))
            if let announcement = todayAnnouncements.first(where: { $0.id == announcementID }) {
                return .announcement(announcement.announcement)
            }
        }

        if id.hasPrefix(Self.assignmentPrefix) {
            let assignmentID = String(id.dropFirst(Self.assignmentPrefix.count))
            if let assignment = todayAssignments.first(where: { $0.id == assignmentID }) {
                return assignment.navigationDestination() ?? .today
            }
        }

        return .today
    }
}

