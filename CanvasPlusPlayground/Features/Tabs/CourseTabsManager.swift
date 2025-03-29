//
//  CourseTabsManager.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/16/24.
//

import Foundation

@Observable
class CourseTabsManager {
    var tabs = [TabAPI]()

    var tabLabels: [String] {
        tabs.map(\.label).compactMap { $0 }
    }

    func fetchTabs(course: Course) async {
        let courseId = course.id

        guard let (data, _) = try? await CanvasService.shared.fetchResponse(CanvasRequest.getTabs(courseId: courseId)) else {
            LoggerService.main.error("Unable to fetch tabs.")
            self.tabs = []
            return
        }

        if let tabs = try? JSONDecoder().decode([TabAPI].self, from: data) {
            self.tabs = tabs
        } else {
            LoggerService.main.error("Unable to decode tab.")
        }
    }
}
