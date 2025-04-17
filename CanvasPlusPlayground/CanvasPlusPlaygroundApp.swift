//
//  CanvasPlusPlaygroundApp.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI
import SwiftData

@main
struct CanvasPlusPlaygroundApp: App {
    // Navigation
    @State private var navigationModel = NavigationModel()

    // App
    @State private var listManager = ToDoListManager()
    @State private var profileManager = ProfileManager()
    @State private var courseManager = CourseManager()
    @State private var pinnedItemsManager = PinnedItemsManager()
    @State private var remindersManager = RemindersManager()
    // Intelligence
    @StateObject private var intelligenceManager = IntelligenceManager()
    @StateObject private var llmEvaluator = LLMEvaluator()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(listManager)
                .environment(profileManager)
                .environment(courseManager)
                .environment(pinnedItemsManager)
                .environment(navigationModel)
                .environment(remindersManager)
                .environmentObject(intelligenceManager)
                .environmentObject(llmEvaluator)
                .onAppear {
                    CanvasService.shared.setupStorage()
                }
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .environment(profileManager)
                .environment(courseManager)
                .environment(pinnedItemsManager)
                .environment(navigationModel)
                .environmentObject(intelligenceManager)
                .environmentObject(llmEvaluator)
                .frame(width: 400, height: 500)
        }
        #endif
    }

    init() {
        #if DEBUG
        LoggerService.main.debug("App Sandbox: \(URL.applicationSupportDirectory.path(percentEncoded: false))")
        #endif

        do {
            try ModelContainer.setupSharedModelContainer()
        } catch {
            LoggerService.main.error("Model container init has failed: \(error)")
            // TODO: show data corruption message with prompt to reset local storage
        }
    }
}
