//
//  CourseTabsManager.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/16/24.
//

import Foundation
import SwiftData

@Observable
class CourseTabsManager {
    var tabs = [CanvasTab]()

    var tabLabels: [String] {
        tabs.map(\.label).compactMap { $0 }
    }

    init(forCourse course: Course) {
        self.tabs = course.tabs
    }
}
