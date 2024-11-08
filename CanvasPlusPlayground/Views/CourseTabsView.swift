//
//  CourseTabsView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/15/24.
//

import SwiftUI

struct CourseTabsView: View {
    let course: Course
    let base_url: String
    @State var tabsManager: CourseTabsManager
    
    init(course: Course) {
        self.course = course
        self.tabsManager = CourseTabsManager(course: course)
        self.base_url = "https://gatech.instructure.com/courses/\(String(course.id!))"
    }
    
    var body: some View {
        List(tabsManager.tabLabels, id: \.self) { label in
            let lower_case_label = label.lowercased()
            let urlString = label != "home" ? base_url + "/\(lower_case_label)" : base_url
            
            if let url = URL(string: urlString) {
                Link(label, destination:url)
            }
        }
        .navigationTitle("Tabs")
        .task {
            await tabsManager.fetchTabs()
        }
    }
}

