//
//  NavigationModel.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/25/24.
//

import SwiftUI

@Observable
class NavigationModel {
    enum CoursePage: String {
        case assignments, files, announcements, grades, calendar, people, tabs, quizzes
    }

    var selectedCourseID: Course.ID? {
        didSet {
            selectedCoursePage = nil
        }
    }
    var selectedCoursePage: CoursePage?
    var showInstallIntelligenceSheet = false
}
