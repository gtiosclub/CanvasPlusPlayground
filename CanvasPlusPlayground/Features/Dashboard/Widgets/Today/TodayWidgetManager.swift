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

    var todayEvents: [CourseEvent] = []
    var todayAnnouncements: [AllAnnouncementsManager.CourseAnnouncement] = []
    var todayAssignments: [ToDoItem] = []


    var widgetData: [ListWidgetData] {
        get {
            var data: [ListWidgetData] = []

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            let todayString = dateFormatter.string(from: Date())

            //Today's date
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
                    id: "event-\(courseEvent.event.id)",
                    title: courseEvent.event.summary,
                    description: "📅 \(timeString) • \(courseName)"
                ))
            }

            for announcement in todayAnnouncements {
                let courseName = announcement.course?.displayName ?? "Unknown Course"
                data.append(ListWidgetData(
                    id: "announcement-\(announcement.id)",
                    title: announcement.announcement.title ?? "Announcement",
                    description: "📢 \(courseName)"
                ))
            }


            for assignment in todayAssignments {
                let courseName = assignment.course?.displayName ?? "Unknown Course"
                data.append(ListWidgetData(
                    id: "assignment-\(assignment.id)",
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

        guard !courses.isEmpty else {
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        fetchStatus = .loaded

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
    }

    private func fetchTodayCalendarEvents(courses: [Course], today: Date, tomorrow: Date) async {
        var allEvents: [CourseEvent] = []

        for course in courses {
            guard let icsURL = course.calendarIcs,
                  let url = URL(string: icsURL) else {
                continue
            }

            let eventGroups = await ICSParser.parseEvents(from: url)

            // Filter events for today
            for group in eventGroups {
                if group.date >= today && group.date < tomorrow {
                    let courseEvents = group.events.map { event in
                        CourseEvent(event: event, course: course)
                    }
                    allEvents.append(contentsOf: courseEvents)
                }
            }
        }

        // Sort by start time
        self.todayEvents = allEvents.sorted { $0.event.startDate < $1.event.startDate }
    }

    private func fetchTodayAnnouncements(courses: [Course], today: Date, tomorrow: Date) async {
        guard !courses.isEmpty else { return }

        let courseIds = courses.map { $0.id }

        await withTaskGroup(of: Void.self) { group in
            for courseId in courseIds {
                group.addTask { [weak self] in
                    let request = CanvasRequest.getDiscussionTopics(
                        courseId: courseId,
                        orderBy: .position,
                        onlyAnnouncements: true,
                        perPage: 25
                    )

                    let course = courses.first { $0.id == courseId }

                    do {
                        try await CanvasService.shared.loadAndSync(
                            request
                        ) { [weak self] cached in
                            guard let self, let cached else { return }
                            self.updateAnnouncements(cached, course: course, today: today, tomorrow: tomorrow)
                        }
                    } catch {
                        
                    }
                }
            }
        }
    }

    private func updateAnnouncements(_ announcements: [DiscussionTopic], course: Course?, today: Date, tomorrow: Date) {
        let filtered = announcements
            .filter { announcement in
                guard let date = announcement.date else { return false }
                return date >= today && date < tomorrow && announcement.published
            }
            .map { AllAnnouncementsManager.CourseAnnouncement(announcement: $0, course: course) }

        if let courseId = course?.id {
            todayAnnouncements.removeAll { $0.course?.id == courseId }
        }
        todayAnnouncements.append(contentsOf: filtered)
        todayAnnouncements.sort {
            ($0.announcement.date ?? .distantPast) > ($1.announcement.date ?? .distantPast)
        }
    }

    private func fetchTodayAssignments(courses: [Course], today: Date, tomorrow: Date) async {
        let request = CanvasRequest.getToDoItems(include: [.ungradedQuizzes])

        do {
            try await CanvasService.shared.loadAndSync(
                request
            ) { [weak self] cached in
                guard let self, let cached else { return }
                self.addTodayAssignments(cached, courses: courses, today: today, tomorrow: tomorrow, replaceExisting: true)
            }
        } catch {
            
        }
    }

    private func addTodayAssignments(_ items: [ToDoItem], courses: [Course], today: Date, tomorrow: Date, replaceExisting: Bool) {
        let filtered = items
            .filter { $0.type == .submitting }
            .filter { item in
                guard let dueDate = item.dueDate else { return false }
                return dueDate >= today && dueDate < tomorrow
            }

        filtered.forEach { item in
            item.course = courses.first { $0.id == item.courseID.asString }
        }

        let sorted = filtered.sorted {
            ($0.dueDate ?? Date()) < ($1.dueDate ?? Date())
        }

        if replaceExisting {
            self.todayAssignments = sorted
        } else {
            // Append new items and remove duplicates
            let existing = Set(self.todayAssignments.map { $0.id })
            let newItems = sorted.filter { !existing.contains($0.id) }
            self.todayAssignments.append(contentsOf: newItems)
            self.todayAssignments.sort { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
        }
    }


    func destinationView(for data: ListWidgetData) -> NavigationModel.Destination {
        let id = data.id

        if id == "today-date" {
            return .today
        }

        if id == "no-events" {
            return .today
        }

        if id.hasPrefix("event-") {
            let eventID = String(id.dropFirst("event-".count))
            if let courseEvent = todayEvents.first(where: { $0.event.id == eventID }),
               let course = courseEvent.course {
                return .calendarEvent(courseEvent.event, course)
            }
            return .today
        }

        if id.hasPrefix("announcement-") {
            let announcementID = String(id.dropFirst("announcement-".count))
            if let announcement = todayAnnouncements.first(where: { $0.id == announcementID }) {
                return .announcement(announcement.announcement)
            }
        }

        if id.hasPrefix("assignment-") {
            let assignmentID = String(id.dropFirst("assignment-".count))
            if let assignment = todayAssignments.first(where: { $0.id == assignmentID }) {
                return assignment.navigationDestination() ?? .today
            }
        }

        return .today
    }
}

