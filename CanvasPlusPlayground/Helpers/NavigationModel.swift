//
//  NavigationModel.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/25/24.
//

import SwiftUI

@Observable
class NavigationModel {
    enum CoursePage {
        case assignments, files, announcements, grades, calendar, people, tabs
    }

    var selectedCourse: Course? {
        didSet { selectedCoursePage = nil }
    }
    var selectedCoursePage: CoursePage?

    var showInstallIntelligenceSheet = false
}
