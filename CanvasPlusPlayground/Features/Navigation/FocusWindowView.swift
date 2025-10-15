//
//  FocusWindowView.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/1/25.
//

import SwiftUI

struct FocusWindowView: View {
    @Environment(CourseManager.self) private var courseManager
    @State private var navigationModel = NavigationModel()
    @State private var destination: NavigationModel.Destination?
    @State private var isLoading = true
    @State private var errorMessage: String?

    let info: FocusWindowInfo

    var body: some View {
        @Bindable var navigationModel = navigationModel

        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let errorMessage {
                ContentUnavailableView(
                    "Unable to open new window",
                    systemImage: "questionmark.square.dashed",
                    description: Text(errorMessage)
                )
            } else if let destination {
                NavigationStack(path: $navigationModel.navigationPath) {
                    destination.destinationView()
                        .defaultNavigationDestination()
                }
                .environment(navigationModel)
            }
        }
        .task {
            await loadDestination()
        }
    }

    private func getCourseID() -> Course.ID {
        switch info.destination {
        case .course(let courseID), .coursePage(_, let courseID), .file(_, let courseID), .folder(_, let courseID):
            return courseID
        case .announcement(_, let courseID), .assignment(_, let courseID), .page(_, let courseID), .quiz(_, let courseID):
            return courseID
        case .allAnnouncements, .allToDos, .recentItems:
            return ""
        case .calendarEvent(_, let courseID):
            return courseID ?? ""
        }
    }

    @MainActor
    private func loadDestination() async {
        do {
            if courseManager.activeCourses.isEmpty {
                await courseManager.getCourses()
            }

            switch info.destination {
            case .course(let courseID):
                try await loadCourse(courseID: courseID)

            case .coursePage(let coursePage, let courseID):
                try await loadCoursePage(coursePage: coursePage, courseID: courseID)

            case .assignment(let assignmentID, let courseID):
                try await loadAssignment(assignmentID: assignmentID, courseID: courseID)

            case .announcement(let announcementID, let courseID):
                try await loadAnnouncement(announcementID: announcementID, courseID: courseID)

            case .page(let pageID, let courseID):
                try await loadPage(pageID: pageID, courseID: courseID)

            case .file(let fileID, let courseID):
                try await loadFile(fileID: fileID, courseID: courseID)

            case .folder(let folderID, let courseID):
                try await loadFolder(folderID: folderID, courseID: courseID)
            case .quiz(let quizID, let courseID):
                try await loadQuiz(quizID: quizID, courseID: courseID)
            case .allAnnouncements:
                destination = .allAnnouncements
            case .allToDos:
                destination = .allToDos
            case .recentItems:
                destination = .recentItems
            case .calendarEvent(let event, let course):
                try await loadEvent(eventID: event, course: course)
            }
        } catch {
            errorMessage = "Failed to load content: \(error.localizedDescription)"
            LoggerService.main.error("FocusWindowView: Failed to load destination - \(error)")
        }

        isLoading = false
    }

    private func loadCourse(courseID: Course.ID) async throws {
        if let course = courseManager.course(withID: courseID) {
            destination = .course(course)
            return
        }

        let courses = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getCourse(id: courseID)
        ) { cachedCourses in
            if let course = cachedCourses?.first {
                destination = .course(course)
            }
        }

        if destination == nil, let course = courses.first {
            destination = .course(course)
        }
    }

    private func loadCoursePage(coursePage: NavigationModel.CoursePage, courseID: Course.ID) async throws {
        if let course = courseManager.course(withID: courseID) {
            destination = .coursePage(coursePage, course)
            return
        }

        let courses = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getCourse(id: courseID)
        ) { cachedCourses in
            if let course = cachedCourses?.first {
                destination = .coursePage(coursePage, course)
            }
        }

        if destination == nil, let course = courses.first {
            destination = .coursePage(coursePage, course)
        }
    }

    private func loadAssignment(assignmentID: Assignment.ID, courseID: Course.ID) async throws {
        let assignments = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getAssignment(id: assignmentID, courseId: courseID)
        ) { cachedAssignments in
            if let assignment = cachedAssignments?.first {
                destination = .assignment(assignment)
            }
        }

        if destination == nil, let assignment = assignments.first {
            destination = .assignment(assignment)
        }
    }

    private func loadAnnouncement(announcementID: DiscussionTopic.ID, courseID: Course.ID) async throws {
        let announcements = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getDiscussionTopics(courseId: courseID)
        ) { cachedAnnouncements in
            if let announcement = cachedAnnouncements?.first(where: { $0.id == announcementID }) {
                destination = .announcement(announcement)
            }
        }

        if destination == nil, let announcement = announcements.first(where: { $0.id == announcementID }) {
            destination = .announcement(announcement)
        }
    }

    private func loadPage(pageID: Page.ID, courseID: Course.ID) async throws {
        let pages = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getPages(courseId: courseID)
        ) { cachedPages in
            if let page = cachedPages?.first(where: { $0.id == pageID }) {
                destination = .page(page)
            }
        }

        if destination == nil, let page = pages.first(where: { $0.id == pageID }) {
            destination = .page(page)
        }
    }

    private func loadFile(fileID: String, courseID: Course.ID) async throws {
        let files = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getFile(fileId: fileID)
        ) { cachedFiles in
            if let file = cachedFiles?.first {
                destination = .file(file, courseID)
            }
        }

        if destination == nil, let file = files.first {
            destination = .file(file, courseID)
        }
    }

    private func loadFolder(folderID: String, courseID: Course.ID) async throws {
        guard let course = courseManager.course(withID: courseID) else {
            throw FocusWindowError.courseNotFound
        }

        let folders = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getFolder(folderId: folderID)
        ) { cachedFolders in
            if let folder = cachedFolders?.first {
                destination = .folder(folder, course)
            }
        }

        if destination == nil, let folder = folders.first {
            destination = .folder(folder, course)
        }
    }
    private func loadQuiz(quizID: Quiz.ID, courseID: Course.ID) async throws {
        let quizzes = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getQuiz(id: quizID, courseId: courseID)
        ) { cachedQuizzes in
            if let quiz = cachedQuizzes?.first {
                destination = .quiz(quiz)
            }
        }

        if destination == nil, let quiz = quizzes.first {
            destination = .quiz(quiz)
        }
    }
    
    private func loadEvent(eventID: String, course courseID: Course.ID?) async throws {
        var course: Course?
        
        if let courseID {
            course = courseManager.activeCourses.first(where: { $0.id == courseID })
            if course == nil {
                let courses = try await CanvasService.shared.loadAndSync(
                    CanvasRequest.getCourse(id: courseID)
                ) { cachedCourses in
                    if let fetchedCourse = cachedCourses?.first {
                        course = fetchedCourse
                    }
                }
                
                if course == nil, let fetchedCourse = courses.first {
                    course = fetchedCourse
                }
            }
        }
        
        if let course, let icsURL = URL(string: course.calendarIcs ?? "") {
            let eventGroups = await ICSParser.parseEvents(from: icsURL)
            
            for group in eventGroups {
                if let event = group.events.first(where: { $0.id == eventID }) {
                    destination = .calendarEvent(event, course)
                    return
                }
            }
        }
        
        throw FocusWindowError.contentNotFound
    }

    enum FocusWindowError: LocalizedError {
        case courseNotFound
        case unsupportedNewWindow
        case contentNotFound

        var errorDescription: String? {
            switch self {
            case .courseNotFound:
                return "Course could not be found"
            case .unsupportedNewWindow:
                return "Unsupported new window"
            case .contentNotFound:
                return "Content could not be found"
            }
        }
    }

}
