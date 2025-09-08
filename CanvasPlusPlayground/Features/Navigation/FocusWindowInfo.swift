//
//  FocusWindowInfo.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/1/25.
//

import Foundation

struct FocusWindowInfo: Codable, Hashable {
    let destination: CodableDestination

    /// Convenience initializer for creating FocusWindowInfo from NavigationModel.Destination
    init(from navigationDestination: NavigationModel.Destination) {
        self.destination = CodableDestination(from: navigationDestination)
    }
}

/// A Codable representation of NavigationModel.Destination for window management
enum CodableDestination: Codable, Hashable {
    case course(Course.ID)
    case coursePage(NavigationModel.CoursePage, Course.ID)
    case announcement(DiscussionTopic.ID, Course.ID)
    case assignment(Assignment.ID, Course.ID)
    case page(Page.ID, Course.ID)
    case file(File.ID, Course.ID)
    case folder(Folder.ID, Course.ID)
}

extension CodableDestination {
    /// Create a CodableDestination from a NavigationModel.Destination
    init(from navigationDestination: NavigationModel.Destination) {
        switch navigationDestination {
        case .course(let course):
            self = .course(course.id)
        case .coursePage(let page, let course):
            self = .coursePage(page, course.id)
        case .announcement(let announcement):
            self = .announcement(announcement.id, announcement.courseId ?? "")
        case .assignment(let assignment):
            self = .assignment(assignment.id, String(assignment.courseId ?? 0))
        case .page(let page):
            self = .page(page.id, page.courseID ?? "")
        case .file(let file, let courseID):
            self = .file(file.id, courseID)
        case .folder(let folder, let course):
            self = .folder(folder.id, course.id)
        }
    }
}

extension CodableDestination {
    /// Loads the NavigationModel.Destination by fetching required data
    @MainActor
    func loadDestination(courseManager: CourseManager) async throws -> NavigationModel.Destination {
        switch self {
        case .course(let courseID):
            return try await loadCourse(courseID: courseID, courseManager: courseManager)
            
        case .coursePage(let coursePage, let courseID):
            return try await loadCoursePage(coursePage: coursePage, courseID: courseID, courseManager: courseManager)
            
        case .assignment(let assignmentID, let courseID):
            return try await loadAssignment(assignmentID: assignmentID, courseID: courseID)
            
        case .announcement(let announcementID, let courseID):
            return try await loadAnnouncement(announcementID: announcementID, courseID: courseID)
            
        case .page(let pageID, let courseID):
            return try await loadPage(pageID: pageID, courseID: courseID)
            
        case .file(let fileID, let courseID):
            return try await loadFile(fileID: fileID, courseID: courseID)
            
        case .folder(let folderID, let courseID):
            return try await loadFolder(folderID: folderID, courseID: courseID, courseManager: courseManager)
        }
    }

    @MainActor
    private func loadCourse(courseID: Course.ID, courseManager: CourseManager) async throws -> NavigationModel.Destination {
        // First try to find in active courses
        if let course = courseManager.activeCourses.first(where: { $0.id == courseID }) {
            return .course(course)
        }
        
        // If not found, fetch it
        let courses = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getCourse(id: courseID)
        ) { _ in }
        
        guard let course = courses.first else {
            throw FocusWindowError.courseNotFound
        }
        return .course(course)
    }

    @MainActor
    private func loadCoursePage(coursePage: NavigationModel.CoursePage, courseID: Course.ID, courseManager: CourseManager) async throws -> NavigationModel.Destination {
        // First try to find in active courses
        if let course = courseManager.activeCourses.first(where: { $0.id == courseID }) {
            return .coursePage(coursePage, course)
        }
        
        // If not found, fetch it
        let courses = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getCourse(id: courseID)
        ) { _ in }
        
        guard let course = courses.first else {
            throw FocusWindowError.courseNotFound
        }
        return .coursePage(coursePage, course)
    }

    private func loadAssignment(assignmentID: Assignment.ID, courseID: Course.ID) async throws -> NavigationModel.Destination {
        let assignments = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getAssignment(id: assignmentID, courseId: courseID)
        ) { _ in }
        
        guard let assignment = assignments.first else {
            throw FocusWindowError.contentNotFound
        }
        return .assignment(assignment)
    }
    
    private func loadAnnouncement(announcementID: DiscussionTopic.ID, courseID: Course.ID) async throws -> NavigationModel.Destination {
        let announcements = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getDiscussionTopics(courseId: courseID)
        ) { _ in }
        
        guard let announcement = announcements.first(where: { $0.id == announcementID }) else {
            throw FocusWindowError.contentNotFound
        }
        return .announcement(announcement)
    }
    
    private func loadPage(pageID: Page.ID, courseID: Course.ID) async throws -> NavigationModel.Destination {
        let pages = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getPages(courseId: courseID)
        ) { _ in }
        
        guard let page = pages.first(where: { $0.id == pageID }) else {
            throw FocusWindowError.contentNotFound
        }
        return .page(page)
    }
    
    private func loadFile(fileID: String, courseID: Course.ID) async throws -> NavigationModel.Destination {
        let files = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getFile(fileId: fileID)
        ) { _ in }
        
        guard let file = files.first else {
            throw FocusWindowError.contentNotFound
        }
        return .file(file, courseID)
    }
    
    private func loadFolder(folderID: String, courseID: Course.ID, courseManager: CourseManager) async throws -> NavigationModel.Destination {
        throw FocusWindowError.unsupportedNewWindow
    }
}

enum FocusWindowError: LocalizedError {
    case courseNotFound
    case contentNotFound
    case unsupportedNewWindow
    
    var errorDescription: String? {
        switch self {
        case .courseNotFound:
            return "Course could not be found"
        case .contentNotFound:
            return "Content could not be found"
        case .unsupportedNewWindow:
            return "Unsupported new window"
        }
    }
}

extension NavigationModel.Destination {
    /// Creates a FocusWindowInfo for this destination
    var focusWindowInfo: FocusWindowInfo {
        return FocusWindowInfo(from: self)
    }
}
