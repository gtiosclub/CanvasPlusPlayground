//
//  CourseTabsView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/15/24.
//

import SwiftUI

struct CourseTabsView: View {
    let course: Course
    @State var tabsManager: CourseTabsManager
    
    init(course: Course) {
        self.course = course
        self.tabsManager = CourseTabsManager(course: course)
    }
    
    var body: some View {
        List(tabsManager.tabLabels, id: \.self) { label in
            Text(label)
        }
        .navigationTitle(course.name ?? "")
        .task {
            await tabsManager.fetchTabs()
        }
    }
}

