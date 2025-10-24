//
//  NavigationModel.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/25/24.
//

import SwiftUI

@Observable
class NavigationModel {
    enum Tab: Hashable {
        case allCourses // iPhone only
        case dashboard
        case search
        case course(Course.ID) // macOS/iPadOS only, all course tabs share the same navigation path
    }

    enum CoursePage: String, CaseIterable, Codable {
        case home
        case syllabus
        case assignments
        case files
        case announcements
        case grades
        case calendar
        case people
        case groups
        case quizzes
        case modules
        case pages

        var title: String {
            rawValue.capitalized
        }

        static let requiredTabs: Set<CoursePage> = [
            .people, .groups, .calendar
        ]

        var systemImageIcon: String {
            switch self {
            case .home:
                "house.fill"
            case .syllabus:
                "book.pages"
            case .files:
                "folder"
            case .assignments:
                "circle.inset.filled"
            case .calendar:
                "calendar"
            case .announcements:
                "bubble"
            case .grades:
                "graduationcap.fill"
            case .people:
                "person.crop.circle.fill"
            case .groups:
                "person.3.sequence.fill"
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
        case allAnnouncements
        case allToDos
        case pinnedItems
        case recentItems
        case today
        case course(Course)
        case coursePage(CoursePage, Course)
        case announcement(DiscussionTopic)
        case assignment(Assignment)
        case page(Page)
        case file(File, Course.ID)
        case folder(Folder, Course)
        case quiz(Quiz)
        case calendarEvent(CanvasCalendarEvent, Course)
        case allCalendar

        // TODO: Add top level views like all announcements, pinned items, etc

        // TODO: Add specific course items as needed.
        @ViewBuilder
        func destinationView() -> some View {
            switch self {
            case .course(let course):
                CourseView(course: course)
            case let .coursePage(coursePage, course):
                CourseDetailView(course: course, coursePage: coursePage)
            case .announcement(let announcement):
                CourseAnnouncementDetailView(announcement: announcement)
            case .assignment(let assignment):
                AssignmentDetailView(assignment: assignment)
            case .page(let page):
                PageView(page: page)
            case let .file(file, courseID):
                FileViewer(courseID: courseID, file: file)
            case let .folder(folder, course):
                FoldersPageView(course: course, folder: folder)
            case let .quiz(quiz):
                QuizDetailView(quiz: quiz)
            case .allAnnouncements:
                AllAnnouncementsView()
            case .allToDos:
                ToDoListView()
            case .pinnedItems:
                PinnedItemsView()
            case .recentItems:
                RecentItemsView()
            case .today:
                TodayView()
            case let .calendarEvent(event, course):
                CalendarEventDetailView(event: event, course: course)
            case .allCalendar:
                CombinedCalendar()
            }
        }
    }

    // MARK: - Tab-based navigation
    var selectedTab: Tab = .dashboard {
        didSet {
            // when switching tab, flush the course path, this is unique to mac and ipad
            coursePath = NavigationPath()
        }
    }

    // Each tab maintains its own NavigationPath (stack)
    var allCoursesPath = NavigationPath() // for Tab.allCourses
    var dashboardPath = NavigationPath()
    var calendarPath = NavigationPath()

    var coursePath = NavigationPath() // for Tab.course(id:)

    var navigationPath: NavigationPath {
        set {
            switch selectedTab {
            case .allCourses: allCoursesPath = newValue
            case .dashboard: dashboardPath = newValue
            case .course: coursePath = newValue
            default: allCoursesPath = newValue
            }
        }
        get {
            switch selectedTab {
            case .allCourses: return allCoursesPath
            case .dashboard: return dashboardPath
            case .course: return coursePath
            default: return allCoursesPath
            }
        }
    }
    var showAuthorizationSheet = false
    var showProfileSheet = false
    #if os(iOS)
    var showSettingsSheet = false
    #endif
}
