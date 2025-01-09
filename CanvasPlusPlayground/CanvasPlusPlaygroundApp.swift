//
//  CanvasPlusPlaygroundApp.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

@main
struct CanvasPlusPlaygroundApp: App {
    @State private var profileManager = ProfileManager()
    @State private var courseManager = CourseManager()
    @State private var navigationModel = NavigationModel()
    @StateObject private var intelligenceManager = IntelligenceManager()
    @StateObject private var llmEvaluator = LLMEvaluator()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(profileManager)
                .environment(courseManager)
                .environment(navigationModel)
                .environmentObject(intelligenceManager)
                .environmentObject(llmEvaluator)
                .task {
                    CanvasService.shared.setupStorage()
                    await courseManager.getCourses()
                }
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .environment(profileManager)
                .environment(courseManager)
                .environment(navigationModel)
                .environmentObject(intelligenceManager)
                .environmentObject(llmEvaluator)
                .frame(width: 400, height: 500)
        }
        #endif
    }

    init() {
        print(URL.applicationSupportDirectory.path(percentEncoded: false))
    }
}
