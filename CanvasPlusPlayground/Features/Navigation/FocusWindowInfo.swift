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
    case quiz(Quiz.ID, Course.ID)
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
        case .quiz(let quiz):
            self = .quiz(quiz.id, quiz.courseID)
        }
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
