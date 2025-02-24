//
//  CourseTabsManager.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/16/24.
//

import Foundation

@Observable
class CourseTabsManager {
    let course: Course
    var tabs = [TabAPI]()

    var tabLabels: [String] {
        tabs.map(\.label).compactMap { $0 }
    }

    init(course: Course) {
        self.course = course
    }

    func fetchTabs() async {
        let courseId = course.id
        guard let (data, _) = try? await CanvasService.shared.fetchResponse(CanvasRequest.getTabs(courseId: courseId)) else {
            logger.error("Unable to fetch tabs.")
            return
        }

        if let tabs = try? JSONDecoder().decode([TabAPI].self, from: data) {
            self.tabs = tabs
        } else {
            logger.error("Unable to decode tab.")
        }
    }
}
