//
//  SearchCategory.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 3/29/26.
//


import Foundation

/// Centralized definition of searchable content categories.
/// Used by SpotlightSearchResult for display and by any future
enum SearchCategory: String, CaseIterable {
    case courses
    case assignments
    case announcements
    case quizzes
    case pages
    case files
    case modules
    case people
    case groups
    case toDos

    var displayName: String {
        switch self {
        case .courses:       "Courses"
        case .assignments:   "Assignments"
        case .announcements: "Announcements"
        case .quizzes:       "Quizzes"
        case .pages:         "Pages"
        case .files:         "Files"
        case .modules:       "Modules"
        case .people:        "People"
        case .groups:        "Groups"
        case .toDos:         "To-Do Items"
        }
    }

    var systemImage: String {
        switch self {
        case .courses:       "book.fill"
        case .assignments:   NavigationModel.CoursePage.assignments.systemImageIcon
        case .announcements: NavigationModel.CoursePage.announcements.systemImageIcon
        case .quizzes:       NavigationModel.CoursePage.quizzes.systemImageIcon
        case .pages:         NavigationModel.CoursePage.pages.systemImageIcon
        case .files:         NavigationModel.CoursePage.files.systemImageIcon
        case .modules:       NavigationModel.CoursePage.modules.systemImageIcon
        case .people:        NavigationModel.CoursePage.people.systemImageIcon
        case .groups:        NavigationModel.CoursePage.groups.systemImageIcon
        case .toDos:         "checklist"
        }
    }
}

