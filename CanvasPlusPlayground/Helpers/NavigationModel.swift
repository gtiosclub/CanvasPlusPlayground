//
//  NavigationModel.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/25/24.
//

import SwiftUI


class NavigationModel: ObservableObject {
    enum CoursePage:String {
        case assignments, files, announcements, grades, calendar, people, tabs
    }

    @Published var selectedCourse: Course? {
        didSet {
            let dataRep = try! JSONEncoder().encode(selectedCourse)
            UserDefaults.standard.set(dataRep, forKey: "selectedCourse")
            selectedCoursePage = nil
        }
    }
    
    @Published var selectedCoursePage: CoursePage? {
        didSet {
            print("Course page changed")
            UserDefaults.standard.set(selectedCoursePage?.rawValue, forKey: "selectedPage")
        }
    }
    
    init(){
        let courseData = UserDefaults.standard.data(forKey: "selectedCourse")
        let pageString = UserDefaults.standard.string(forKey: "selectedPage")
        print("Nav created")
        guard let data = courseData else { return }
        var course:Course? = nil
        var page:CoursePage? = nil
        do {
            course = try JSONDecoder().decode(Course.self, from: data)
            guard let pageString else { return }
            print("page content \(pageString)")
            page = CoursePage(rawValue: pageString)
            
        } catch {
            print("Error fetching selected course from user defaults \(error.localizedDescription)")
            course = nil
        }
        self.selectedCourse = course
        self.selectedCoursePage = page
    }
    
    @Published var showInstallIntelligenceSheet = false
}
