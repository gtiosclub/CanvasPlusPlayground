//
//  FocusWindowView.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/1/25.
//

import SwiftUI

struct FocusWindowView: View {
    
    @Environment(ToDoListManager.self) private var listManager
    @Environment(ProfileManager.self) private var profileManager
    @Environment(CourseManager.self) private var courseManager
    @Environment(PinnedItemsManager.self) private var pinnedItemsManager
    @Environment(RemindersManager.self) private var remindersManager
    @Environment(NavigationModel.self) private var navigationModel
    
    let info: FocusWindowInfo
    
    private var coursePage: NavigationModel.CoursePage { info.coursePage }
    
    private var course: Course? { courseManager.activeCourses.first(where: { $0.id == info.courseID }) }
    
    var body: some View {
        if let course {
            NavigationStack {
                Group {
                    switch coursePage {
                    case .files:
                        CourseFilesView(course: course)
                    case .announcements:
                        CourseAnnouncementsView(course: course)
                    case .assignments:
                        CourseAssignmentsView(course: course)
                    case .calendar:
                        CalendarView(course: course)
                    case .grades:
                        CourseGradeView(course: course)
                    case .people:
                        PeopleView(courseID: course.id)
                    case .groups:
                        CourseGroupsView(course: course)
                    case .quizzes:
                        CourseQuizzesView(courseId: course.id)
                    case .modules:
                        ModulesListView(courseId: course.id)
                    case .pages:
                        PagesListView(courseId: course.id)
                    }
                }
            }
        } else {
            ContentUnavailableView("Unable to make a focus window", systemImage: "questionmark.square.dashed", description: Text("The course object is nil"))
        }
    }
}


