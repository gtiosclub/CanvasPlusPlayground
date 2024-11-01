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
    @StateObject private var intelligenceManager = IntelligenceManager()
    @StateObject private var llmEvaluator = LLMEvaluator()

    var body: some Scene {
        WindowGroup {
            CourseListView()
                .environment(CourseManager())
                .environmentObject(IntelligenceManager())
                .environmentObject(LLMEvaluator())
        }
    }
}
