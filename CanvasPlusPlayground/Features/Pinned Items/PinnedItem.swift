//
//  PinnedItem.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/9/25.
//

import Foundation

@Observable
class PinnedItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let courseID: String
    let type: PinnedItemType
    var data: PinnedItemData?

    private var course: Course?
    private var modelData: PinnedItemData.ModelData?

    enum PinnedItemType: Int, Codable {
        case announcement, assignment, file, calendarEvent, quiz, grade, home, syllabus, people, groups, modules, pages

        var displayName: String {
            switch self {
            case .announcement:
                "Announcements"
            case .assignment:
                "Assignments"
            case .file:
                "Files"
            case .calendarEvent:
                "Calendar Events"
            case .quiz:
                "Quizzes"
            case .grade:
                "Grades"
            case .home:
                "Home"
            case .syllabus:
                "Syllabus"
            case .people:
                "People"
            case .groups:
                "Groups"
            case .modules:
                "Modules"
            case .pages:
                "Pages"
            }
        }
    }

    func itemData() async {
        do {

            async let fetchData: Void = fetchData()
            // TODO: use new course infra
            async let fetchCourse: [Course] = CanvasService.shared.loadAndSync(
                CanvasRequest.getCourse(id: courseID)
            ) { cachedCourse in
                    guard let course = cachedCourse?.first else { return }
                    setData(course: course)
            }

            try await (_, _) = (fetchData, fetchCourse)
        } catch {
            LoggerService.main.error("Error fetching \(self.type.displayName)")
        }
    }

    private func fetchData() async throws {
        switch type {
        case .announcement:
            let announcements = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getDiscussionTopics(courseId: courseID)
            ) { cachedAnnouncements in
                    guard let announcement = cachedAnnouncements?.first(where: { $0.id == id }) else { return }
                    setData(modelData: .announcement(announcement))
            }
            guard let announcement = announcements.first(where: { $0.id == id }) else { return }
            setData(modelData: .announcement(announcement))
        case .assignment:
            let assignments = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getAssignment(id: id, courseId: courseID)
            ) { cachedAssignments in
                    guard let assignment = cachedAssignments?.first else { return }
                    setData(modelData: .assignment(assignment))
            }
            guard let assignment = assignments.first else { return }
            setData(modelData: .assignment(assignment))

        case .file:
            let files = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getFile(fileId: id)
            ) { cachedFiles in
                    guard let file = cachedFiles?.first else { return }
                    setData(modelData: .file(file))
            }
            guard let file = files.first else { return }
            setData(modelData: .file(file))
        case .calendarEvent:
            let courses = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getCourse(id: courseID)
            ) { _ in }

            guard let course = courses.first,
                  let icsURLString = course.calendarIcs,
                  let icsURL = URL(string: icsURLString) else {
                LoggerService.main.error("No ICS URL found for course: \(self.courseID)")
                return
            }

            let eventGroups = await ICSParser.parseEvents(from: icsURL, for: course)
            let allEvents = eventGroups.flatMap { $0.events }

            guard let event = allEvents.first(where: { $0.id == id }) else {
                LoggerService.main.error("Calendar event not found: \(self.id)")
                return
            }

            setData(modelData: .calendarEvent(event))
        case .quiz:
            let quizzes = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getQuiz(id: id, courseId: courseID)
            ) { cachedQuizzes in
                    guard let quiz = cachedQuizzes?.first else { return }
                    setData(modelData: .quiz(quiz))
            }
            guard let quiz = quizzes.first else { return }
            setData(modelData: .quiz(quiz))
        case .grade:
            let enrollments = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getEnrollments(courseId: courseID)
            ) { cachedEnrollments in
                    guard let enrollment = cachedEnrollments?.first else { return }
                    setData(modelData: .grade(enrollment))
            }
            guard let enrollment = enrollments.first else { return }
            setData(modelData: .grade(enrollment))
        case .home, .syllabus, .people, .groups, .modules, .pages:
            break
        }
    }

    func setData(course: Course? = nil, modelData: PinnedItemData.ModelData? = nil) {
        if course != nil {
            self.course = course
        }

        if modelData != nil {
            self.modelData = modelData
        }

        if self.course != nil {
            self.data = .init(modelData: self.modelData, course: self.course)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case courseID
        case type
    }

    init(id: String, courseID: String, type: PinnedItemType, data: PinnedItemData? = nil) {
        self.id = id
        self.courseID = courseID
        self.type = type
        self.data = data
    }

    static func == (lhs: PinnedItem, rhs: PinnedItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct PinnedItemData {
    enum ModelData {
        case announcement(DiscussionTopic)
        case assignment(Assignment)
        case file(File)
        case calendarEvent(CanvasCalendarEvent)
        case quiz(Quiz)
        case grade(Enrollment)
        // TODO: Add more pinned item types
    }

    let modelData: ModelData?
    let course: Course

    init?(modelData: ModelData? = nil, course: Course?) {
        guard let course else { return nil }

        self.modelData = modelData
        self.course = course
    }
}

extension PinnedItem.PinnedItemType {
    init?(coursePage: NavigationModel.CoursePage) {
        switch coursePage {
        case .home:
            self = .home
        case .syllabus:
            self = .syllabus
        case .assignments:
            self = .assignment
        case .files:
            self = .file
        case .announcements:
            self = .announcement
        case .grades:
            self = .grade
        case .calendar:
            self = .calendarEvent
        case .people:
            self = .people
        case .groups:
            self = .groups
        case .quizzes:
            self = .quiz
        case .modules:
            self = .modules
        case .pages:
            self = .pages
        }
    }

    var coursePage: NavigationModel.CoursePage? {
        switch self {
        case .home:
            return .home
        case .syllabus:
            return .syllabus
        case .assignment:
            return .assignments
        case .file:
            return .files
        case .announcement:
            return .announcements
        case .grade:
            return .grades
        case .calendarEvent:
            return .calendar
        case .people:
            return .people
        case .groups:
            return .groups
        case .quiz:
            return .quizzes
        case .modules:
            return .modules
        case .pages:
            return .pages
        }
    }
}


extension PinnedItem {
    func destination() -> NavigationModel.Destination? {
        guard let itemData = data else { return nil }

        if let modelData = itemData.modelData {
            switch modelData {
            case .announcement(let announcement):
                return .announcement(announcement)
            case .assignment(let assignment):
                return .assignment(assignment)
            case .file(let file):
                return .file(file, itemData.course.id)
            case .calendarEvent(let event):
                return .calendarEvent(event, itemData.course)
            case .quiz(let quiz):
                return .quiz(quiz)
            case .grade:
                return .coursePage(.grades, itemData.course)
            }
        } else if let coursePage = type.coursePage {
            return .coursePage(coursePage, itemData.course)
        }

        return nil
    }
}
