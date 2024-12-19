//
//  NavigationModel.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/25/24.
//

import SwiftUI

@Observable
class NavigationModel {
    enum CoursePage: String, CaseIterable {
        case assignments
        case files
        case announcements
        case grades
        case calendar
        case people
        case tabs
        case quizzes

        var title: String {
            rawValue.capitalized
        }

        var systemImageIcon: String {
            switch self {
            case .files: "folder"
            case .assignments: "circle.inset.filled"
            case .calendar: "calendar"
            case .tabs: "tray.2"
            case .announcements: "bubble"
            case .grades: "graduationcap.fill"
            case .people: "person.crop.circle.fill"
            case .quizzes: "questionmark.circle.fill"
            }
        }
    }

    var selectedCourseID: Course.ID? {
        didSet {
            selectedCoursePage = nil
        }
    }
    var selectedCoursePage: CoursePage?
    var showInstallIntelligenceSheet = false
}
