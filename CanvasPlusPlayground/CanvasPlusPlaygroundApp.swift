//
//  CanvasPlusPlaygroundApp.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

@main
struct CanvasPlusPlaygroundApp: App {
    @State private var courseManager = CourseManager()

    var body: some Scene {
        WindowGroup {
            CourseListView()
                .environment(CourseManager())
                .onAppear {
                    Task {
                        await CanvasService.shared.setupRepository()
                    }
                }
        }
    }
}
