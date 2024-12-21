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
    @StateObject private var intelligenceManager = IntelligenceManager()
    @StateObject private var llmEvaluator = LLMEvaluator()

    var body: some Scene {
        WindowGroup {
            CourseListView()
                .environment(ProfileManager())
                .environment(CourseManager())
                .environmentObject(IntelligenceManager())
                .environmentObject(LLMEvaluator())
        }
    }
    
    init() {
        print(URL.applicationSupportDirectory.path(percentEncoded: false))
    }
}
