//
//  CourseDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/28/24.
//

import SwiftUI

struct CourseDetailView: View {
    let course: Course
    let coursePage: NavigationModel.CoursePage

    var body: some View {
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
            case .tabs:
                CourseTabsView(course: course)
            case .quizzes:
                CourseQuizzesView(courseId: course.id)
            case .modules:
                ModulesListView(courseId: course.id)
            case .pages:
                PagesListView(courseId: course.id)
            }
        }
        .tint(course.rgbColors?.color)
    }
}
