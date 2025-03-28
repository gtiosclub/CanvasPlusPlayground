//
//  NavigationModel.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/25/24.
//

import SwiftUI

@Observable
class NavigationModel {
    enum NavigationPage: Hashable, RawRepresentable {
        init?(rawValue: String) {
            if rawValue.hasPrefix("course") {
                guard let id = rawValue.split(separator: "/").last else { return nil }
                self = .course(id: String(id))
            } else {
                switch rawValue {
                case "announcements":
                    self = .announcements
                case "todoList":
                    self = .toDoList
                case "pinned":
                    self = .pinned
                default:
                    return nil
                }
            }
        }

        case course(id: Course.ID)
        case announcements
        case toDoList
        case pinned

        var rawValue: String {
            switch self {
            case .course(id: let id):
                "course/\(id)"
            case .announcements:
                "announcements"
            case .toDoList:
                "todoList"
            case .pinned:
                "pinned"
            }
        }
    }

    enum CoursePage: String, CaseIterable {
        case assignments
        case files
        case announcements
        case grades
        case calendar
        case people
        case tabs
        case quizzes
        case modules
        case pages

        var title: String {
            rawValue.capitalized
        }

        static let requiredTabs: Set<CoursePage> = [
            .tabs, .people
        ]

        var systemImageIcon: String {
            switch self {
            case .files:
                "folder"
            case .assignments:
                "circle.inset.filled"
            case .calendar:
                "calendar"
            case .tabs:
                "tray.2"
            case .announcements:
                "bubble"
            case .grades:
                "graduationcap.fill"
            case .people:
                "person.crop.circle.fill"
            case .quizzes:
                "questionmark.circle.fill"
            case .modules:
                "book.closed.circle.fill"
            case .pages:
                "doc.text.fill"
            }
        }
    }

    enum Destination: Hashable {
        case coursePage(CoursePage)

        case announcement(DiscussionTopic)
        case assignment(Assignment)
        case page(Page)
        // TODO: Add specific course items as needed.

        @ViewBuilder
        func destinationView(for course: Course) -> some View {
            switch self {
            case .coursePage(let coursePage):
                CourseDetailView(course: course, coursePage: coursePage)
            case .announcement(let announcement):
                CourseAnnouncementDetailView(announcement: announcement)
            case .assignment(let assignment):
                AssignmentDetailView(assignment: assignment)
            case .page(let page):
                PageView(page: page)
            }
        }
    }

    var navigationPath = NavigationPath()
    var selectedNavigationPage: NavigationPage? {
        didSet {
            selectedCoursePage = nil
        }
    }
    var selectedCoursePage: CoursePage?
    var selectedCourseForItemPicker: Course?
    var showInstallIntelligenceSheet = false
    var showAuthorizationSheet = false
    var showProfileSheet = false
    #if os(iOS)
    var showSettingsSheet = false
    #endif
}
