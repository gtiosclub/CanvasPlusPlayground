//
//  CourseView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/8/24.
//

import SwiftUI

struct CourseView: View {
    @Environment(PickerService.self) private var pickerService: PickerService?
    @Environment(NavigationModel.self) private var navigationModel
    let course: Course

    private var coursePages: [NavigationModel.CoursePage] {
        pickerService?.supportedPickerViews ?? NavigationModel.CoursePage.allCases
    }

    var body: some View {
        @Bindable var navigationModel = navigationModel

        List(coursePages, id: \.self, selection: $navigationModel.selectedCoursePage) { page in
            NavigationLink(value: page.destination) {
                Label(page.title, systemImage: page.systemImageIcon)
            }
        }
        .tint(course.rgbColors?.color)
        .navigationTitle(course.displayName)
        .navigationDestination(for: NavigationModel.Destination.self) { destination in
            switch destination {
            case .announcements:
                CourseAnnouncementsView(course: course)
            case .announcement(let announcement):
                CourseAnnouncementDetailView(announcement: announcement)
            case .assignments:
                CourseAssignmentsView(course: course)
            case .assignment(let assignment):
                AssignmentDetailView(assignment: assignment)
            }
        }
    }
}
