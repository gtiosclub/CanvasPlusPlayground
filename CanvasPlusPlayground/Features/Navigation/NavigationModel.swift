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

        var destination: Destination {
            switch self {
            case .announcements: .announcements
            case .assignments: .assignments
            default: .announcements
            }
        }
    }

    enum Destination: Hashable {
        case announcements
        case announcement(DiscussionTopic)

        case assignments
        case assignment(Assignment)
    }

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
