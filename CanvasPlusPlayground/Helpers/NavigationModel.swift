//
//  NavigationModel.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/25/24.
//

import SwiftUI

@Observable
class NavigationModel {
    enum CoursePage:String {
        case assignments, files, announcements, grades, calendar, people, tabs
    }

    var selectedCourse: Course? {
        didSet {
            let dataRep = try! JSONEncoder().encode(selectedCourse)
            UserDefaults.standard.set(dataRep, forKey: "selectedCourse")
            selectedCoursePage = nil
        }
    }
    var selectedCoursePage: CoursePage? {
        didSet {
            if let page = selectedCoursePage {
                UserDefaults.standard.set(page.rawValue, forKey: "selectedPage")
            } else {
                UserDefaults.standard.removeObject(forKey: "selectedPage")
            }
        }
    }
    
    init() {
        let courseVal = UserDefaults.standard.data(forKey: "selectedCourse")
        guard let courseVal else { return }
        selectedCourse = Course(from: courseVal)
        
        if let rawValue = UserDefaults.standard.string(forKey: "selectedPage"),
           let state = CoursePage(rawValue: rawValue) {
            selectedCoursePage = state
        }
    }
}
