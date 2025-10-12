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

    static let testDate = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 9))!

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
            LoggerService.main.debug("[TodayWidget] Building widget data: \(self.todayEvents.count) events, \(self.todayAnnouncements.count) announcements, \(self.todayAssignments.count) assignments")

            var data: [ListWidgetData] = []

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            let todayString = dateFormatter.string(from: Self.testDate)

            //Today's date
            data.append(ListWidgetData(
                id: "today-date",
                title: todayString,
                description: " "
            ))

            //today's courses/events
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

            // Add announcements
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
            LoggerService.main.error("[TodayWidget] No course manager available")
            fetchStatus = .error
            return
        }

        fetchStatus = .loading

        // Capture courses on the main actor before entering task group
        let courses = courseManager.activeCourses
        LoggerService.main.debug("[TodayWidget] Starting fetch with \(courses.count) favorited courses")

        // TEMP: Use last Wednesday for testing (October 8, 2025)
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(year: 2025, month: 10, day: 9))!
        let today = calendar.startOfDay(for: testDate)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        LoggerService.main.debug("[TodayWidget] Fetching data for date range: \(today) to \(tomorrow)")

        // TODO: Replace with this for production:
        // let today = calendar.startOfDay(for: Date())
        // let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

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

        LoggerService.main.debug("[TodayWidget] Fetch complete. Events: \(self.todayEvents.count), Announcements: \(self.todayAnnouncements.count), Assignments: \(self.todayAssignments.count)")
        fetchStatus = .loaded
    }

    private func fetchTodayCalendarEvents(courses: [Course], today: Date, tomorrow: Date) async {
        LoggerService.main.debug("[TodayWidget] Fetching calendar events for \(courses.count) courses")
        var allEvents: [CourseEvent] = []

        for course in courses {
            guard let icsURL = course.calendarIcs,
                  let url = URL(string: icsURL) else {
                LoggerService.main.debug("[TodayWidget] Course \(course.displayName) has no calendar ICS URL")
                continue
            }

            LoggerService.main.debug("[TodayWidget] Parsing ICS for course: \(course.displayName)")
            let eventGroups = await ICSParser.parseEvents(from: url)
            LoggerService.main.debug("[TodayWidget] Found \(eventGroups.count) event groups for \(course.displayName)")

            // Filter events for today
            for group in eventGroups {
                LoggerService.main.debug("[TodayWidget] Event group date: \(group.date), checking if >= \(today) and < \(tomorrow)")
                if group.date >= today && group.date < tomorrow {
                    LoggerService.main.debug("[TodayWidget] ✓ Found \(group.events.count) events for today from \(course.displayName)")
                    // Wrap each event with course information
                    let courseEvents = group.events.map { event in
                        CourseEvent(event: event, course: course)
                    }
                    allEvents.append(contentsOf: courseEvents)
                }
            }
        }

        // Sort by start time
        self.todayEvents = allEvents.sorted { $0.event.startDate < $1.event.startDate }
        LoggerService.main.debug("[TodayWidget] Calendar events complete: \(self.todayEvents.count) total events")
    }

    private func fetchTodayAnnouncements(courses: [Course], today: Date, tomorrow: Date) async {
        guard !courses.isEmpty else {
            LoggerService.main.debug("[TodayWidget] No courses to fetch announcements for")
            return
        }

        LoggerService.main.debug("[TodayWidget] Fetching announcements for \(courses.count) courses")
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

                    let announcements: [DiscussionTopic]? = try? await CanvasService.shared.loadAndSync(
                        request,
                        onCacheReceive: { (cached: [DiscussionTopic]?) in
                            guard let cached else { return }
                            self?.addTodayAnnouncements(cached, course: course, today: today, tomorrow: tomorrow)
                        },
                        loadingMethod: .all(onNewPage: { batchAnnouncements in
                            self?.addTodayAnnouncements(batchAnnouncements, course: course, today: today, tomorrow: tomorrow)
                        })
                    )

                    guard let announcements else {
                        LoggerService.main.error("[TodayWidget] Failed to fetch announcements.")
                        return
                    }

                    // Final update - do it synchronously on main actor
                    let filtered = announcements
                        .filter { announcement in
                            guard let date = announcement.date else { return false }
                            return date >= today && date < tomorrow && announcement.published
                        }
                        .map { AllAnnouncementsManager.CourseAnnouncement(announcement: $0, course: course) }

                    await MainActor.run {
                        if let courseId = course?.id {
                            self?.todayAnnouncements.removeAll { $0.course?.id == courseId }
                        }
                        self?.todayAnnouncements.append(contentsOf: filtered)
                        self?.todayAnnouncements.sort {
                            ($0.announcement.date ?? .distantPast) > ($1.announcement.date ?? .distantPast)
                        }
                    }
                }
            }
        }

        LoggerService.main.debug("[TodayWidget] Announcements complete: \(self.todayAnnouncements.count) total announcements")
    }

    nonisolated private func addTodayAnnouncements(_ announcements: [DiscussionTopic], course: Course?, today: Date, tomorrow: Date) {
        DispatchQueue.main.async {
            let filtered = announcements
                .filter { announcement in
                    guard let date = announcement.date else { return false }
                    return date >= today && date < tomorrow && announcement.published
                }
                .map { AllAnnouncementsManager.CourseAnnouncement(announcement: $0, course: course) }

            if let courseId = course?.id {
                self.todayAnnouncements.removeAll { $0.course?.id == courseId }
            }
            self.todayAnnouncements.append(contentsOf: filtered)
            self.todayAnnouncements.sort {
                ($0.announcement.date ?? .distantPast) > ($1.announcement.date ?? .distantPast)
            }
        }
    }

    private func fetchTodayAssignments(courses: [Course], today: Date, tomorrow: Date) async {
        let request = CanvasRequest.getToDoItems(include: [.ungradedQuizzes])

        do {
            let items: [ToDoItem] = try await CanvasService.shared.loadAndSync(
                request,
                onCacheReceive: { cached in
                    guard let cached else { return }
                    Task { @MainActor in
                        self.addTodayAssignments(cached, courses: courses, today: today, tomorrow: tomorrow, replaceExisting: true)
                    }
                },
                loadingMethod: .all(onNewPage: { items in
                    Task { @MainActor in
                        self.addTodayAssignments(items, courses: courses, today: today, tomorrow: tomorrow, replaceExisting: false)
                    }
                })
            )

            // Final update - do it synchronously
            await MainActor.run {
                self.addTodayAssignments(items, courses: courses, today: today, tomorrow: tomorrow, replaceExisting: true)
            }
        } catch {
            LoggerService.main.error("[TodayWidget] Error fetching to-do items: \(error)")
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

    // MARK: - Navigation

    func destinationView(for data: ListWidgetData) -> NavigationModel.Destination {
        let id = data.id

        if id == "today-date" {
            return .today
        }

        // No events message
        if id == "no-events" {
            return .today
        }

        // Calendar event
        if id.hasPrefix("event-") {
            let eventID = String(id.dropFirst("event-".count))
            if let courseEvent = todayEvents.first(where: { $0.event.id == eventID }) {
                return .calendarEvent(courseEvent.event, courseEvent.course)
            }
            return .today
        }

        // Announcement
        if id.hasPrefix("announcement-") {
            let announcementID = String(id.dropFirst("announcement-".count))
            if let announcement = todayAnnouncements.first(where: { $0.id == announcementID }) {
                return .announcement(announcement.announcement)
            }
        }

        // Assignment
        if id.hasPrefix("assignment-") {
            let assignmentID = String(id.dropFirst("assignment-".count))
            if let assignment = todayAssignments.first(where: { $0.id == assignmentID }) {
                return assignment.navigationDestination() ?? .today
            }
        }

        return .today
    }
}
